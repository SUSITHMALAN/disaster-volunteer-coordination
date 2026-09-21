"""Graph tests use controlled team-agent fixtures, never live HTTP or LLM calls."""
import unittest
from unittest.mock import Mock, patch

from langgraph.types import Command
from graph.orchestration import build_graph
from graph.orchestration import dispatch_node
from agents.coordinator_agent import run_coordinator
from tools.dispatch_tools import create_dispatch
from tests.test_dispatch_tools import INCIDENT_ID, VOLUNTEER_ID, DISPATCH_ID


class OrchestrationTests(unittest.TestCase):
    def setUp(self):
        # Fail accidental network access even if a future implementation adds it.
        for target in ("socket.socket.connect", "socket.socket.connect_ex"):
            guard = patch(target, side_effect=AssertionError("Unit tests must not access external services"))
            guard.start()
            self.addCleanup(guard.stop)

    def _start(self, validation, backend=None, matched_ids=None, incident_id=INCIDENT_ID):
        with patch("graph.orchestration.run_triage", return_value={"severity": "High", "zone": "North"}), \
             patch("graph.orchestration.run_matching", return_value={
                 "matched_volunteer_ids": [VOLUNTEER_ID] if matched_ids is None else matched_ids,
                 "candidate_volunteers": [{"id": VOLUNTEER_ID, "fullName": "Asha", "isAvailable": True}],
             }), patch("graph.orchestration.validation_node", return_value=validation):
            app = build_graph(dispatch_backend=backend)
            config = {"configurable": {"thread_id": "test-1"}}
            result = app.invoke({"incident_id": incident_id, "raw_report_text": "Flood"}, config=config)
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
        for decision in ("reject", "invalid"):
            with self.subTest(decision=decision), patch("graph.orchestration.create_dispatch") as execute:
                app, config, _ = self._start({"validation_passed": True, "validation_is_stub": False})
                execute.assert_not_called()
                final = app.invoke(Command(resume={"decision": decision, "feedback": "Not yet."}), config=config)
                self.assertEqual(final["status"], "rejected")
                self.assertNotIn("__interrupt__", final)
                self.assertEqual(app.get_state(config).next, ())
                execute.assert_not_called()

    def test_tool_only_called_after_approval_and_confirmed_receipt_marks_dispatched(self):
        backend = Mock()
        backend.persist_dispatch.return_value = {"persisted": True, "dispatch_id": DISPATCH_ID}
        with patch("graph.orchestration.create_dispatch", wraps=create_dispatch) as execute:
            app, config, result = self._start({"validation_passed": True, "validation_is_stub": False}, backend)
            self.assertIn("__interrupt__", result)
            proposal = result["__interrupt__"][0].value["dispatch_plan"]
            execute.assert_not_called()
            backend.persist_dispatch.assert_not_called()
            final = app.invoke(Command(resume={"decision": "approve"}), config=config)
            execute.assert_called_once()
            backend.persist_dispatch.assert_called_once()
            self.assertEqual(final["status"], "dispatched")
            self.assertTrue(final["dispatch_result"]["success"])
            self.assertEqual(final["dispatch_plan"], proposal)
            self.assertEqual(backend.persist_dispatch.call_args.args[0], proposal)

    def test_revision_regenerates_proposal_and_requires_fresh_approval(self):
        backend = Mock()
        backend.persist_dispatch.return_value = {"persisted": True, "dispatch_id": DISPATCH_ID}
        feedback = "Review water availability before dispatching."
        with patch("graph.orchestration.create_dispatch", wraps=create_dispatch) as execute:
            app, config, initial = self._start({"validation_passed": True, "validation_is_stub": False}, backend)
            original = initial["__interrupt__"][0].value["dispatch_plan"]
            revised = app.invoke(Command(resume={"decision": "revise", "feedback": feedback}), config=config)
            self.assertEqual(revised["status"], "revision_requested")
            self.assertEqual(revised["human_decision"], "revise")
            self.assertEqual(revised["human_feedback"], feedback)
            self.assertIsNone(revised["dispatch_approval"])
            self.assertIsNone(revised["dispatch_result"])
            proposal = revised["__interrupt__"][0].value["dispatch_plan"]
            self.assertEqual(proposal["human_feedback"], feedback)
            self.assertEqual(proposal["assigned_volunteers"], original["assigned_volunteers"])
            self.assertNotEqual(proposal, original)
            with self.assertRaises(ValueError):
                run_coordinator({**revised, "validation_passed": False})
            execute.assert_not_called()
            backend.persist_dispatch.assert_not_called()
            final = app.invoke(Command(resume={"decision": "approve"}), config=config)
            self.assertEqual(final["status"], "dispatched")
            self.assertEqual(final["dispatch_plan"], proposal)
            execute.assert_called_once()
            backend.persist_dispatch.assert_called_once()
            self.assertEqual(backend.persist_dispatch.call_args.args[0], proposal)

    def test_repeated_revisions_then_rejection_never_execute(self):
        backend = Mock()
        with patch("graph.orchestration.create_dispatch") as execute:
            app, config, _ = self._start({"validation_passed": True, "validation_is_stub": False}, backend)
            for feedback in ("Check supplies.", "Review the zone coverage."):
                result = app.invoke(Command(resume={"decision": "revise", "feedback": feedback}), config=config)
                self.assertEqual(result["status"], "revision_requested")
                self.assertEqual(result["__interrupt__"][0].value["dispatch_plan"]["human_feedback"], feedback)
                self.assertIsNone(result["dispatch_approval"])
                execute.assert_not_called()
                backend.persist_dispatch.assert_not_called()
            final = app.invoke(Command(resume={"decision": "reject"}), config=config)
            self.assertEqual(final["status"], "rejected")
            self.assertNotIn("__interrupt__", final)
            self.assertEqual(app.get_state(config).next, ())
            execute.assert_not_called()
            backend.persist_dispatch.assert_not_called()

    def test_no_matched_volunteers_never_reach_approval_or_execution(self):
        backend = Mock()
        with patch("graph.orchestration.create_dispatch") as execute:
            _, _, result = self._start({"validation_passed": True, "validation_is_stub": False},
                                       backend, matched_ids=[])
            self.assertNotIn("__interrupt__", result)
            self.assertEqual(result["status"], "rejected")
            self.assertEqual(result["dispatch_plan"]["assignments"], [])
            execute.assert_not_called()
            backend.persist_dispatch.assert_not_called()

    def test_missing_incident_id_never_executes_dispatch(self):
        backend = Mock()
        with patch("graph.orchestration.create_dispatch") as execute:
            with self.assertRaisesRegex(ValueError, "incident ID is required"):
                self._start({"validation_passed": True, "validation_is_stub": False}, backend, incident_id=None)
            execute.assert_not_called()
            backend.persist_dispatch.assert_not_called()

    def test_direct_node_invocation_without_approval_does_not_call_tool(self):
        with patch("graph.orchestration.create_dispatch") as execute:
            for state in ({}, {"status": "rejected", "human_decision": "reject"},
                          {"status": "approved", "human_decision": "revise"},
                          {"status": "pending_approval", "human_decision": "approve"}):
                self.assertEqual(dispatch_node(state)["status"], "dispatch_blocked")
            execute.assert_not_called()

    def test_failed_validation_and_stub_never_reach_approval(self):
        for validation in ({"validation_passed": False}, {"validation_passed": True, "validation_is_stub": True}):
            with self.subTest(validation=validation), patch("graph.orchestration.create_dispatch") as execute:
                backend = Mock()
                _, _, result = self._start(validation, backend)
                self.assertNotIn("__interrupt__", result)
                self.assertNotIn("dispatch_plan", result)
                execute.assert_not_called()
                backend.persist_dispatch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
