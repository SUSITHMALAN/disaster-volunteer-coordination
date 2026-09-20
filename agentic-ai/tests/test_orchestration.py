"""Graph tests use controlled team-agent fixtures, never live HTTP or LLM calls."""
import unittest
from unittest.mock import patch

from langgraph.types import Command
from graph.orchestration import build_graph
from graph.orchestration import dispatch_node
from tools.dispatch_tools import create_dispatch
from tests.test_dispatch_tools import INCIDENT_ID, VOLUNTEER_ID, DISPATCH_ID


class OrchestrationTests(unittest.TestCase):
    def _start(self, validation, backend=None):
        with patch("graph.orchestration.run_triage", return_value={"severity": "High", "zone": "North"}), \
             patch("graph.orchestration.run_matching", return_value={
                 "matched_volunteer_ids": [VOLUNTEER_ID],
                 "candidate_volunteers": [{"id": VOLUNTEER_ID, "fullName": "Asha", "isAvailable": True}],
             }), patch("graph.orchestration.validation_node", return_value=validation):
            app = build_graph(dispatch_backend=backend)
            config = {"configurable": {"thread_id": "test-1"}}
            result = app.invoke({"incident_id": INCIDENT_ID, "raw_report_text": "Flood"}, config=config)
        return app, config, result

    def test_graph_pauses_with_structured_proposal_then_accepts_approval(self):
        app, config, result = self._start({"validation_passed": True, "validation_is_stub": False})
        self.assertIn("__interrupt__", result)
        plan = result["__interrupt__"][0].value["dispatch_plan"]
        self.assertEqual(plan["assignments"][0]["volunteer_id"], VOLUNTEER_ID)
        self.assertNotEqual(result.get("status"), "approved")
        final = app.invoke(Command(resume={"decision": "approve", "feedback": "Looks good."}), config=config)
        self.assertEqual(final["status"], "dispatch_blocked")
        self.assertEqual(final["dispatch_result"]["status"], "integration_unavailable")
        self.assertEqual(final["human_decision"], "approve")
        self.assertEqual(final["dispatch_plan"], plan)

    def test_rejection_does_not_approve(self):
        for decision in ("reject", "revise", "invalid"):
            with self.subTest(decision=decision), patch("graph.orchestration.create_dispatch") as execute:
                app, config, _ = self._start({"validation_passed": True, "validation_is_stub": False})
                execute.assert_not_called()
                final = app.invoke(Command(resume={"decision": decision, "feedback": "Not yet."}), config=config)
                self.assertEqual(final["status"], "rejected")
                execute.assert_not_called()

    def test_tool_only_called_after_approval_and_confirmed_receipt_marks_dispatched(self):
        from unittest.mock import Mock
        backend = Mock()
        backend.persist_dispatch.return_value = {"persisted": True, "dispatch_id": DISPATCH_ID}
        with patch("graph.orchestration.create_dispatch", wraps=create_dispatch) as execute:
            app, config, result = self._start({"validation_passed": True, "validation_is_stub": False}, backend)
            self.assertIn("__interrupt__", result)
            execute.assert_not_called()
            backend.persist_dispatch.assert_not_called()
            final = app.invoke(Command(resume={"decision": "approve"}), config=config)
            execute.assert_called_once()
            backend.persist_dispatch.assert_called_once()
            self.assertEqual(final["status"], "dispatched")
            self.assertTrue(final["dispatch_result"]["success"])

    def test_direct_node_invocation_without_approval_does_not_call_tool(self):
        with patch("graph.orchestration.create_dispatch") as execute:
            for state in ({}, {"status": "rejected", "human_decision": "reject"},
                          {"status": "approved", "human_decision": "revise"},
                          {"status": "pending_approval", "human_decision": "approve"}):
                self.assertEqual(dispatch_node(state)["status"], "dispatch_blocked")
            execute.assert_not_called()

    def test_failed_validation_and_stub_never_reach_approval(self):
        for validation in ({"validation_passed": False}, {"validation_passed": True, "validation_is_stub": True}):
            with self.subTest(validation=validation):
                _, _, result = self._start(validation)
                self.assertNotIn("__interrupt__", result)
                self.assertNotIn("dispatch_plan", result)


if __name__ == "__main__":
    unittest.main()
