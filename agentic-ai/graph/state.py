from typing import TypedDict, Optional, Literal


class AgentState(TypedDict, total=False):
    # --- Input ---
    incident_id: str
    raw_report_text: str

    # --- Triage Agent output ---
    category: Optional[str]
    severity: Optional[str]
    required_skills: Optional[list[str]]
    zone: Optional[str]
    triage_confidence: Optional[float]

    # --- Matching Agent output ---
    candidate_volunteers: Optional[list[dict]]
    matched_volunteer_ids: Optional[list[str]]
    match_scores: Optional[dict[str, float]]

    # --- Safety/Validation Agent output ---
    validation_passed: Optional[bool]
    validation_notes: Optional[str]
    validation_is_stub: Optional[bool]
    validated_volunteer_ids: Optional[list[str]]

    # --- Coordinator/Dispatch Agent output ---
    dispatch_plan: Optional[dict]
    dispatch_summary: Optional[str]
    # Optional Resource API snapshots for this incident; no fetches in the agent.
    incident_resources: Optional[list[dict]]

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
