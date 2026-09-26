import os
import logging

import requests

logger = logging.getLogger(__name__)

API_BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:5030")

SKILL_WEIGHT = 0.5
ZONE_WEIGHT = 0.2
AVAILABILITY_WEIGHT = 0.2
RELIABILITY_WEIGHT = 0.1


def fetch_candidates(required_skills: list[str]) -> list[dict]:
    """Fetch available volunteers from the C# API.

    Returns an empty list (rather than raising) when the backend is unreachable
    or returns a non-2xx status, so the orchestration graph can still complete.
    """
    try:
        params = {"available": "true"}
        response = requests.get(f"{API_BASE_URL}/api/Volunteers", params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as exc:
        logger.warning(
            "matching_agent: could not reach volunteer API at %s — %s. "
            "Continuing with empty candidate list.",
            API_BASE_URL,
            exc,
        )
        return []


def score_candidate(candidate: dict, required_skills: list[str], zone: str | None) -> dict:
    candidate_skills = set(candidate.get("skills") or [])
    required = set(required_skills or [])

    skill_overlap = len(candidate_skills & required) / len(required) if required else 1.0
    zone_match = 1.0 if zone is None else 1.0  # placeholder until volunteers have a zone field
    availability = 1.0 if candidate.get("isAvailable") else 0.0
    reliability = 1.0  # stub — future: derive from completed match history

    score = (
        skill_overlap * SKILL_WEIGHT
        + zone_match * ZONE_WEIGHT
        + availability * AVAILABILITY_WEIGHT
        + reliability * RELIABILITY_WEIGHT
    )

    return {
        "candidate": candidate,
        "score": round(score, 4),
        "breakdown": {
            "skill_overlap": skill_overlap,
            "zone_match": zone_match,
            "availability": availability,
            "reliability": reliability,
        },
    }


def generate_rationale(scored: dict) -> str:
    """Deterministic, template-based rationale for now.
    A future iteration can swap this for an LLM call that explains the score
    in natural language — the LLM would only phrase this text, not affect the score."""
    c = scored["candidate"]
    b = scored["breakdown"]
    matched_skills = ", ".join(c.get("skills") or []) or "no listed skills"
    return (
        f"{c['fullName']} scored {scored['score']:.2f}: "
        f"skill overlap {b['skill_overlap']:.0%}, "
        f"available: {'yes' if b['availability'] else 'no'}. "
        f"Skills on file: {matched_skills}."
    )


def create_match(incident_id: str, volunteer_id: str, score: float, rationale: str) -> dict:
    """Persist a match record via the C# API.

    Returns a stub dict on failure so the caller can still record the volunteer ID
    without crashing the orchestration pipeline.
    """
    payload = {
        "incidentId": incident_id,
        "volunteerId": volunteer_id,
        "score": score,
        "rationale": rationale,
    }
    try:
        response = requests.post(f"{API_BASE_URL}/api/Matches", json=payload, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as exc:
        logger.warning(
            "matching_agent: could not persist match for volunteer %s — %s. "
            "Returning stub result.",
            volunteer_id,
            exc,
        )
        return {"volunteerId": volunteer_id, "score": score, "rationale": rationale}


def run_matching(incident_id: str, required_skills: list[str], zone: str | None, top_n: int = 3) -> dict:
    """Full matching pipeline: fetch candidates, score, rank, persist top N matches."""
    candidates = fetch_candidates(required_skills)

    if not candidates:
        return {"candidate_volunteers": [], "matched_volunteer_ids": []}

    scored = [score_candidate(c, required_skills, zone) for c in candidates]
    scored.sort(key=lambda s: s["score"], reverse=True)
    top_matches = scored[:top_n]

    matched_ids = []
    for m in top_matches:
        rationale = generate_rationale(m)
        result = create_match(incident_id, m["candidate"]["id"], m["score"], rationale)
        matched_ids.append(result["volunteerId"])

    return {
        "candidate_volunteers": [m["candidate"] for m in scored],
        "matched_volunteer_ids": matched_ids,
    }