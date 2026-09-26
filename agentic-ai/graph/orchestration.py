import logging

from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt
from langgraph.checkpoint.memory import MemorySaver

from .state import AgentState
from agents.matching_agent import run_matching
from agents.triage_agent import run_triage
from agents.validation_agent import (
    APPROVED,
    validate_candidates,
)
from agents.coordinator_agent import run_coordinator
from tools.dispatch_tools import DispatchBackend, create_dispatch, plan_fingerprint

logger = logging.getLogger(__name__)


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

    candidates = state.get("candidate_volunteers") or []

    incident = {
        "severity": state.get("severity"),
        "requiredSkills": state.get("required_skills") or [],
        "estimatedDurationMinutes": state.get(
            "estimated_duration_minutes"
        ),
    }

    result = validate_candidates(
        incident=incident,
        volunteers=candidates,
    )

    selected_volunteer = result.get("selectedVolunteer")

    if selected_volunteer is not None:
        validated_volunteer_id = selected_volunteer.get("id")

        return {
            "validation_verdict": APPROVED,
            "validation_passed": True,
            "validation_is_stub": False,
            "validation_notes": "Volunteer passed all safety validation checks.",
            "validated_volunteer_id": validated_volunteer_id,
            "validated_volunteer_ids": [validated_volunteer_id],
            "status": "pending_approval",
        }

    results = result.get("results", [])

    if results:
        notes = "; ".join(
            f"{item['volunteer'].get('fullName', 'Unknown volunteer')}: "
            f"{item['message']}"
            for item in results
        )
    else:
        notes = "No volunteer candidates were available for validation."

    return {
        "validation_verdict": result["verdict"],
        "validation_passed": False,
        "validation_is_stub": False,
        "validation_notes": notes,
        "validated_volunteer_id": None,
        "validated_volunteer_ids": [],
        "status": (
            "rejected"
            if result["verdict"] == "rejected"
            else "pending_validation"
        ),
    }


def coordinator_node(state: AgentState) -> dict:
    """Student 4: Coordinator/Dispatch Agent."""
    dispatch_plan = run_coordinator(state)
    summary = dispatch_plan["summary"]
    if not dispatch_plan.get("assignments"):
        return {
            "dispatch_plan": dispatch_plan,
            "dispatch_summary": summary,
            "dispatch_approval": None,
            "dispatch_result": None,
            "human_decision": None,
            "status": "rejected",
        }

    decision = interrupt({
        "dispatch_plan": dispatch_plan,
        "summary": summary,
        "message": "Approve, reject, or request revision for this dispatch plan.",
    })

    if not isinstance(decision, dict):
        decision = {}
    approved = decision.get("decision") == "approve"

    return {
        "dispatch_plan": dispatch_plan,
        "dispatch_summary": summary,
        "human_decision": decision.get("decision"),
        "human_feedback": decision.get("feedback"),
        "dispatch_approval": {
            "decision": "approve",
            "plan_fingerprint": plan_fingerprint(dispatch_plan),
        } if approved else None,
        "dispatch_result": None,
        "status": "approved" if approved else (
            "revision_requested" if decision.get("decision") == "revise" else "rejected"
        ),
    }


def route_after_coordinator(state: AgentState) -> str:
    if state.get("status") == "revision_requested" and state.get("human_decision") == "revise":
        return "coordinator"
    return "dispatch" if state.get("status") == "approved" and state.get("human_decision") == "approve" else END


def dispatch_node(state: AgentState, backend: DispatchBackend | None = None) -> dict:
    if state.get("status") != "approved" or state.get("human_decision") != "approve":
        return {"status": "dispatch_blocked", "dispatch_result": {
            "success": False, "status": "blocked", "message": "Explicit human approval is required.",
            "dispatch_id": None, "idempotency_key": None,
        }}
    validated_ids = state.get("validated_volunteer_ids")
    if validated_ids is None:
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


def _make_checkpointer(db_url: str | None):
    if db_url:
        try:
            from psycopg_pool import ConnectionPool
            from langgraph.checkpoint.postgres import PostgresSaver

            pool = ConnectionPool(
                conninfo=db_url,
                max_size=10,
                open=True,
                kwargs={"autocommit": True},
            )
            checkpointer = PostgresSaver(pool)
            checkpointer.setup()
            logger.info("Checkpointer: PostgreSQL (pool max_size=10)")
            return checkpointer
        except Exception as exc:
            logger.warning(
                "Could not initialise PostgreSQL checkpointer (%s). "
                "Falling back to MemorySaver — workflow state will NOT survive restarts.",
                exc,
            )

    logger.warning(
        "POSTGRES_URL is not set — using in-memory MemorySaver. "
        "Set POSTGRES_URL to enable durable workflow state."
    )
    return MemorySaver()


def build_graph(db_url: str | None = None, dispatch_backend: DispatchBackend | None = None):
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
        "dispatch": "dispatch", "coordinator": "coordinator", END: END,
    })
    graph.add_edge("dispatch", END)

    checkpointer = _make_checkpointer(db_url)
    return graph.compile(checkpointer=checkpointer)
