from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any


APPROVED = "approved"
REJECTED = "rejected"
NEEDS_REVISION = "needs_revision"


@dataclass
class ValidationResult:
    verdict: str
    rule: str
    message: str


def check_capacity(volunteer: dict[str, Any]) -> ValidationResult:
    """Check whether the volunteer has capacity for another assignment."""
    active_assignments = volunteer.get("activeAssignments")
    maximum_assignments = volunteer.get("maximumActiveAssignments")

    if active_assignments is None or maximum_assignments is None:
        return ValidationResult(
            NEEDS_REVISION,
            "capacity",
            "Capacity information is missing.",
        )

    if active_assignments >= maximum_assignments:
        return ValidationResult(
            REJECTED,
            "capacity",
            "Volunteer has reached the maximum number of active assignments.",
        )

    return ValidationResult(
        APPROVED,
        "capacity",
        "Volunteer has available assignment capacity.",
    )


def check_certification(
    incident: dict[str, Any],
    volunteer: dict[str, Any],
) -> ValidationResult:
    """Check that the volunteer has all certifications required by the incident."""
    required_skills = {
        str(skill).strip().lower()
        for skill in (incident.get("requiredSkills") or [])
        if str(skill).strip()
    }

    certifications = {
        str(certification).strip().lower()
        for certification in (volunteer.get("certifications") or [])
        if str(certification).strip()
    }

    missing = sorted(required_skills - certifications)

    if missing:
        return ValidationResult(
            REJECTED,
            "certification",
            f"Volunteer is missing required certifications: {', '.join(missing)}.",
        )

    return ValidationResult(
        APPROVED,
        "certification",
        "Volunteer has all required certifications.",
    )


def check_severity(
    incident: dict[str, Any],
    volunteer: dict[str, Any],
) -> ValidationResult:
    """Check that incident severity does not exceed the volunteer comfort tier."""
    severity_levels = {
        "low": 1,
        "medium": 2,
        "high": 3,
        "critical": 4,
    }

    severity = str(incident.get("severity", "")).strip().lower()
    comfort_tier = str(volunteer.get("comfortTier", "")).strip().lower()

    if severity not in severity_levels or comfort_tier not in severity_levels:
        return ValidationResult(
            NEEDS_REVISION,
            "severity",
            "Incident severity or volunteer comfort tier is missing or invalid.",
        )

    if severity_levels[severity] > severity_levels[comfort_tier]:
        return ValidationResult(
            REJECTED,
            "severity",
            "Incident severity exceeds the volunteer's comfort tier.",
        )

    return ValidationResult(
        APPROVED,
        "severity",
        "Incident severity is within the volunteer's comfort tier.",
    )


def check_time_window(
    incident: dict[str, Any],
    volunteer: dict[str, Any],
    now: datetime | None = None,
) -> ValidationResult:
    """Check whether the volunteer's availability covers the estimated duration."""
    start_value = volunteer.get("availabilityStartUtc")
    end_value = volunteer.get("availabilityEndUtc")
    duration = incident.get("estimatedDurationMinutes")

    if duration is None or duration <= 0:
        return ValidationResult(
            NEEDS_REVISION,
            "time_window",
            "Estimated duration is missing or invalid.",
        )

    if start_value is None or end_value is None:
        return ValidationResult(
            NEEDS_REVISION,
            "time_window",
            "Volunteer availability window is incomplete.",
        )

    try:
        availability_start = _parse_datetime(start_value)
        availability_end = _parse_datetime(end_value)
    except (TypeError, ValueError):
        return ValidationResult(
            NEEDS_REVISION,
            "time_window",
            "Volunteer availability window contains an invalid date/time.",
        )

    current_time = now or datetime.now(timezone.utc)
    current_time = _ensure_utc(current_time)

    estimated_end = current_time + timedelta_minutes(duration)

    if current_time < availability_start:
        return ValidationResult(
            REJECTED,
            "time_window",
            "Volunteer availability has not started yet.",
        )

    if estimated_end > availability_end:
        return ValidationResult(
            REJECTED,
            "time_window",
            "Volunteer availability does not cover the estimated task duration.",
        )

    return ValidationResult(
        APPROVED,
        "time_window",
        "Volunteer availability covers the estimated task duration.",
    )


def validate_candidate(
    incident: dict[str, Any],
    volunteer: dict[str, Any],
    now: datetime | None = None,
) -> ValidationResult:
    """
    Run safety checks in the required order.

    The first failed safety rule determines the verdict.
    """
    checks = [
        lambda: check_capacity(volunteer),
        lambda: check_certification(incident, volunteer),
        lambda: check_severity(incident, volunteer),
        lambda: check_time_window(incident, volunteer, now),
    ]

    for check in checks:
        result = check()

        if result.verdict != APPROVED:
            return result

    return ValidationResult(
        APPROVED,
        "all",
        "Volunteer passed all safety validation checks.",
    )


def validate_candidates(
    incident: dict[str, Any],
    volunteers: list[dict[str, Any]],
    now: datetime | None = None,
) -> dict[str, Any]:
    """
    Validate candidates in order and return the first approved candidate.

    Rejected candidates are skipped so the next candidate can be evaluated.
    """
    results = []

    for volunteer in volunteers:
        result = validate_candidate(incident, volunteer, now)

        results.append(
            {
                "volunteer": volunteer,
                "verdict": result.verdict,
                "rule": result.rule,
                "message": result.message,
            }
        )

        if result.verdict == APPROVED:
            return {
                "verdict": APPROVED,
                "selectedVolunteer": volunteer,
                "results": results,
            }

    if any(result["verdict"] == NEEDS_REVISION for result in results):
        final_verdict = NEEDS_REVISION
    else:
        final_verdict = REJECTED

    return {
        "verdict": final_verdict,
        "selectedVolunteer": None,
        "results": results,
    }


def _parse_datetime(value: Any) -> datetime:
    """Parse an ISO-8601 datetime and normalize it to UTC."""
    if isinstance(value, datetime):
        return _ensure_utc(value)

    if not isinstance(value, str):
        raise ValueError("Invalid datetime value.")

    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return _ensure_utc(parsed)


def _ensure_utc(value: datetime) -> datetime:
    """Return a timezone-aware UTC datetime."""
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)

    return value.astimezone(timezone.utc)


def timedelta_minutes(minutes: int):
    """Create a timedelta without exposing datetime arithmetic to callers."""
    from datetime import timedelta

    return timedelta(minutes=minutes)