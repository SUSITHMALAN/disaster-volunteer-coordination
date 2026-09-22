"""
Integration tests for the FastAPI bridge (api.py).

The LangGraph graph is mocked so no real agents or DB connections are needed.
Tests cover all three endpoints: POST /workflows, GET /workflows/{id},
POST /workflows/{id}/approve.
"""
import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient


# ── Shared graph mock factory ─────────────────────────────────────────────────

def _make_graph_mock(
    invoke_result=None,
    state_values=None,
    state_tasks=None,
):
    """Return a mock CompiledGraph with controllable invoke/get_state behaviour."""
    if invoke_result is None:
        invoke_result = {
            "status": "pending_approval",
            "category": "Flood",
            "severity": "High",
            "__interrupt__": [{"value": {"message": "approve?"}}],
        }

    mock_graph = MagicMock()
    mock_graph.invoke.return_value = invoke_result

    mock_state = MagicMock()
    mock_state.values = state_values or {
        "status": "pending_approval",
        "category": "Flood",
    }
    mock_state.tasks = state_tasks or []
    mock_graph.get_state.return_value = mock_state

    return mock_graph


# ── Test class ────────────────────────────────────────────────────────────────

class TestApiEndpoints(unittest.TestCase):

    def setUp(self):
        """
        Patch build_graph before importing api so _graph is always a mock.
        The lifespan runs synchronously inside TestClient context.
        """
        self.graph_mock = _make_graph_mock()
        self._patcher = patch("graph.orchestration.build_graph", return_value=self.graph_mock)
        self._patcher.start()

        # Import after patching so the lifespan picks up the mock
        import importlib
        import api as api_module
        importlib.reload(api_module)
        api_module._graph = self.graph_mock
        self.app = api_module.app
        self.client = TestClient(self.app)

    def tearDown(self):
        self._patcher.stop()

    # ── POST /workflows ────────────────────────────────────────────────────

    def test_start_workflow_returns_200_with_thread_id(self):
        resp = self.client.post("/workflows", json={
            "incident_id": "inc-001",
            "raw_report_text": "Flooding near the bridge.",
            "required_skills": ["first-aid"],
        })
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertIn("thread_id", body)
        self.assertIsInstance(body["thread_id"], str)
        self.assertNotEqual(body["thread_id"], "")

    def test_start_workflow_returns_awaiting_approval_true_when_interrupted(self):
        resp = self.client.post("/workflows", json={
            "incident_id": "inc-001",
            "raw_report_text": "Flooding near the bridge.",
        })
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json()["awaiting_approval"])

    def test_start_workflow_omits_interrupt_key_from_state(self):
        resp = self.client.post("/workflows", json={
            "incident_id": "inc-001",
            "raw_report_text": "Flooding near the bridge.",
        })
        state = resp.json()["state"]
        self.assertNotIn("__interrupt__", state)

    def test_start_workflow_returns_false_awaiting_when_no_interrupt(self):
        self.graph_mock.invoke.return_value = {"status": "approved"}
        resp = self.client.post("/workflows", json={
            "incident_id": "inc-002",
            "raw_report_text": "Minor incident.",
        })
        self.assertFalse(resp.json()["awaiting_approval"])

    # ── GET /workflows/{thread_id} ─────────────────────────────────────────

    def test_get_status_returns_200_for_known_thread(self):
        resp = self.client.get("/workflows/thread-123")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["thread_id"], "thread-123")

    def test_get_status_returns_404_for_unknown_thread(self):
        mock_state = MagicMock()
        mock_state.values = {}
        self.graph_mock.get_state.return_value = mock_state

        resp = self.client.get("/workflows/no-such-thread")
        self.assertEqual(resp.status_code, 404)

    def test_get_status_returns_awaiting_true_when_tasks_have_interrupts(self):
        mock_interrupt = MagicMock()
        mock_interrupt.interrupts = [MagicMock()]
        mock_state = MagicMock()
        mock_state.values = {"status": "pending_approval"}
        mock_state.tasks = [mock_interrupt]
        self.graph_mock.get_state.return_value = mock_state

        resp = self.client.get("/workflows/thread-123")
        self.assertTrue(resp.json()["awaiting_approval"])

    def test_get_status_returns_awaiting_false_when_no_tasks(self):
        mock_state = MagicMock()
        mock_state.values = {"status": "approved"}
        mock_state.tasks = []
        self.graph_mock.get_state.return_value = mock_state

        resp = self.client.get("/workflows/thread-123")
        self.assertFalse(resp.json()["awaiting_approval"])

    # ── POST /workflows/{thread_id}/approve ───────────────────────────────

    def test_approve_returns_200_with_state(self):
        self.graph_mock.invoke.return_value = {"status": "approved"}
        resp = self.client.post("/workflows/thread-abc/approve", json={
            "decision": "approve",
            "feedback": "All good.",
        })
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["state"]["status"], "approved")

    def test_approve_reject_returns_rejected_status(self):
        self.graph_mock.invoke.return_value = {"status": "rejected"}
        resp = self.client.post("/workflows/thread-abc/approve", json={
            "decision": "reject",
        })
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["state"]["status"], "rejected")

    def test_approve_passes_command_with_decision_and_feedback(self):
        from langgraph.types import Command
        self.graph_mock.invoke.return_value = {"status": "approved"}
        self.client.post("/workflows/thread-abc/approve", json={
            "decision": "approve",
            "feedback": "Looks good.",
        })
        call_args = self.graph_mock.invoke.call_args
        command = call_args[0][0]
        self.assertIsInstance(command, Command)
        self.assertEqual(command.resume["decision"], "approve")
        self.assertEqual(command.resume["feedback"], "Looks good.")


if __name__ == "__main__":
    unittest.main()
