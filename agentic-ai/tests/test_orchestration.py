from langgraph.types import Command
from graph.orchestration import build_graph


def test_graph_pauses_for_approval():
    app = build_graph()
    config = {"configurable": {"thread_id": "test-1"}}

    initial_state = {
        "incident_id": "INC-001",
        "raw_report_text": "Flooded street near river, need sandbags.",
        "status": "pending_triage",
    }

    # Run until it hits the interrupt (human approval pause)
    result = app.invoke(initial_state, config=config)

    assert "__interrupt__" in result
    print("Graph paused for approval as expected:", result["__interrupt__"])

    # Simulate human approving — resume the SAME run with Command
    final_result = app.invoke(
        Command(resume={"decision": "approve", "feedback": "Looks good."}),
        config=config,
    )

    assert final_result["status"] == "approved"
    print("Final state after approval:", final_result)


if __name__ == "__main__":
    test_graph_pauses_for_approval()