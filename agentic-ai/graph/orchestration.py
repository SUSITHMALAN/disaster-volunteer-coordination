from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt
from langgraph.checkpoint.memory import MemorySaver

from .state import AgentState


# --- Node stubs — each teammate replaces the body of their own function ---

def triage_node(state: AgentState) -> dict:
    """Student 1: Triage/Intake Agent.
    Classifies raw_report_text into category, severity, required_skills, zone.
    """
    # TODO: replace with real LLM + geocoding logic
    return {
        "category": "Other",
        "severity": "Medium",
        "required_skills": state.get("required_skills") or [],
        "zone": "Unknown",
        "triage_confidence": 1.0,
        "status": "pending_matching",
    }


def matching_node(state: AgentState) -> dict:
    """Student 2: Matching Agent.
    Deterministic weighted scoring of candidate volunteers.
    """
    # TODO: replace with real scoring logic
    return {
        "candidate_volunteers": [],
        "matched_volunteer_ids": [],
        "status": "pending_validation",
    }


def validation_node(state: AgentState) -> dict:
    """Student 3: Safety/Validation Agent.
    Pure rule-based gatekeeper — no LLM calls.
    """
    # TODO: replace with real rule checks
    return {
        "validation_passed": True,
        "validation_notes": "Stub: no rules evaluated yet.",
        "status": "pending_approval",
    }


def coordinator_node(state: AgentState) -> dict:
    """Student 4: Coordinator/Dispatch Agent.
    Builds the dispatch plan and human-readable summary.
    Pauses here for mandatory human approval before any write action.
    """
    dispatch_plan = {
        "incident_id": state.get("incident_id"),
        "assigned_volunteers": state.get("matched_volunteer_ids", []),
    }
    summary = f"Proposed dispatch for incident {state.get('incident_id')}: " \
              f"{len(state.get('matched_volunteer_ids', []))} volunteer(s) assigned."

    # --- Mandatory human-approval pause ---
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
    """Only proceed to the coordinator (and human approval) if validation passed."""
    return "coordinator" if state.get("validation_passed") else END


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

    # MemorySaver enables interrupt()/resume — required for the human-approval pause
    checkpointer = MemorySaver()
    return graph.compile(checkpointer=checkpointer)