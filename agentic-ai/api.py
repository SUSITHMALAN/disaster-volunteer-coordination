import logging
import os
import uuid
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from langgraph.types import Command
from graph.orchestration import build_graph

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Application lifespan — build the graph once at startup so the PostgreSQL
# connection pool is opened before the first request arrives.
# ---------------------------------------------------------------------------

_graph = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _graph
    db_url = os.environ.get("POSTGRES_URL")
    _graph = build_graph(db_url=db_url)
    logger.info("LangGraph workflow graph initialised.")
    yield
    # Nothing to tear down; the connection pool closes when the process exits.


app = FastAPI(title="DVC Agentic AI Service", lifespan=lifespan)


# ---------------------------------------------------------------------------
# Request / response models
# ---------------------------------------------------------------------------

class StartWorkflowRequest(BaseModel):
    incident_id: str
    raw_report_text: str
    required_skills: list[str] = []


class ApprovalRequest(BaseModel):
    decision: str
    feedback: Optional[str] = None


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.post("/workflows")
def start_workflow(request: StartWorkflowRequest):
    thread_id = str(uuid.uuid4())
    config = {"configurable": {"thread_id": thread_id}}

    initial_state = {
        "incident_id": request.incident_id,
        "raw_report_text": request.raw_report_text,
        "required_skills": request.required_skills,
        "status": "pending_triage",
    }

    result = _graph.invoke(initial_state, config=config)

    return {
        "thread_id": thread_id,
        "state": _serialize(result),
        "awaiting_approval": "__interrupt__" in result,
    }


@app.get("/workflows/{thread_id}")
def get_workflow_status(thread_id: str):
    config = {"configurable": {"thread_id": thread_id}}
    state = _graph.get_state(config)

    if state is None or state.values == {}:
        raise HTTPException(status_code=404, detail="Workflow not found")

    return {
        "thread_id": thread_id,
        "state": _serialize(state.values),
        "awaiting_approval": bool(state.tasks and any(
            t.interrupts for t in state.tasks
        )),
    }


@app.post("/workflows/{thread_id}/approve")
def approve_workflow(thread_id: str, request: ApprovalRequest):
    config = {"configurable": {"thread_id": thread_id}}

    result = _graph.invoke(
        Command(resume={"decision": request.decision, "feedback": request.feedback}),
        config=config,
    )

    return {
        "thread_id": thread_id,
        "state": _serialize(result),
    }


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _serialize(state: dict) -> dict:
    return {k: v for k, v in state.items() if k != "__interrupt__"}
