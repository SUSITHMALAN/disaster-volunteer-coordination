"""
Unit tests for agents/matching_agent.py.

All HTTP calls are mocked with unittest.mock so no running backend is needed.
"""
import unittest
from unittest.mock import MagicMock, patch

from agents.matching_agent import (
    score_candidate,
    generate_rationale,
    fetch_candidates,
    create_match,
    run_matching,
)


# ── Fixtures ─────────────────────────────────────────────────────────────────

def make_volunteer(
    id="vol-1",
    full_name="Alice Smith",
    skills=None,
    is_available=True,
):
    if skills is None:
        skills = ["first-aid", "boat"]
    return {
        "id": id,
        "fullName": full_name,
        "skills": skills,
        "isAvailable": is_available,
    }


# ── score_candidate ───────────────────────────────────────────────────────────

class TestScoreCandidate(unittest.TestCase):

    def test_perfect_skill_match_gives_max_score(self):
        vol = make_volunteer(skills=["first-aid", "boat"])
        scored = score_candidate(vol, ["first-aid", "boat"], zone=None)
        self.assertAlmostEqual(scored["score"], 1.0, places=2)

    def test_zero_skill_match_lowers_score(self):
        vol = make_volunteer(skills=["electrical"])
        scored = score_candidate(vol, ["first-aid", "boat"], zone=None)
        self.assertLessEqual(scored["score"], 0.5)

    def test_unavailable_volunteer_gets_zero_availability(self):
        vol = make_volunteer(is_available=False)
        scored = score_candidate(vol, ["first-aid"], zone=None)
        self.assertEqual(scored["breakdown"]["availability"], 0.0)

    def test_no_required_skills_gives_full_skill_overlap(self):
        vol = make_volunteer(skills=["first-aid"])
        scored = score_candidate(vol, [], zone=None)
        self.assertEqual(scored["breakdown"]["skill_overlap"], 1.0)

    def test_score_breakdown_keys_present(self):
        vol = make_volunteer()
        scored = score_candidate(vol, ["first-aid"], zone=None)
        for key in ("skill_overlap", "zone_match", "availability", "reliability"):
            self.assertIn(key, scored["breakdown"])

    def test_score_is_rounded_to_4_decimal_places(self):
        vol = make_volunteer()
        scored = score_candidate(vol, ["first-aid"], zone=None)
        self.assertEqual(scored["score"], round(scored["score"], 4))


class TestConfigurableWeights(unittest.TestCase):

    def test_custom_weights_override_scoring(self):
        vol = make_volunteer(skills=["first-aid"])
        custom_weights = {"skill": 0.8, "zone": 0.1, "availability": 0.05, "reliability": 0.05}
        scored = score_candidate(vol, ["first-aid"], zone=None, weights=custom_weights)
        self.assertAlmostEqual(scored["score"], 1.0, places=2)

    @patch.dict("os.environ", {"SKILL_WEIGHT": "0.7", "ZONE_WEIGHT": "0.1", "AVAILABILITY_WEIGHT": "0.1", "RELIABILITY_WEIGHT": "0.1"})
    def test_environment_variables_override_defaults(self):
        from agents.matching_agent import get_matching_weights
        weights = get_matching_weights()
        self.assertEqual(weights["skill"], 0.7)
        self.assertEqual(weights["zone"], 0.1)


# ── generate_rationale ────────────────────────────────────────────────────────

class TestGenerateRationale(unittest.TestCase):

    def test_rationale_contains_volunteer_name(self):
        vol = make_volunteer(full_name="Bob Jones")
        scored = score_candidate(vol, ["boat"], zone=None)
        rationale = generate_rationale(scored)
        self.assertIn("Bob Jones", rationale)

    def test_rationale_contains_score(self):
        vol = make_volunteer()
        scored = score_candidate(vol, ["first-aid"], zone=None)
        rationale = generate_rationale(scored)
        self.assertIn(str(round(scored["score"], 2)), rationale)

    def test_rationale_mentions_skills_on_file(self):
        vol = make_volunteer(skills=["diving", "first-aid"])
        scored = score_candidate(vol, ["first-aid"], zone=None)
        rationale = generate_rationale(scored)
        self.assertIn("diving", rationale)

    def test_no_skills_shows_placeholder(self):
        vol = make_volunteer(skills=[])
        scored = score_candidate(vol, ["first-aid"], zone=None)
        rationale = generate_rationale(scored)
        self.assertIn("no listed skills", rationale)


# ── fetch_candidates (mocked HTTP) ───────────────────────────────────────────

