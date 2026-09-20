from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt
from langgraph.checkpoint.memory import MemorySaver

from .state import AgentState
from agents.matching_agent import run_matching
from agents.triage_agent import run_triage
from agents.coordinator_agent import run_coordinator
from tools.dispatch_tools import DispatchBackend, create_dispatch, plan_fingerprint


def triage_node(state: AgentState) -> dict:
    """Student 1: Triage/Intake Agent."""
    result = run_triage(
        raw_report_text=state.get("raw_report_text") or "",
        existing_required_skills=state.get("required_skills"),
    )
    return {
        **result,
        "status": "pending_matching",
    }


def matching_node(state: AgentState) -> dict:
    """Student 2: Matching Agent."""
    result = run_matching(
        incident_id=state.get("incident_id"),
        required_skills=state.get("required_skills") or [],
        zone=state.get("zone"),
    )
    return {
        **result,
        "status": "pending_validation",
    }


def validation_node(state: AgentState) -> dict:
    """Student 3: Safety/Validation Agent."""
    return {
        "validation_passed": True,
        "validation_notes": "Stub: no rules evaluated yet.",
        "validation_is_stub": True,
        "status": "pending_validation",
    }


def coordinator_node(state: AgentState) -> dict:
    """Student 4: Coordinator/Dispatch Agent."""
    dispatch_plan = run_coordinator(state)
    summary = dispatch_plan["summary"]
    if not dispatch_plan["assignments"]:
        return {"dispatch_plan": dispatch_plan, "dispatch_summary": summary,
                "dispatch_approval": None, "dispatch_result": None,
                "human_decision": None, "status": "rejected"}

    decision = interrupt({
        "dispatch_plan": dispatch_plan,
        "summary": summary,
        "message": "Approve, reject, or request revision for this dispatch plan.",
    })

    # Only this resumed approval boundary creates approval evidence. Client input
    # cannot replace the reviewed plan or supply an approval record directly.
    if not isinstance(decision, dict):
        decision = {}
    approved = decision.get("decision") == "approve"

    return {
        "dispatch_plan": dispatch_plan,
        "dispatch_summary": summary,
        "human_decision": decision.get("decision"),
        "human_feedback": decision.get("feedback"),
        "dispatch_approval": {"decision": "approve", "plan_fingerprint": plan_fingerprint(dispatch_plan)}
            if approved else None,
        "dispatch_result": None,
        "status": "approved" if approved else "rejected",
    }


def route_after_coordinator(state: AgentState) -> str:
    return "dispatch" if state.get("status") == "approved" and state.get("human_decision") == "approve" else END


def dispatch_node(state: AgentState, backend: DispatchBackend | None = None) -> dict:
    # Guard the node as well as the graph edge: rejected/unapproved states must
    # never call the execution function, even when this node is invoked directly.
    if state.get("status") != "approved" or state.get("human_decision") != "approve":
        return {"status": "dispatch_blocked", "dispatch_result": {
            "success": False, "status": "blocked", "message": "Explicit human approval is required.",
            "dispatch_id": None, "idempotency_key": None,
        }}
    validated_ids = state.get("validated_volunteer_ids")
    if validated_ids is None:
        # Existing Safety contract applies its overall result to the matched set.
        validated_ids = state.get("matched_volunteer_ids") or []
    result = create_dispatch(
        state.get("dispatch_plan"), approval=state.get("dispatch_approval"),
        validation_passed=state.get("validation_passed") is True,
        validation_is_stub=bool(state.get("validation_is_stub")),
        validated_volunteer_ids=validated_ids,
        expected_incident_id=state.get("incident_id"), backend=backend,
    )
    status = {"succeeded": "dispatched", "unknown": "dispatch_unknown",
              "failed": "dispatch_failed"}.get(result["status"], "dispatch_blocked")
    return {"dispatch_result": result, "status": status}


def route_after_validation(state: AgentState) -> str:
    return "coordinator" if (
        state.get("validation_passed") is True and not state.get("validation_is_stub")
    ) else END


def build_graph(dispatch_backend: DispatchBackend | None = None):
    graph = StateGraph(AgentState)

    graph.add_node("triage", triage_node)
    graph.add_node("matching", matching_node)
    graph.add_node("validation", validation_node)
    graph.add_node("coordinator", coordinator_node)
    def execute_dispatch(state: AgentState) -> dict:
        return dispatch_node(state, backend=dispatch_backend)
    graph.add_node("dispatch", execute_dispatch)

    graph.add_edge(START, "triage")
    graph.add_edge("triage", "matching")
    graph.add_edge("matching", "validation")
    graph.add_conditional_edges("validation", route_after_validation, {
        "coordinator": "coordinator",
        END: END,
    })
    graph.add_conditional_edges("coordinator", route_after_coordinator, {
        "dispatch": "dispatch", END: END,
    })
    graph.add_edge("dispatch", END)

    checkpointer = MemorySaver()
    return graph.compile(checkpointer=checkpointer)
