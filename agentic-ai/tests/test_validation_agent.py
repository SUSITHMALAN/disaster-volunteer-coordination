from datetime import datetime, timezone

from agents.validation_agent import (
    APPROVED,
    NEEDS_REVISION,
    REJECTED,
    check_capacity,
    check_certification,
    check_severity,
    check_time_window,
    validate_candidate,
    validate_candidates,
)


NOW = datetime(2026, 9, 21, 12, 0, tzinfo=timezone.utc)


def make_incident(**overrides):
    incident = {
        "severity": "Medium",
        "requiredSkills": ["first-aid"],
        "estimatedDurationMinutes": 60,
    }
    incident.update(overrides)
    return incident


def make_volunteer(**overrides):
    volunteer = {
        "id": "vol-001",
        "maximumActiveAssignments": 2,
        "activeAssignments": 0,
        "certifications": ["first-aid"],
        "comfortTier": "Medium",
        "availabilityStartUtc": "2026-09-21T10:00:00Z",
        "availabilityEndUtc": "2026-09-21T18:00:00Z",
    }
    volunteer.update(overrides)
    return volunteer


def test_capacity_passes_when_volunteer_has_space():
    result = check_capacity(make_volunteer())

    assert result.verdict == APPROVED
    assert result.rule == "capacity"


def test_capacity_rejects_when_limit_is_reached():
    volunteer = make_volunteer(activeAssignments=2)

    result = check_capacity(volunteer)

    assert result.verdict == REJECTED
    assert result.rule == "capacity"


def test_capacity_needs_revision_when_data_is_missing():
    volunteer = make_volunteer()
    del volunteer["maximumActiveAssignments"]

    result = check_capacity(volunteer)

    assert result.verdict == NEEDS_REVISION
    assert result.rule == "capacity"


def test_certification_passes_when_all_skills_are_available():
    incident = make_incident(requiredSkills=["first-aid"])
    volunteer = make_volunteer(certifications=["first-aid", "rescue"])

    result = check_certification(incident, volunteer)

    assert result.verdict == APPROVED
    assert result.rule == "certification"


def test_certification_rejects_missing_required_skill():
    incident = make_incident(requiredSkills=["first-aid", "rescue"])
    volunteer = make_volunteer(certifications=["first-aid"])

    result = check_certification(incident, volunteer)

    assert result.verdict == REJECTED
    assert result.rule == "certification"
    assert "rescue" in result.message


def test_severity_passes_when_within_comfort_tier():
    incident = make_incident(severity="Medium")
    volunteer = make_volunteer(comfortTier="High")

    result = check_severity(incident, volunteer)

    assert result.verdict == APPROVED
    assert result.rule == "severity"


def test_severity_rejects_when_incident_exceeds_comfort_tier():
    incident = make_incident(severity="Critical")
    volunteer = make_volunteer(comfortTier="High")

    result = check_severity(incident, volunteer)

    assert result.verdict == REJECTED
    assert result.rule == "severity"


def test_severity_needs_revision_when_value_is_invalid():
    incident = make_incident(severity="Unknown")
    volunteer = make_volunteer(comfortTier="High")

    result = check_severity(incident, volunteer)

    assert result.verdict == NEEDS_REVISION
    assert result.rule == "severity"


def test_time_window_passes_when_duration_fits():
    incident = make_incident(estimatedDurationMinutes=120)
    volunteer = make_volunteer(
        availabilityStartUtc="2026-09-21T10:00:00Z",
        availabilityEndUtc="2026-09-21T18:00:00Z",
    )

    result = check_time_window(incident, volunteer, NOW)

    assert result.verdict == APPROVED
    assert result.rule == "time_window"


def test_time_window_rejects_when_duration_does_not_fit():
    incident = make_incident(estimatedDurationMinutes=420)
    volunteer = make_volunteer(
        availabilityStartUtc="2026-09-21T10:00:00Z",
        availabilityEndUtc="2026-09-21T18:00:00Z",
    )

    result = check_time_window(incident, volunteer, NOW)

    assert result.verdict == REJECTED
    assert result.rule == "time_window"


def test_time_window_rejects_when_availability_has_not_started():
    incident = make_incident(estimatedDurationMinutes=60)
    volunteer = make_volunteer(
        availabilityStartUtc="2026-09-21T14:00:00Z",
        availabilityEndUtc="2026-09-21T18:00:00Z",
    )

    result = check_time_window(incident, volunteer, NOW)

    assert result.verdict == REJECTED
    assert result.rule == "time_window"


def test_time_window_needs_revision_when_window_is_missing():
    incident = make_incident(estimatedDurationMinutes=60)
    volunteer = make_volunteer()
    del volunteer["availabilityEndUtc"]

    result = check_time_window(incident, volunteer, NOW)

    assert result.verdict == NEEDS_REVISION
    assert result.rule == "time_window"


def test_validate_candidate_approves_safe_candidate():
    incident = make_incident()
    volunteer = make_volunteer()

    result = validate_candidate(incident, volunteer, NOW)

    assert result.verdict == APPROVED
    assert result.rule == "all"


def test_validate_candidate_stops_at_capacity_failure():
    incident = make_incident()
    volunteer = make_volunteer(activeAssignments=2)

    result = validate_candidate(incident, volunteer, NOW)

    assert result.verdict == REJECTED
    assert result.rule == "capacity"


def test_validate_candidate_runs_checks_in_order():
    incident = make_incident(
        requiredSkills=["first-aid", "rescue"],
        severity="Critical",
    )
    volunteer = make_volunteer(
        activeAssignments=0,
        certifications=["first-aid"],
        comfortTier="High",
    )

    result = validate_candidate(incident, volunteer, NOW)

    assert result.verdict == REJECTED
    assert result.rule == "certification"


def test_validate_candidates_moves_to_next_candidate():
    incident = make_incident()

    rejected_volunteer = make_volunteer(
        id="vol-001",
        activeAssignments=2,
    )

    approved_volunteer = make_volunteer(
        id="vol-002",
    )

    result = validate_candidates(
        incident,
        [rejected_volunteer, approved_volunteer],
        NOW,
    )

    assert result["verdict"] == APPROVED
    assert result["selectedVolunteer"]["id"] == "vol-002"
    assert len(result["results"]) == 2


def test_validate_candidates_rejects_when_all_candidates_fail():
    incident = make_incident()

    volunteer_one = make_volunteer(
        id="vol-001",
        activeAssignments=2,
    )

    volunteer_two = make_volunteer(
        id="vol-002",
        certifications=[],
    )

    result = validate_candidates(
        incident,
        [volunteer_one, volunteer_two],
        NOW,
    )

    assert result["verdict"] == REJECTED
    assert result["selectedVolunteer"] is None


def test_validate_candidates_needs_revision_when_candidate_data_is_incomplete():
    incident = make_incident()

    volunteer = make_volunteer()
    del volunteer["availabilityEndUtc"]

    result = validate_candidates(
        incident,
        [volunteer],
        NOW,
    )

    assert result["verdict"] == NEEDS_REVISION
    assert result["selectedVolunteer"] is None