class TestFetchCandidates(unittest.TestCase):

    @patch("agents.matching_agent.requests.get")
    def test_returns_list_on_success(self, mock_get):
        mock_response = MagicMock()
        mock_response.json.return_value = [make_volunteer()]
        mock_response.raise_for_status.return_value = None
        mock_get.return_value = mock_response

        result = fetch_candidates(["first-aid"])
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["id"], "vol-1")

    @patch("agents.matching_agent.requests.get")
    def test_returns_empty_list_on_connection_error(self, mock_get):
        import requests
        mock_get.side_effect = requests.exceptions.RequestException("Connection refused")
        result = fetch_candidates(["first-aid"])
        self.assertEqual(result, [])

    @patch("agents.matching_agent.requests.get")
    def test_returns_empty_list_on_non_2xx(self, mock_get):
        import requests as req
        mock_get.side_effect = req.exceptions.HTTPError("503")
        result = fetch_candidates([])
        self.assertEqual(result, [])


# ── create_match (mocked HTTP) ────────────────────────────────────────────────

class TestCreateMatch(unittest.TestCase):

    @patch("agents.matching_agent.requests.post")
    def test_returns_api_response_on_success(self, mock_post):
        mock_response = MagicMock()
        mock_response.json.return_value = {"volunteerId": "vol-1", "score": 0.9}
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        result = create_match("inc-1", "vol-1", 0.9, "Good match.")
        self.assertEqual(result["volunteerId"], "vol-1")

    @patch("agents.matching_agent.requests.post")
    def test_returns_stub_dict_on_failure(self, mock_post):
        import requests
        mock_post.side_effect = requests.exceptions.RequestException("timeout")
        result = create_match("inc-1", "vol-1", 0.85, "Fallback.")
        self.assertEqual(result["volunteerId"], "vol-1")
        self.assertAlmostEqual(result["score"], 0.85)


# ── run_matching (full pipeline, mocked HTTP) ────────────────────────────────

class TestRunMatching(unittest.TestCase):

    @patch("agents.matching_agent.fetch_candidates", return_value=[])
    def test_empty_candidates_returns_empty_lists(self, _):
        result = run_matching("inc-1", ["first-aid"], zone=None)
        self.assertEqual(result, {"candidate_volunteers": [], "matched_volunteer_ids": []})

    @patch("agents.matching_agent.create_match")
    @patch("agents.matching_agent.fetch_candidates")
    def test_returns_all_candidates_by_default(self, mock_fetch, mock_create):
        volunteers = [
            make_volunteer(id=f"vol-{i}", skills=["first-aid"]) for i in range(5)
        ]
        mock_fetch.return_value = volunteers
        mock_create.side_effect = lambda inc, vid, sc, rat: {"volunteerId": vid}

        result = run_matching("inc-1", ["first-aid"], zone=None)

        self.assertEqual(len(result["matched_volunteer_ids"]), 5)
        self.assertEqual(len(result["candidate_volunteers"]), 5)

    @patch("agents.matching_agent.create_match")
    @patch("agents.matching_agent.fetch_candidates")
    def test_explicit_top_n_still_limits_persisted_matches(self, mock_fetch, mock_create):
        volunteers = [
            make_volunteer(id=f"vol-{i}", skills=["first-aid"]) for i in range(5)
        ]
        mock_fetch.return_value = volunteers
        mock_create.side_effect = lambda inc, vid, sc, rat: {"volunteerId": vid}

        result = run_matching("inc-1", ["first-aid"], zone=None, top_n=3)

        self.assertEqual(len(result["matched_volunteer_ids"]), 3)
        self.assertEqual(len(result["candidate_volunteers"]), 5)

class TestMatchingAgentEdgeCases(unittest.TestCase):

    def test_tie_breaking_preserves_candidate_order(self):
        v1 = make_volunteer(id="vol-1", full_name="Alpha", skills=["first-aid"])
        v2 = make_volunteer(id="vol-2", full_name="Beta", skills=["first-aid"])
        s1 = score_candidate(v1, ["first-aid"], zone=None)
        s2 = score_candidate(v2, ["first-aid"], zone=None)
        self.assertEqual(s1["score"], s2["score"])

    def test_zero_skill_overlap_and_unavailable_produces_lowest_score(self):
        v = make_volunteer(id="vol-3", skills=["gardening"], is_available=False)
        scored = score_candidate(v, ["first-aid", "boat"], zone=None)
        self.assertAlmostEqual(scored["score"], 0.3, places=2)

    def test_rationale_fallback_for_empty_skills(self):
        v = make_volunteer(skills=[])
        scored = score_candidate(v, ["first-aid"], zone=None)
        rationale = generate_rationale(scored)
        self.assertIn("no listed skills", rationale)

    @patch("agents.matching_agent.requests.post")
    def test_create_match_llm_rationale_fallback_on_network_error(self, mock_post):
        import requests
        mock_post.side_effect = requests.exceptions.RequestException("Backend down")
        res = create_match("inc-123", "vol-456", 0.75, "Fallback explanation")
        self.assertEqual(res["volunteerId"], "vol-456")
        self.assertEqual(res["rationale"], "Fallback explanation")


if __name__ == "__main__":
    unittest.main()
