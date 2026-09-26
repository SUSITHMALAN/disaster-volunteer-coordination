import copy
import unittest
from unittest.mock import Mock

from tools.dispatch_tools import create_dispatch, plan_fingerprint

INCIDENT_ID = "6bf94b77-2ede-4cc3-9e52-3e549667bcea"
VOLUNTEER_ID = "73f8f3af-9fb3-49bd-8602-27609e6d8901"
DISPATCH_ID = "5f7c82a0-a4db-4a1b-baae-3f744bb50abb"


def plan_fixture():
    return {"incident_id": INCIDENT_ID, "assigned_volunteers": [VOLUNTEER_ID],
            "assignments": [{"order": 1, "volunteer_id": VOLUNTEER_ID,
                             "justification": "Validated primary volunteer."}],
            "severity": "High", "zone": "North", "summary": "Proposed response."}


def approval_for(plan):
    return {"decision": "approve", "plan_fingerprint": plan_fingerprint(plan)}


class DispatchToolTests(unittest.TestCase):
    def setUp(self):
        self.plan = plan_fixture()
        self.backend = Mock()
        self.backend.persist_dispatch.return_value = {"persisted": True, "dispatch_id": DISPATCH_ID}

    def execute(self, **changes):
        arguments = {"approval": approval_for(self.plan), "validation_passed": True,
                     "validated_volunteer_ids": [VOLUNTEER_ID], "expected_incident_id": INCIDENT_ID,
                     "backend": self.backend}
        arguments.update(changes)
        return create_dispatch(self.plan, **arguments)

    def test_unapproved_rejected_revised_and_malformed_approval_never_reach_backend(self):
        for approval in (None, {}, True, {"decision": "reject"}, {"decision": "revise"},
                         {"decision": "approve"}):
            with self.subTest(approval=approval):
                self.assertEqual(self.execute(approval=approval)["status"], "blocked")
                self.backend.persist_dispatch.assert_not_called()

    def test_failed_stub_or_ineligible_validation_never_reaches_backend(self):
        for changes in ({"validation_passed": False}, {"validation_is_stub": True},
                        {"validated_volunteer_ids": []}):
            with self.subTest(changes=changes):
                self.assertEqual(self.execute(**changes)["status"], "blocked")
                self.backend.persist_dispatch.assert_not_called()

    def test_changed_plan_invalidates_approval(self):
        approval = approval_for(self.plan)
        self.plan["summary"] = "Changed after approval"
        self.assertEqual(self.execute(approval=approval)["status"], "blocked")
        self.backend.persist_dispatch.assert_not_called()

    def test_invalid_identifiers_and_assignment_structure_never_reach_backend(self):
        for change in (
            lambda p: p.update(incident_id=""),
            lambda p: p.update(incident_id="not-a-uuid"),
            lambda p: p.update(incident_id="00000000-0000-0000-0000-000000000000"),
            lambda p: p.update(assignments=[]),
            lambda p: p["assignments"][0].update(volunteer_id="V102"),
            lambda p: p["assignments"][0].update(order=True),
            lambda p: p["assignments"][0].update(order=2),
            lambda p: p["assignments"][0].update(role="backup"),
            lambda p: p.update(assigned_volunteers=[]),
        ):
            self.plan = plan_fixture()
            change(self.plan)
            self.assertEqual(self.execute()["status"], "invalid_plan")
            self.backend.persist_dispatch.assert_not_called()

    def test_duplicate_and_cross_incident_assignments_are_rejected(self):
        self.plan["assignments"].append({"order": 2, "volunteer_id": VOLUNTEER_ID})
        self.plan["assigned_volunteers"].append(VOLUNTEER_ID)
        self.assertEqual(self.execute()["status"], "invalid_plan")
        self.plan = plan_fixture()
        self.assertEqual(self.execute(expected_incident_id=DISPATCH_ID)["status"], "invalid_plan")
        self.backend.persist_dispatch.assert_not_called()

    def test_missing_integration_is_explicit_and_not_success(self):
        result = self.execute(backend=None)
        self.assertEqual(result["status"], "integration_unavailable")
        self.assertFalse(result["success"])
        self.assertIsNone(result["dispatch_id"])

    def test_confirmed_success_uses_stable_key_and_does_not_mutate_plan(self):
        before = copy.deepcopy(self.plan)
        first = self.execute()
        second = self.execute()
        self.assertTrue(first["success"])
        self.assertEqual(first["dispatch_id"], DISPATCH_ID)
        self.assertEqual(first["idempotency_key"], second["idempotency_key"])
        self.assertEqual(self.plan, before)
        self.assertIsNot(self.backend.persist_dispatch.call_args.args[0], self.plan)

    def test_backend_failure_and_unknown_outcome_are_not_success(self):
        for receipt, status in (({"persisted": False}, "failed"),
                                ({"persisted": True}, "unknown"),
                                ({"dispatch_id": DISPATCH_ID}, "unknown"), (None, "unknown")):
            self.backend.persist_dispatch.return_value = receipt
            result = self.execute()
            self.assertEqual(result["status"], status)
            self.assertFalse(result["success"])
        self.backend.persist_dispatch.side_effect = TimeoutError()
        self.assertEqual(self.execute()["status"], "unknown")


if __name__ == "__main__":
    unittest.main()
