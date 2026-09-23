"""Deterministic dispatch proposals. No HTTP, LLM, approval or persistence effects."""

from decimal import Decimal, InvalidOperation
from math import isfinite
from typing import TypedDict

from graph.state import AgentState


class VolunteerAssignment(TypedDict):
    order: int
    volunteer_id: str
    volunteer_name: str | None
    match_score: float | None
    justification: str


class DispatchProposal(TypedDict):
    incident_id: str
    assigned_volunteers: list[str]
    assignments: list[VolunteerAssignment]
    ordering_reason: str
    severity: str | None
    zone: str | None
    resource_requirements: list[dict]
    warnings: list[str]
    summary: str
    human_feedback: str | None


def _known_text(value: object) -> str | None:
    if not isinstance(value, str) or not value.strip() or value.strip().lower() == "unknown":
        return None
    return value.strip()


def _resources(state: AgentState, warnings: list[str]) -> list[dict]:
    """Normalize supplied Resource API snapshots; never fetch or reserve stock."""
    records = state.get("incident_resources")
    if records is None:
        warnings.append("Resource information is unavailable; supply sufficiency is unknown.")
        return []
    if not records:
        warnings.append("No resource records supplied; this does not establish that no supplies are needed.")
    result = []
    for record in records:
        if record.get("incidentId") != state["incident_id"]:
            warnings.append("Ignored resource data without a matching incident ID.")
            continue
        try:
            values = [Decimal(str(record[key])) for key in
                      ("availableQuantity", "neededQuantity", "usedQuantity")]
            if any(not value.is_finite() or value < 0 for value in values):
                raise ValueError("Invalid quantity")
            available, needed, used = values
            if used > available:
                raise ValueError("Usage exceeds allocation")
            name = _known_text(record.get("resourceName"))
            unit = _known_text(record.get("unit"))
            if name is None or unit is None:
                raise ValueError("Missing resource name or unit")
        except (KeyError, InvalidOperation, ValueError):
            warnings.append("Ignored incomplete or invalid resource quantities; resource information is partial.")
            continue
        shortage = max(needed - available, Decimal(0))
        result.append({
            "resource_name": name,
            "category": record.get("category"),
            "unit": unit,
            # Decimal strings preserve quantities exactly and remain JSON serializable.
            "available_quantity": str(available),
            "needed_quantity": str(needed),
            "used_quantity": str(used),
            "remaining_quantity": str(available - used),
            "shortage_quantity": str(shortage),
        })
        if shortage > 0:
            warnings.append(f"Resource shortage: {name}, {shortage} {unit}.")
    return result


def run_coordinator(state: AgentState) -> DispatchProposal:
    """Build a proposal from trusted graph state without modifying it.

    A real validation_passed=True applies to the matched set. If Safety supplies
    validated_volunteer_ids, only that intersection is eligible. match_scores
    and incident_resources are optional upstream snapshots, never invented here.
    Severity is incident urgency, not an invented per-volunteer suitability score.
    """
    if state.get("validation_passed") is not True or state.get("validation_is_stub"):
        raise ValueError("Completed Safety/Validation approval is required before proposing dispatch.")
    incident_id = _known_text(state.get("incident_id"))
    if incident_id is None:
        raise ValueError("An incident ID is required.")

    warnings: list[str] = []
    matched = list(dict.fromkeys(state.get("matched_volunteer_ids") or []))
    if any(not isinstance(value, str) or not value.strip() for value in matched):
        raise ValueError("Matched volunteer IDs must be nonempty strings.")
    validated = state.get("validated_volunteer_ids")
    eligible = matched if validated is None else [value for value in matched if value in validated]
    if validated is None:
        warnings.append("Using the overall Safety result for the matched set; per-volunteer validation was not supplied.")
    elif len(eligible) != len(matched):
        warnings.append("Matches outside Safety's validated volunteer set were excluded.")

    candidates = {c["id"]: c for c in (state.get("candidate_volunteers") or []) if c.get("id")}
    selected = []
    for volunteer_id in eligible:
        candidate = candidates.get(volunteer_id, {})
        if candidate.get("isAvailable") is False:
            warnings.append(f"Excluded unavailable volunteer {volunteer_id}; updated Safety review may be needed.")
            continue
        if candidate.get("isAvailable") is not True:
            warnings.append(f"Current availability is unknown for volunteer {volunteer_id}.")
        selected.append(volunteer_id)

    severity = state.get("severity")
    if severity not in ("Low", "Medium", "High", "Critical"):
        severity = None
        warnings.append("Incident severity is unavailable.")
    zone = _known_text(state.get("zone"))
    if zone is None:
        warnings.append("Incident zone is unavailable.")
    if any(_known_text(candidates.get(value, {}).get("zone")) is None for value in selected):
        warnings.append("Volunteer location data is incomplete; no travel time or proximity is inferred.")

    raw_scores = state.get("match_scores") or {}
    scores = {}
    for volunteer_id in selected:
        score = raw_scores.get(volunteer_id)
        if isinstance(score, (int, float)) and not isinstance(score, bool) and isfinite(score) and 0 <= score <= 1:
            scores[volunteer_id] = float(score)
    use_scores = bool(selected) and len(scores) == len(selected)
    # Use zone only when every selected candidate has comparable recorded data.
    use_zone = zone is not None and all(
        _known_text(candidates.get(value, {}).get("zone")) is not None for value in selected)
    if use_scores:
        selected.sort(key=lambda value: (
            -scores[value],
            0 if use_zone and candidates[value]["zone"].strip().casefold() == zone.casefold() else 1,
            value,
        ))
        ordering_reason = "Recorded match score descending; " + (
            "same-zone preference for equal scores; " if use_zone else ""
        ) + "volunteer ID as the final tie-breaker."
    else:
        ordering_reason = "Preserved Matching Agent order because complete reliable scores were not supplied."
        if selected:
            warnings.append("Match scores are missing or invalid; no replacement scores were invented.")

    assignments: list[VolunteerAssignment] = []
    for order, volunteer_id in enumerate(selected, 1):
        assignments.append({
            "order": order,
            "volunteer_id": volunteer_id,
            "volunteer_name": _known_text(candidates.get(volunteer_id, {}).get("fullName")),
            "match_score": scores.get(volunteer_id),
            "justification": f"Position {order} within the Safety-approved matched set. " + ordering_reason,
        })
    resources = _resources(state, warnings)
    if not assignments:
        warnings.append("No eligible validated volunteers are available; there is no dispatch to approve.")
    feedback = _known_text(state.get("human_feedback"))
    if feedback:
        warnings.append("Human feedback is retained for review; free text does not override Safety or ranking rules.")
    summary = (
        f"Dispatch proposal for incident {incident_id}: {len(assignments)} volunteer(s) proposed. "
        f"Severity: {severity or 'Unknown'}. Zone: {zone or 'Unknown'}. {ordering_reason} "
        + ("Order: " + ", ".join(item["volunteer_name"] or item["volunteer_id"] for item in assignments) + ". "
           if assignments else "")
        + "Mandatory human approval is required; no assignments have been persisted."
    )
    return {
        "incident_id": incident_id,
        # Preserve the original plan's ID list for existing consumers.
        "assigned_volunteers": selected,
        "assignments": assignments,
        "ordering_reason": ordering_reason,
        "severity": severity,
        "zone": zone,
        "resource_requirements": resources,
        "warnings": warnings,
        "summary": summary,
        "human_feedback": feedback,
    }
