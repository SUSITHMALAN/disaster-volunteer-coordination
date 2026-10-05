import unittest
from unittest.mock import MagicMock, patch

from tools.auth_context import authorization_header
from tools.http_dispatch_backend import HttpDispatchBackend


def dispatch_plan():
    return {
        "incident_id": "incident-1",
        "estimated_duration_minutes": 120,
        "assigned_volunteers": ["volunteer-1"],
        "assignments": [
            {
                "order": 1,
                "volunteer_id": "volunteer-1",
                "match_id": "match-1",
                "volunteer_name": "Alice",
                "match_score": 0.9,
                "justification": "Validated volunteer.",
            }
        ],
    }


def response(json_data, status_code=200):
    mock = MagicMock()
    mock.status_code = status_code
    mock.content = b"{}"
    mock.json.return_value = json_data
    mock.raise_for_status.return_value = None
    return mock


class TestHttpDispatchBackend(unittest.TestCase):

    def setUp(self):
        self.backend = HttpDispatchBackend(
            base_url="http://localhost:5030"
        )

        self.auth_token = authorization_header.set(
            "Bearer test-token"
        )

    def tearDown(self):
        authorization_header.reset(
            self.auth_token
        )

    def test_requires_forwarded_bearer_token(self):
        authorization_header.reset(
            self.auth_token
        )

        self.auth_token = authorization_header.set(
            None
        )

        with self.assertRaisesRegex(
            RuntimeError,
            "bearer token",
        ):
            self.backend._headers()

    @patch("tools.http_dispatch_backend.requests.request")
    def test_persist_dispatch_completes_full_flow(
        self,
        mock_request,
    ):
        mock_request.side_effect = [
            # GET /api/Matches
            response([
                {
                    "id": "match-1",
                    "incidentId": "incident-1",
                    "volunteerId": "volunteer-1",
                    "status": "Proposed",
                }
            ]),

            # PATCH /api/Matches/match-1/status
            response({
                "id": "match-1",
                "status": "Approved",
            }),

            # GET /api/Assignments/history
            response([]),

            # POST /api/Assignments
            response({
                "id": "assignment-1",
                "incidentId": "incident-1",
                "volunteerId": "volunteer-1",
                "matchId": "match-1",
                "status": "Assigned",
            }),

            # GET /api/Dispatches/history
            response([]),

            # POST /api/Dispatches
            response({
                "id": "dispatch-1",
                "incidentId": "incident-1",
                "idempotencyKey": "dispatch:key-1",
            }),

            # PATCH assignment -> Dispatched
            response({
                "id": "assignment-1",
                "status": "Dispatched",
            }),
        ]

        result = self.backend.persist_dispatch(
            dispatch_plan(),
            idempotency_key="dispatch:key-1",
        )

        self.assertEqual(
            result,
            {
                "persisted": True,
                "dispatch_id": "dispatch-1",
            },
        )

        self.assertEqual(
            mock_request.call_count,
            7,
        )

    @patch.object(
        HttpDispatchBackend,
        "_mark_assignment_dispatched",
    )
    @patch.object(
        HttpDispatchBackend,
        "_find_existing_dispatch",
    )
    @patch.object(
        HttpDispatchBackend,
        "_create_or_reuse_assignment",
    )
    @patch.object(
        HttpDispatchBackend,
        "_approve_match",
    )
    def test_existing_dispatch_reconciles_assignment_status(
        self,
        mock_approve,
        mock_assignment,
        mock_find_dispatch,
        mock_mark_dispatched,
    ):
        mock_assignment.return_value = {
            "id": "assignment-1",
            "status": "Assigned",
            "matchId": "match-1",
        }

        mock_find_dispatch.return_value = {
            "id": "dispatch-existing",
            "incidentId": "incident-1",
            "idempotencyKey": "dispatch:key-1",
        }

        result = self.backend.persist_dispatch(
            dispatch_plan(),
            idempotency_key="dispatch:key-1",
        )

        self.assertEqual(
            result,
            {
                "persisted": True,
                "dispatch_id": "dispatch-existing",
            },
        )

        mock_approve.assert_called_once_with(
            "incident-1",
            "match-1",
        )

        mock_assignment.assert_called_once_with(
            "incident-1",
            "volunteer-1",
            "match-1",
            120,
        )

        mock_find_dispatch.assert_called_once_with(
            "incident-1",
            "dispatch:key-1",
        )

        mock_mark_dispatched.assert_called_once_with(
            mock_assignment.return_value
        )

    def test_missing_match_id_is_rejected(self):
        plan = dispatch_plan()

        plan["assignments"][0]["match_id"] = None

        with patch.object(
            self.backend,
            "_approve_match",
        ):
            with self.assertRaisesRegex(
                ValueError,
                "persisted match ID",
            ):
                self.backend.persist_dispatch(
                    plan,
                    idempotency_key="dispatch:key-1",
                )

    def test_invalid_duration_is_rejected(self):
        plan = dispatch_plan()

        plan["estimated_duration_minutes"] = 0

        with self.assertRaisesRegex(
            ValueError,
            "positive number",
        ):
            self.backend.persist_dispatch(
                plan,
                idempotency_key="dispatch:key-1",
            )

    @patch("tools.http_dispatch_backend.requests.request")
    def test_authorization_header_is_sent_to_backend(
        self,
        mock_request,
    ):
        mock_request.return_value = response([])

        self.backend._find_existing_dispatch(
            "incident-1",
            "dispatch:key-1",
        )

        sent_headers = (
            mock_request.call_args.kwargs["headers"]
        )

        self.assertEqual(
            sent_headers["Authorization"],
            "Bearer test-token",
        )


if __name__ == "__main__":
    unittest.main()