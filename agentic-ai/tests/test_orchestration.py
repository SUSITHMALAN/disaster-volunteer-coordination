"""Graph tests use controlled team-agent fixtures, never live HTTP or LLM calls."""
import unittest
from unittest.mock import patch

from langgraph.types import Command
from graph.orchestration import build_graph


class OrchestrationTests(unittest.TestCase):
    def _start(self, validation):
        with patch("graph.orchestration.run_triage", return_value={"severity": "High", "zone": "North"}), \
             patch("graph.orchestration.run_matching", return_value={
                 "matched_volunteer_ids": ["volunteer-1"],
                 "candidate_volunteers": [{"id": "volunteer-1", "fullName": "Asha", "isAvailable": True}],
             }), patch("graph.orchestration.validation_node", return_value=validation):
            app = build_graph()
            config = {"configurable": {"thread_id": "test-1"}}
            result = app.invoke({"incident_id": "incident-1", "raw_report_text": "Flood"}, config=config)
        return app, config, result

    def test_graph_pauses_with_structured_proposal_then_accepts_approval(self):
        app, config, result = self._start({"validation_passed": True, "validation_is_stub": False})
        self.assertIn("__interrupt__", result)
        plan = result["__interrupt__"][0].value["dispatch_plan"]
        self.assertEqual(plan["assignments"][0]["volunteer_id"], "volunteer-1")
        self.assertNotEqual(result.get("status"), "approved")
        final = app.invoke(Command(resume={"decision": "approve", "feedback": "Looks good."}), config=config)
        self.assertEqual(final["status"], "approved")
        self.assertEqual(final["dispatch_plan"], plan)

    def test_rejection_does_not_approve(self):
        app, config, _ = self._start({"validation_passed": True, "validation_is_stub": False})
        final = app.invoke(Command(resume={"decision": "reject", "feedback": "Not yet."}), config=config)
        self.assertEqual(final["status"], "rejected")

    def test_failed_validation_and_stub_never_reach_approval(self):
        for validation in ({"validation_passed": False}, {"validation_passed": True, "validation_is_stub": True}):
            with self.subTest(validation=validation):
                _, _, result = self._start(validation)
                self.assertNotIn("__interrupt__", result)
                self.assertNotIn("dispatch_plan", result)


if __name__ == "__main__":
    unittest.main()
