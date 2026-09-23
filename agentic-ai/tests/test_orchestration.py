from langgraph.types import Command

import graph.orchestration as orchestration
from graph.orchestration import build_graph


def test_graph_pauses_for_approval(monkeypatch):
    def mock_run_triage(raw_report_text, existing_required_skills=None):
        return {
            "category": "Flood",
            "severity": "Medium",
            "required_skills": existing_required_skills or ["first-aid"],
            "zone": "Colombo",
            "triage_confidence": 0.95,
        }

    def mock_run_matching(incident_id, required_skills, zone=None):
        return {
            "candidate_volunteers": [
                {
                    "id": "volunteer-1",
                    "fullName": "Test Volunteer",
                    "isAvailable": True,
                    "activeAssignments": 0,
                    "maximumActiveAssignments": 2,
                    "certifications": ["first-aid"],
                    "comfortTier": "High",
                    "availabilityStartUtc": "2026-09-23T08:00:00Z",
                    "availabilityEndUtc": "2026-09-23T18:00:00Z",
                }
            ],
            "matched_volunteer_ids": ["volunteer-1"],
        }

    monkeypatch.setattr(orchestration, "run_triage", mock_run_triage)
    monkeypatch.setattr(orchestration, "run_matching", mock_run_matching)

    app = build_graph()

    config = {
        "configurable": {
            "thread_id": "test-1"
        }
    }

    initial_state = {
        "incident_id": "6bf94b77-2ede-4cc3-9e52-3e549667bcea",
        "raw_report_text": "Flooded street near river, need sandbags.",
        "required_skills": ["first-aid"],
        "estimated_duration_minutes": 60,
        "status": "pending_triage",
    }

    result = app.invoke(initial_state, config=config)

    assert "__interrupt__" in result

    print(
        "Graph paused for approval as expected:",
        result["__interrupt__"]
    )

    final_result = app.invoke(
        Command(
            resume={
                "decision": "approve",
                "feedback": "Looks good."
            }
        ),
        config=config,
    )

    assert final_result["status"] == "approved"
    assert final_result["validation_verdict"] == "approved"
    assert final_result["validated_volunteer_id"] == "volunteer-1"

    print("Final state after approval:", final_result)


if __name__ == "__main__":
    test_graph_pauses_for_approval()