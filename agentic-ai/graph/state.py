from typing import TypedDict, Optional, Literal


class AgentState(TypedDict, total=False):
    # --- Input ---
    incident_id: str
    raw_report_text: str
    estimated_duration_minutes: Optional[int]

    # --- Triage Agent output ---
    category: Optional[str]
    severity: Optional[str]
    required_skills: Optional[list[str]]
    zone: Optional[str]
    triage_confidence: Optional[float]

    # --- Matching Agent output ---
    candidate_volunteers: Optional[list[dict]]
    matched_volunteer_ids: Optional[list[str]]

    # --- Safety/Validation Agent output ---
    validation_verdict: Optional[
        Literal["approved", "rejected", "needs_revision"]
    ]
    validation_notes: Optional[str]
    validated_volunteer_id: Optional[str]

    # --- Coordinator/Dispatch Agent output ---
    dispatch_plan: Optional[dict]
    dispatch_summary: Optional[str]

    # --- Human-in-the-loop control ---
    status: Literal[
        "pending_triage",
        "pending_matching",
        "pending_validation",
        "pending_approval",
        "approved",
        "rejected",
        "dispatched",
    ]
    human_decision: Optional[Literal["approve", "reject", "revise"]]
    human_feedback: Optional[str]