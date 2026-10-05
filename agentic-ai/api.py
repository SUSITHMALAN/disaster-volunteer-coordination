import logging
import os
import uuid
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

from langgraph.types import Command
from graph.orchestration import build_graph
from tools.auth_context import authorization_header
from tools.http_dispatch_backend import HttpDispatchBackend


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Application lifespan
# ---------------------------------------------------------------------------

_graph = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _graph

    db_url = os.environ.get("POSTGRES_URL")

    dispatch_backend = HttpDispatchBackend()

    _graph = build_graph(
        db_url=db_url,
        dispatch_backend=dispatch_backend,
    )

    logger.info(
        "LangGraph workflow graph initialised."
    )

    yield


app = FastAPI(
    title="DVC Agentic AI Service",
    lifespan=lifespan,
)


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
def start_workflow(
    request: StartWorkflowRequest,
    authorization: str | None = Header(
        default=None,
    ),
):
    thread_id = str(uuid.uuid4())

    config = {
        "configurable": {
            "thread_id": thread_id
        }
    }

    initial_state = {
        "incident_id": request.incident_id,
        "raw_report_text": request.raw_report_text,
        "required_skills": request.required_skills,
        "status": "pending_triage",
    }

    token = authorization_header.set(
        authorization
    )

    try:
        result = _graph.invoke(
            initial_state,
            config=config,
        )
    finally:
        authorization_header.reset(
            token
        )

    return {
        "thread_id": thread_id,
        "state": _serialize(result),
        "awaiting_approval":
            "__interrupt__" in result,
    }


@app.get("/workflows/{thread_id}")
def get_workflow_status(
    thread_id: str,
    authorization: str | None = Header(
        default=None,
    ),
):
    config = {
        "configurable": {
            "thread_id": thread_id
        }
    }

    token = authorization_header.set(
        authorization
    )

    try:
        state = _graph.get_state(
            config
        )
    finally:
        authorization_header.reset(
            token
        )

    if (
        state is None
        or state.values == {}
    ):
        raise HTTPException(
            status_code=404,
            detail="Workflow not found",
        )

    return {
        "thread_id": thread_id,
        "state": _serialize(
            state.values
        ),
        "awaiting_approval": bool(
            state.tasks
            and any(
                task.interrupts
                for task in state.tasks
            )
        ),
    }


@app.post(
    "/workflows/{thread_id}/approve"
)
def approve_workflow(
    thread_id: str,
    request: ApprovalRequest,
    authorization: str | None = Header(
        default=None,
    ),
):
    config = {
        "configurable": {
            "thread_id": thread_id
        }
    }

    token = authorization_header.set(
        authorization
    )

    try:
        result = _graph.invoke(
            Command(
                resume={
                    "decision":
                        request.decision,
                    "feedback":
                        request.feedback,
                }
            ),
            config=config,
        )
    finally:
        authorization_header.reset(
            token
        )

    return {
        "thread_id": thread_id,
        "state": _serialize(result),
    }


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _serialize(
    state: dict,
) -> dict:
    return {
        key: value
        for key, value in state.items()
        if key != "__interrupt__"
    }