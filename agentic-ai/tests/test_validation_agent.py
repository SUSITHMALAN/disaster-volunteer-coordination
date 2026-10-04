import unittest
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


class TestValidationAgent(unittest.TestCase):

    def setUp(self):
        self.now = datetime(
            2026,
            10,
            4,
            5,
            0,
            0,
            tzinfo=timezone.utc,
        )

        self.incident = {
            "requiredSkills": ["first-aid"],
            "requiredCertifications": [],
            "severity": "Medium",
            "estimatedDurationMinutes": 60,
        }

        self.volunteer = {
            "id": "volunteer-1",
            "fullName": "Test Volunteer",
            "skills": ["first-aid", "driving"],
            "certifications": ["Standard First Aid"],
            "activeAssignments": 0,
            "maximumActiveAssignments": 2,
            "comfortTier": "Medium",
            "availabilityStartUtc": "2026-10-04T04:00:00Z",
            "availabilityEndUtc": "2026-10-04T08:00:00Z",
        }

    # ------------------------------------------------------------------
    # Capacity tests
    # ------------------------------------------------------------------

    def test_capacity_passes_when_volunteer_has_space(self):
        result = check_capacity(self.volunteer)

        self.assertEqual(result.verdict, APPROVED)
        self.assertEqual(result.rule, "capacity")

    def test_capacity_rejects_when_at_limit(self):
        volunteer = {
            **self.volunteer,
            "activeAssignments": 2,
            "maximumActiveAssignments": 2,
        }

        result = check_capacity(volunteer)

        self.assertEqual(result.verdict, REJECTED)
        self.assertEqual(result.rule, "capacity")

    def test_capacity_needs_revision_when_data_missing(self):
        volunteer = {
            **self.volunteer,
            "activeAssignments": None,
        }

        result = check_capacity(volunteer)

        self.assertEqual(result.verdict, NEEDS_REVISION)

    # ------------------------------------------------------------------
    # Skills and certification tests
    # ------------------------------------------------------------------

    def test_skill_check_passes_when_required_skill_exists(self):
        result = check_certification(
            self.incident,
            self.volunteer,
        )

        self.assertEqual(result.verdict, APPROVED)

    def test_skill_check_rejects_missing_skill(self):
        incident = {
            **self.incident,
            "requiredSkills": [
                "first-aid",
                "boat",
                "swift-water-rescue",
            ],
        }

        result = check_certification(
            incident,
            self.volunteer,
        )

        self.assertEqual(result.verdict, REJECTED)
        self.assertEqual(result.rule, "certification")
        self.assertIn("boat", result.message)
        self.assertIn("swift-water-rescue", result.message)

    def test_skill_check_is_case_insensitive(self):
        incident = {
            **self.incident,
            "requiredSkills": ["FIRST-AID"],
        }

        volunteer = {
            **self.volunteer,
            "skills": ["First-Aid"],
        }

        result = check_certification(
            incident,
            volunteer,
        )

        self.assertEqual(result.verdict, APPROVED)

    def test_certification_check_passes_when_required_certification_exists(self):
        incident = {
            **self.incident,
            "requiredCertifications": ["Standard First Aid"],
        }

        result = check_certification(
            incident,
            self.volunteer,
        )

        self.assertEqual(result.verdict, APPROVED)

    def test_certification_check_rejects_missing_certification(self):
        incident = {
            **self.incident,
            "requiredCertifications": ["Swift Water Rescue"],
        }

        result = check_certification(
            incident,
            self.volunteer,
        )

        self.assertEqual(result.verdict, REJECTED)
        self.assertIn("swift water rescue", result.message.lower())

    # ------------------------------------------------------------------
    # Severity tests
    # ------------------------------------------------------------------

    def test_severity_passes_when_within_comfort_tier(self):
        result = check_severity(
            self.incident,
            self.volunteer,
        )

        self.assertEqual(result.verdict, APPROVED)

    def test_severity_rejects_when_above_comfort_tier(self):
        incident = {
            **self.incident,
            "severity": "High",
        }

        volunteer = {
            **self.volunteer,
            "comfortTier": "Medium",
        }

        result = check_severity(
            incident,
            volunteer,
        )

        self.assertEqual(result.verdict, REJECTED)
        self.assertEqual(result.rule, "severity")

    def test_severity_needs_revision_when_invalid(self):
        incident = {
            **self.incident,
            "severity": "Unknown",
        }

        result = check_severity(
            incident,
            self.volunteer,
        )

        self.assertEqual(result.verdict, NEEDS_REVISION)

    # ------------------------------------------------------------------
    # Time-window tests
    # ------------------------------------------------------------------

    def test_time_window_passes_when_duration_fits(self):
        result = check_time_window(
            self.incident,
            self.volunteer,
            self.now,
        )

        self.assertEqual(result.verdict, APPROVED)

    def test_time_window_rejects_when_duration_exceeds_availability(self):
        incident = {
            **self.incident,
            "estimatedDurationMinutes": 240,
        }

        volunteer = {
            **self.volunteer,
            "availabilityEndUtc": "2026-10-04T06:00:00Z",
        }

        result = check_time_window(
            incident,
            volunteer,
            self.now,
        )

        self.assertEqual(result.verdict, REJECTED)
        self.assertEqual(result.rule, "time_window")

    def test_time_window_needs_revision_when_duration_missing(self):
        incident = {
            **self.incident,
            "estimatedDurationMinutes": None,
        }

        result = check_time_window(
            incident,
            self.volunteer,
            self.now,
        )

        self.assertEqual(result.verdict, NEEDS_REVISION)

    def test_time_window_needs_revision_when_availability_missing(self):
        volunteer = {
            **self.volunteer,
            "availabilityStartUtc": None,
            "availabilityEndUtc": None,
        }

        result = check_time_window(
            self.incident,
            volunteer,
            self.now,
        )

        self.assertEqual(result.verdict, NEEDS_REVISION)

    # ------------------------------------------------------------------
    # Full validation tests
    # ------------------------------------------------------------------

    def test_candidate_passes_all_validation_checks(self):
        result = validate_candidate(
            self.incident,
            self.volunteer,
            self.now,
        )

        self.assertEqual(result.verdict, APPROVED)
        self.assertEqual(result.rule, "all")

    def test_validation_fails_fast_on_capacity(self):
        volunteer = {
            **self.volunteer,
            "activeAssignments": 2,
            "maximumActiveAssignments": 2,
        }

        result = validate_candidate(
            self.incident,
            volunteer,
            self.now,
        )

        self.assertEqual(result.verdict, REJECTED)
        self.assertEqual(result.rule, "capacity")

    def test_validation_moves_to_next_candidate(self):
        first_volunteer = {
            **self.volunteer,
            "id": "volunteer-1",
            "skills": ["driving"],
        }

        second_volunteer = {
            **self.volunteer,
            "id": "volunteer-2",
        }

        result = validate_candidates(
            self.incident,
            [
                first_volunteer,
                second_volunteer,
            ],
            self.now,
        )

        self.assertEqual(result["verdict"], APPROVED)
        self.assertEqual(
            result["selectedVolunteer"]["id"],
            "volunteer-2",
        )

        self.assertEqual(len(result["results"]), 2)

        self.assertEqual(
            result["results"][0]["verdict"],
            REJECTED,
        )

        self.assertEqual(
            result["results"][1]["verdict"],
            APPROVED,
        )

    def test_validation_rejects_when_all_candidates_fail(self):
        first_volunteer = {
            **self.volunteer,
            "id": "volunteer-1",
            "skills": ["driving"],
        }

        second_volunteer = {
            **self.volunteer,
            "id": "volunteer-2",
            "skills": ["logistics"],
        }

        result = validate_candidates(
            self.incident,
            [
                first_volunteer,
                second_volunteer,
            ],
            self.now,
        )

        self.assertEqual(result["verdict"], REJECTED)
        self.assertIsNone(result["selectedVolunteer"])

    def test_validation_returns_needs_revision_when_candidate_data_incomplete(self):
        volunteer = {
            **self.volunteer,
            "availabilityStartUtc": None,
            "availabilityEndUtc": None,
        }

        result = validate_candidates(
            self.incident,
            [volunteer],
            self.now,
        )

        self.assertEqual(
            result["verdict"],
            NEEDS_REVISION,
        )

        self.assertIsNone(
            result["selectedVolunteer"],
        )


if __name__ == "__main__":
    unittest.main()