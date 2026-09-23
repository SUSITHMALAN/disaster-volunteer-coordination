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
            "validation_notes": "Volunteer passed all safety validation checks.",
            "validated_volunteer_id": validated_volunteer_id,
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
        "validation_notes": notes,
        "validated_volunteer_id": None,
        "status": (
            "rejected"
            if result["verdict"] == "rejected"
            else "pending_validation"
        ),
    }


def coordinator_node(state: AgentState) -> dict:
    """Student 4: Coordinator/Dispatch Agent."""

    validated_volunteer_id = state.get("validated_volunteer_id")

    assigned_volunteers = (
        [validated_volunteer_id]
        if validated_volunteer_id
        else []
    )

    dispatch_plan = {
        "incident_id": state.get("incident_id"),
        "assigned_volunteers": assigned_volunteers,
    }
    summary = (
        f"Proposed dispatch for incident "
        f"{state.get('incident_id')}: "
        f"{len(assigned_volunteers)} volunteer(s) assigned."
    )

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
        "status": (
            "approved"
            if decision.get("decision") == "approve"
            else "rejected"
        ),
    }


def route_after_validation(state: AgentState) -> str:
    verdict = state.get("validation_verdict")

    if verdict == APPROVED:
        return "coordinator"

    return END


def _make_checkpointer(db_url: str | None):
    """
    Return a PostgresSaver backed by a connection pool when *db_url* is
    provided, or fall back to an in-memory MemorySaver for local dev / tests.

    PostgresSaver.setup() is idempotent — it creates the checkpoint tables
    if they do not already exist, so it is safe to call on every startup.
    """
    if db_url:
        try:
            from psycopg_pool import ConnectionPool
            from langgraph.checkpoint.postgres import PostgresSaver

            pool = ConnectionPool(
                conninfo=db_url,
                max_size=10,
                open=True,            # open the pool eagerly at startup
                kwargs={"autocommit": True},
            )
            checkpointer = PostgresSaver(pool)
            checkpointer.setup()      # CREATE TABLE IF NOT EXISTS — safe to re-run
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


def build_graph(db_url: str | None = None):
    """
    Compile and return the LangGraph workflow graph.

    Args:
        db_url: A libpq-style connection string, e.g.
                ``"postgresql://user:pass@host:5432/dbname"``.
                When *None* the graph uses an in-memory checkpointer.
    """
    graph = StateGraph(AgentState)

    graph.add_node("triage", triage_node)
    graph.add_node("matching", matching_node)
    graph.add_node("validation", validation_node)
    graph.add_node("coordinator", coordinator_node)

    graph.add_edge(START, "triage")
    graph.add_edge("triage", "matching")
    graph.add_edge("matching", "validation")

    graph.add_conditional_edges(
        "validation",
        route_after_validation,
        {
            "coordinator": "coordinator",
            END: END,
        },
    )

    graph.add_edge("coordinator", END)

    checkpointer = _make_checkpointer(db_url)
    return graph.compile(checkpointer=checkpointer)
