import os
import re
from typing import Literal, Optional

from pydantic import BaseModel, Field

CATEGORIES = [
    "Flood",
    "Landslide",
    "PowerOutage",
    "MedicalEmergency",
    "StructuralDamage",
    "Other",
]
SEVERITIES = ["Low", "Medium", "High", "Critical"]

TRIAGE_MODEL = os.environ.get("TRIAGE_MODEL", "gpt-4o-mini")

# ── Fallback heuristics (used when no OPENAI_API_KEY is configured) ──
# Deterministic, same spirit as matching_agent.py's scoring: no external
# calls required, so tests and local dev work without an API key.
CATEGORY_KEYWORDS = {
    "Flood": ["flood", "flooding", "flooded", "water rising", "river overflow"],
    "Landslide": ["landslide", "mudslide", "slope collapse", "soil collapse"],
    "PowerOutage": ["power outage", "no electricity", "blackout", "power cut"],
    "MedicalEmergency": ["injured", "medical", "unconscious", "bleeding", "ambulance", "hospital"],
    "StructuralDamage": ["collapsed", "building damage", "structural", "crack", "unstable structure"],
}

SEVERITY_KEYWORDS = {
    "Critical": ["life-threatening", "trapped", "unconscious", "critical", "dying", "collapsed"],
    "High": ["urgent", "severe", "emergency", "rising fast", "spreading"],
    "Low": ["minor", "small", "under control"],
}

SKILL_HINTS_BY_CATEGORY = {
    "Flood": ["boat", "swift-water-rescue"],
    "Landslide": ["heavy-lifting", "search-and-rescue"],
    "PowerOutage": ["electrical"],
    "MedicalEmergency": ["first-aid", "medical"],
    "StructuralDamage": ["heavy-lifting", "structural-assessment"],
    "Other": [],
}

ZONE_PATTERN = re.compile(r"\bnear\s+([A-Z][a-zA-Z]+(?:\s[A-Z][a-zA-Z]+)*)")


class TriageResult(BaseModel):
    category: Literal[
        "Flood", "Landslide", "PowerOutage", "MedicalEmergency", "StructuralDamage", "Other"
    ]
    severity: Literal["Low", "Medium", "High", "Critical"]
    required_skills: list[str] = Field(
        description="Skills volunteers would need to respond to this incident"
    )
    zone: Optional[str] = Field(
        default=None, description="Area/zone name if mentioned or inferable, else null"
    )
    confidence: float = Field(ge=0.0, le=1.0)


def _fallback_classify(raw_report_text: str) -> TriageResult:
    """Deterministic keyword-based classification, used when no LLM is configured."""
    text = (raw_report_text or "").lower()

    category = "Other"
    for cat, keywords in CATEGORY_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            category = cat
            break

    severity = "Medium"
    for sev, keywords in SEVERITY_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            severity = sev
            break

    zone_match = ZONE_PATTERN.search(raw_report_text or "")
    zone = zone_match.group(1) if zone_match else None

    return TriageResult(
        category=category,
        severity=severity,
        required_skills=SKILL_HINTS_BY_CATEGORY.get(category, []),
        zone=zone,
        confidence=0.4,  # low confidence — this is a heuristic, not a model judgement
    )


def _llm_classify(raw_report_text: str) -> TriageResult:
    from langchain_openai import ChatOpenAI

    llm = ChatOpenAI(model=TRIAGE_MODEL, temperature=0)
    structured_llm = llm.with_structured_output(TriageResult)

    prompt = (
        "You are the triage agent for a disaster-response coordination system. "
        "Read the raw incident report below and classify it.\n\n"
        f"Categories: {', '.join(CATEGORIES)}\n"
        f"Severities: {', '.join(SEVERITIES)} "
        "(Critical = life-threatening/trapped people, High = urgent and worsening, "
        "Medium = needs a response but stable, Low = minor).\n\n"
        "List the practical skills volunteers would need (e.g. first-aid, boat, "
        "heavy-lifting, electrical, search-and-rescue). "
        "If a zone/area name is mentioned, extract it; otherwise leave zone null. "
        "Set confidence between 0 and 1 based on how much detail the report gives you.\n\n"
        f"Report:\n{raw_report_text}"
    )

    return structured_llm.invoke(prompt)


def run_triage(raw_report_text: str, existing_required_skills: list[str] | None = None) -> dict:
    """Classify a raw incident report into structured triage fields.

    Uses an LLM when OPENAI_API_KEY is configured; otherwise falls back to a
    deterministic keyword-based classifier so this works offline / in tests
    without requiring an API key.
    """
    if os.environ.get("OPENAI_API_KEY"):
        try:
            result = _llm_classify(raw_report_text)
        except Exception:
            # If the LLM call fails for any reason (network, quota, bad response),
            # don't crash the pipeline — fall back to the heuristic classifier.
            result = _fallback_classify(raw_report_text)
    else:
        result = _fallback_classify(raw_report_text)

    # Union with any skills already supplied when the incident was created,
    # rather than discarding what the requester/coordinator already specified.
    merged_skills = list(
        dict.fromkeys((existing_required_skills or []) + result.required_skills)
    )

    return {
        "category": result.category,
        "severity": result.severity,
        "required_skills": merged_skills,
        "zone": result.zone or "Unknown",
        "triage_confidence": result.confidence,
    }
