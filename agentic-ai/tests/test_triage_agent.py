"""
Unit tests for agents/triage_agent.py.

All tests run without an OPENAI_API_KEY so the deterministic keyword-based
fallback path is exercised throughout.  No network calls are made.
"""
import os
import unittest

# Ensure the LLM path is never triggered in tests
os.environ.pop("OPENAI_API_KEY", None)

from agents.triage_agent import run_triage, _fallback_classify


class TestFallbackClassify(unittest.TestCase):

    def test_flood_keyword_detected(self):
        result = _fallback_classify("Heavy flooding near the river bank.")
        self.assertEqual(result.category, "Flood")

    def test_medical_emergency_keyword(self):
        result = _fallback_classify("Person is unconscious and bleeding on the road.")
        self.assertEqual(result.category, "MedicalEmergency")

    def test_power_outage_keyword(self):
        result = _fallback_classify("Total blackout in the area, no electricity.")
        self.assertEqual(result.category, "PowerOutage")

    def test_landslide_keyword(self):
        result = _fallback_classify("Mudslide blocking the main road.")
        self.assertEqual(result.category, "Landslide")

    def test_structural_damage_keyword(self):
        result = _fallback_classify("Building collapsed after the tremor.")
        self.assertEqual(result.category, "StructuralDamage")

    def test_unknown_text_defaults_to_other(self):
        result = _fallback_classify("Something happened in the city.")
        self.assertEqual(result.category, "Other")

    def test_critical_severity_keyword(self):
        result = _fallback_classify("People are trapped and life-threatening situation.")
        self.assertEqual(result.severity, "Critical")

    def test_high_severity_keyword(self):
        result = _fallback_classify("Urgent: fire spreading rapidly.")
        self.assertEqual(result.severity, "High")

    def test_low_severity_keyword(self):
        result = _fallback_classify("Minor water leak, situation under control.")
        self.assertEqual(result.severity, "Low")

    def test_default_severity_is_medium(self):
        result = _fallback_classify("Incident reported in sector 4.")
        self.assertEqual(result.severity, "Medium")

    def test_zone_extraction_from_report(self):
        result = _fallback_classify("Flooding near Colombo district.")
        self.assertEqual(result.zone, "Colombo")

    def test_no_zone_when_absent(self):
        result = _fallback_classify("Flooding is widespread across the area.")
        self.assertIsNone(result.zone)

    def test_confidence_is_low_for_heuristic(self):
        result = _fallback_classify("Flooding near city centre.")
        self.assertLess(result.confidence, 0.5)

    def test_skills_returned_for_flood(self):
        result = _fallback_classify("River overflow flooding the streets.")
        self.assertIn("boat", result.required_skills)
        self.assertIn("swift-water-rescue", result.required_skills)


class TestRunTriage(unittest.TestCase):

    def test_returns_expected_keys(self):
        out = run_triage("Flooding near the bridge.")
        for key in ("category", "severity", "required_skills", "zone", "triage_confidence"):
            self.assertIn(key, out)

    def test_existing_skills_are_merged_not_replaced(self):
        out = run_triage(
            "Flooding near the coast.",
            existing_required_skills=["diving"],
        )
        self.assertIn("diving", out["required_skills"])
        # Flood skills should also be present
        self.assertIn("boat", out["required_skills"])

    def test_skills_deduplicated_when_overlap(self):
        out = run_triage(
            "Flooding near the coast.",
            existing_required_skills=["boat"],   # already in flood hints
        )
        self.assertEqual(out["required_skills"].count("boat"), 1)

    def test_zone_defaults_to_unknown_when_absent(self):
        out = run_triage("Generic incident with no location info.")
        self.assertEqual(out["zone"], "Unknown")

    def test_empty_report_does_not_crash(self):
        out = run_triage("")
        self.assertIn("category", out)

    def test_none_skills_handled_gracefully(self):
        out = run_triage("Flooding near town.", existing_required_skills=None)
        self.assertIsInstance(out["required_skills"], list)


if __name__ == "__main__":
    unittest.main()
