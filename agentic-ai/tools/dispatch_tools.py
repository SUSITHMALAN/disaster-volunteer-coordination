"""Approved-only boundary for Student 3's future dispatch integration.

Approval is trusted orchestration evidence, not a browser-supplied authorization
claim. Its fingerprint binds approval to the reviewed plan; it is not a signature.
The eventual backend adapter must enforce authenticated human authorization and
atomic idempotency/assignment validation on Student 3's endpoint.
"""

import copy
import hashlib
import json
from collections.abc import Mapping, Sequence
from typing import Literal, Protocol, TypedDict
from uuid import UUID


DispatchStatus = Literal["succeeded", "blocked", "invalid_plan", "integration_unavailable", "failed", "unknown"]


class DispatchResult(TypedDict):
    success: bool
    status: DispatchStatus
    message: str
    dispatch_id: str | None
    idempotency_key: str | None


class DispatchBackend(Protocol):
    def persist_dispatch(self, plan: dict, *, idempotency_key: str) -> dict:
        """Persist atomically through Student 3's authenticated API.

        Return {"persisted": True, "dispatch_id": <UUID>} only after confirmed
        persistence. False means confirmed non-persistence. Repeated requests
        with the same key must return the original receipt, not assign twice.
        Do not reinterpret backup entries as active assignments.
        """
        ...


def plan_fingerprint(plan: Mapping) -> str:
    """Deterministic, JSON-compatible binding to the complete reviewed proposal."""
    serialized = json.dumps(dict(plan), sort_keys=True, separators=(",", ":"), allow_nan=False)
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def _identifier(value: object) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("Incident and volunteer identifiers must be nonempty UUID strings.")
    identifier = UUID(value)
    if identifier.int == 0:
        raise ValueError("Empty UUIDs are not valid dispatch identifiers.")
    return str(identifier)


def _result(status: DispatchStatus, message: str, key: str | None = None,
            dispatch_id: str | None = None) -> DispatchResult:
    return {"success": status == "succeeded", "status": status,
            "message": message, "dispatch_id": dispatch_id, "idempotency_key": key}


def create_dispatch(
    plan: Mapping | None,
    *,
    approval: Mapping | None = None,
    validation_passed: bool = False,
    validation_is_stub: bool = False,
    validated_volunteer_ids: Sequence[str] = (),
    expected_incident_id: str | None = None,
    backend: DispatchBackend | None = None,
) -> DispatchResult:
    """Execute only an unchanged, approved and Safety-validated dispatch plan.

    With no backend adapter this deliberately returns integration_unavailable;
    it never fabricates an endpoint, updates matches, or writes to PostgreSQL.
    All checks run before any adapter call, including for direct function calls.
    """
    if not isinstance(approval, Mapping) or approval.get("decision") != "approve":
        return _result("blocked", "Explicit human approval is required.")
    if validation_passed is not True or validation_is_stub:
        return _result("blocked", "Completed Safety/Validation approval is required.")
    if not isinstance(plan, Mapping):
        return _result("invalid_plan", "A structured dispatch plan is required.")
    try:
        snapshot = copy.deepcopy(dict(plan))
        fingerprint = plan_fingerprint(snapshot)
    except (TypeError, ValueError):
        return _result("invalid_plan", "The dispatch plan must contain finite JSON-compatible values.")
    if approval.get("plan_fingerprint") != fingerprint:
        return _result("blocked", "Approval does not match the current dispatch plan.")

    try:
        incident_id = _identifier(snapshot.get("incident_id"))
        if incident_id != _identifier(expected_incident_id):
            raise ValueError("The dispatch plan belongs to a different incident.")
        assignments = snapshot.get("assignments")
        if not isinstance(assignments, list) or not assignments:
            raise ValueError("At least one ordered volunteer assignment is required.")
        volunteer_ids = []
        raw_ids = []
        for order, assignment in enumerate(assignments, 1):
            if not isinstance(assignment, dict):
                raise ValueError("Each assignment must be a structured object.")
            if type(assignment.get("order")) is not int or assignment["order"] != order:
                raise ValueError("Assignment order must be consecutive, starting at 1.")
            if assignment.get("role", "dispatch") != "dispatch":
                raise ValueError("Only active dispatch assignments are supported; backups must not be dispatched.")
            raw_ids.append(assignment.get("volunteer_id"))
            volunteer_ids.append(_identifier(assignment.get("volunteer_id")))
        if len(set(volunteer_ids)) != len(volunteer_ids):
            raise ValueError("A volunteer cannot appear more than once in a dispatch.")
        if snapshot.get("assigned_volunteers") != raw_ids:
            raise ValueError("Assigned volunteer IDs must match the ordered assignments.")
        if isinstance(validated_volunteer_ids, (str, bytes)):
            raise ValueError("Validated volunteer IDs must be a sequence of UUIDs.")
        validated = {_identifier(value) for value in validated_volunteer_ids}
        if not set(volunteer_ids).issubset(validated):
            return _result("blocked", "Every assignment must belong to the Safety-validated volunteer set.")
    except (ValueError, TypeError, AttributeError):
        return _result("invalid_plan", "Invalid incident/volunteer IDs, assignment order, roles, or validated set.")

    key = f"dispatch:{fingerprint}"
    if backend is None:
        return _result("integration_unavailable",
                       "Student 3's dispatch backend is not integrated. No dispatch was persisted.", key)
    try:
        receipt = backend.persist_dispatch(snapshot, idempotency_key=key)
    except Exception:
        # A transport error can occur after a successful server commit.
        return _result("unknown", "Dispatch outcome is unknown. Reconcile using the same idempotency key.", key)
    if not isinstance(receipt, Mapping):
        return _result("unknown", "The backend did not return a valid persistence receipt.", key)
    if receipt.get("persisted") is False:
        return _result("failed", "The backend confirmed that no dispatch was persisted.", key)
    try:
        dispatch_id = _identifier(receipt.get("dispatch_id"))
    except ValueError:
        return _result("unknown", "The backend did not return a valid dispatch identifier.", key)
    if receipt.get("persisted") is not True:
        return _result("unknown", "The backend did not confirm persistence.", key)
    return _result("succeeded", "Approved dispatch persisted successfully.", key, dispatch_id)
