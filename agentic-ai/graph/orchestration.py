from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt
from langgraph.checkpoint.memory import MemorySaver

from .state import AgentState
from agents.matching_agent import run_matching
from agents.triage_agent import run_triage
from agents.coordinator_agent import run_coordinator


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
                "human_decision": None, "status": "rejected"}

    decision = interrupt({
        "dispatch_plan": dispatch_plan,
        "summary": summary,
        "message": "Approve, reject, or request revision for this dispatch plan.",
    })

    return {
        "dispatch_plan": dispatch_plan,
        "dispatch_summary": summary,
        "human_decision": decision.get("decision"),
        "human_feedback": decision.get("feedback"),
        "status": "approved" if decision.get("decision") == "approve" else "rejected",
    }


def route_after_validation(state: AgentState) -> str:
    return "coordinator" if (
        state.get("validation_passed") is True and not state.get("validation_is_stub")
    ) else END


def build_graph():
    graph = StateGraph(AgentState)

    graph.add_node("triage", triage_node)
    graph.add_node("matching", matching_node)
    graph.add_node("validation", validation_node)
    graph.add_node("coordinator", coordinator_node)

    graph.add_edge(START, "triage")
    graph.add_edge("triage", "matching")
    graph.add_edge("matching", "validation")
    graph.add_conditional_edges("validation", route_after_validation, {
        "coordinator": "coordinator",
        END: END,
    })
    graph.add_edge("coordinator", END)

    checkpointer = MemorySaver()
    return graph.compile(checkpointer=checkpointer)
