"""HTTP adapter for persisting approved dispatches through the ASP.NET Core API."""

import os
from collections.abc import Mapping

import requests

from tools.auth_context import authorization_header


class HttpDispatchBackend:
    """Persist an approved dispatch through the authenticated C# API.

    The adapter performs the backend operations in this order:

    1. Approve the selected VolunteerMatch.
    2. Create or reuse the Assignment.
    3. Create the idempotent Dispatch record.
    4. Move the Assignment to Dispatched.

    The Coordinator/Admin bearer token is taken from the current FastAPI
    request context. It is never hard-coded or stored in LangGraph state.
    """

    def __init__(
        self,
        base_url: str | None = None,
        timeout: int = 10,
    ):
        self.base_url = (
            base_url
            or os.environ.get(
                "API_BASE_URL",
                "http://localhost:5030",
            )
        ).rstrip("/")

        self.timeout = timeout

    def _headers(self) -> dict[str, str]:
        """Return the forwarded Coordinator/Admin authorization header."""

        auth = authorization_header.get()

        if (
            not isinstance(auth, str)
            or not auth.strip()
            or not auth.lower().startswith("bearer ")
        ):
            raise RuntimeError(
                "A forwarded Coordinator/Admin bearer token is required."
            )

        return {
            "Authorization": auth,
        }

    def _request(
        self,
        method: str,
        path: str,
        *,
        json: dict | None = None,
        params: dict | None = None,
    ):
        """Send an authenticated request to the ASP.NET Core backend."""

        response = requests.request(
            method,
            f"{self.base_url}{path}",
            headers=self._headers(),
            json=json,
            params=params,
            timeout=self.timeout,
        )

        response.raise_for_status()

        if not response.content:
            return None

        return response.json()

    def _find_existing_dispatch(
        self,
        incident_id: str,
        idempotency_key: str,
    ) -> dict | None:
        """Return an existing dispatch created with the same key."""

        history = self._request(
            "GET",
            "/api/Dispatches/history",
            params={
                "incidentId": incident_id,
            },
        )

        if not isinstance(history, list):
            return None

        for dispatch in history:
            if (
                isinstance(dispatch, Mapping)
                and dispatch.get("idempotencyKey")
                == idempotency_key
            ):
                return dict(dispatch)

        return None

    def _get_match(
        self,
        incident_id: str,
        match_id: str,
    ) -> dict:
        """Find the selected match for the incident."""

        matches = self._request(
            "GET",
            "/api/Matches",
            params={
                "incidentId": incident_id,
            },
        )

        if not isinstance(matches, list):
            raise RuntimeError(
                "The backend did not return a valid match list."
            )

        for match in matches:
            if (
                isinstance(match, Mapping)
                and match.get("id") == match_id
            ):
                return dict(match)

        raise RuntimeError(
            f"Match '{match_id}' was not found for the incident."
        )

    def _approve_match(
        self,
        incident_id: str,
        match_id: str,
    ) -> dict:
        """Approve a Proposed match or reuse an already-approved match."""

        match = self._get_match(
            incident_id,
            match_id,
        )

        status = match.get("status")

        if status == "Proposed":
            updated = self._request(
                "PATCH",
                f"/api/Matches/{match_id}/status",
                json={
                    "newStatus": "Approved",
                },
            )

            if not isinstance(updated, Mapping):
                raise RuntimeError(
                    "The backend did not return the approved match."
                )

            return dict(updated)

        if status in (
            "Approved",
            "Dispatched",
        ):
            return match

        raise RuntimeError(
            f"Match '{match_id}' cannot be dispatched from status '{status}'."
        )

    def _find_existing_assignment(
        self,
        incident_id: str,
        volunteer_id: str,
        match_id: str,
    ) -> dict | None:
        """Find an assignment previously created for this exact match."""

        history = self._request(
            "GET",
            "/api/Assignments/history",
            params={
                "incidentId": incident_id,
                "volunteerId": volunteer_id,
            },
        )

        if not isinstance(history, list):
            return None

        for assignment in history:
            if (
                isinstance(assignment, Mapping)
                and assignment.get("matchId")
                == match_id
            ):
                return dict(assignment)

        return None

    def _create_or_reuse_assignment(
        self,
        incident_id: str,
        volunteer_id: str,
        match_id: str,
        estimated_duration_minutes: int,
    ) -> dict:
        """Create the assignment once, or reuse it after a retry."""

        existing = self._find_existing_assignment(
            incident_id,
            volunteer_id,
            match_id,
        )

        if existing is not None:
            return existing

        created = self._request(
            "POST",
            "/api/Assignments",
            json={
                "matchId": match_id,
                "estimatedDurationMinutes":
                    estimated_duration_minutes,
            },
        )

        if not isinstance(created, Mapping):
            raise RuntimeError(
                "The backend did not return the created assignment."
            )

        return dict(created)

    def _mark_assignment_dispatched(
        self,
        assignment: dict,
    ) -> dict:
        """Move an Assigned assignment to Dispatched.

        If a retry observes that it has already advanced beyond Assigned,
        no duplicate status transition is attempted.
        """

        assignment_id = assignment.get("id")
        status = assignment.get("status")

        if not assignment_id:
            raise RuntimeError(
                "The assignment response is missing its ID."
            )

        if status == "Assigned":
            updated = self._request(
                "PATCH",
                f"/api/Assignments/{assignment_id}/status",
                json={
                    "newStatus": "Dispatched",
                },
            )

            if not isinstance(updated, Mapping):
                raise RuntimeError(
                    "The backend did not return the updated assignment."
                )

            return dict(updated)

        if status in (
            "Dispatched",
            "InProgress",
            "Completed",
        ):
            return assignment

        raise RuntimeError(
            f"Assignment '{assignment_id}' cannot be dispatched "
            f"from status '{status}'."
        )

    def persist_dispatch(
        self,
        plan: dict,
        *,
        idempotency_key: str,
    ) -> dict:
        """Persist or reconcile an approved dispatch through the backend APIs."""

        if not isinstance(plan, Mapping):
            raise ValueError(
                "A structured dispatch plan is required."
            )

        incident_id = plan.get("incident_id")

        if (
            not isinstance(incident_id, str)
            or not incident_id.strip()
        ):
            raise ValueError(
                "The dispatch plan must contain an incident ID."
            )

        estimated_duration_minutes = plan.get(
            "estimated_duration_minutes"
        )

        if (
            not isinstance(
                estimated_duration_minutes,
                int,
            )
            or isinstance(
                estimated_duration_minutes,
                bool,
            )
            or estimated_duration_minutes <= 0
        ):
            raise ValueError(
                "Estimated duration must be a positive number of minutes."
            )

        assignments = plan.get("assignments")

        if (
            not isinstance(assignments, list)
            or not assignments
        ):
            raise ValueError(
                "At least one assignment is required."
            )

        created_assignments = []

        # Reconcile every approved match and assignment first.
        # On retries these helpers reuse existing backend records.
        for item in assignments:
            if not isinstance(item, Mapping):
                raise ValueError(
                    "Each dispatch assignment must be structured."
                )

            volunteer_id = item.get(
                "volunteer_id"
            )

            match_id = item.get(
                "match_id"
            )

            if (
                not isinstance(volunteer_id, str)
                or not volunteer_id.strip()
            ):
                raise ValueError(
                    "Each assignment requires a volunteer ID."
                )

            if (
                not isinstance(match_id, str)
                or not match_id.strip()
            ):
                raise ValueError(
                    "Each assignment requires a persisted match ID."
                )

            self._approve_match(
                incident_id,
                match_id,
            )

            assignment = (
                self._create_or_reuse_assignment(
                    incident_id,
                    volunteer_id,
                    match_id,
                    estimated_duration_minutes,
                )
            )

            created_assignments.append(
                assignment
            )

        # Reuse an existing dispatch when the idempotency key
        # was already committed by a previous attempt.
        dispatch = self._find_existing_dispatch(
            incident_id,
            idempotency_key,
        )

        if dispatch is None:
            dispatch = self._request(
                "POST",
                "/api/Dispatches",
                json={
                    "incidentId": incident_id,
                    "idempotencyKey":
                        idempotency_key,
                },
            )

            if not isinstance(
                dispatch,
                Mapping,
            ):
                raise RuntimeError(
                    "The backend did not return a dispatch receipt."
                )

        dispatch_id = dispatch.get("id")

        if not dispatch_id:
            raise RuntimeError(
                "The backend dispatch response is missing its ID."
            )

        # Important for retries: even if the Dispatch record
        # already existed, repair any Assignment still at Assigned.
        for assignment in created_assignments:
            self._mark_assignment_dispatched(
                assignment
            )

        return {
            "persisted": True,
            "dispatch_id": dispatch_id,
        }