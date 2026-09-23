namespace DVC.Application.Dtos
{
    // ── Request DTOs ──────────────────────────────────────────────────────────

    /// <summary>
    /// Payload sent to POST /workflows on the FastAPI agentic-AI service.
    /// </summary>
    public class StartWorkflowRequest
    {
        /// <summary>The incident ID that this triage workflow is being run for.</summary>
        public string IncidentId { get; set; } = string.Empty;

        /// <summary>Raw free-text incident report that the triage agent will classify.</summary>
        public string RawReportText { get; set; } = string.Empty;

        /// <summary>
        /// Optional pre-known required skills. The triage agent will union these
        /// with whatever skills it infers from the report text.
        /// </summary>
        public List<string> RequiredSkills { get; set; } = new();
    }

    /// <summary>
    /// Payload sent to POST /workflows/{thread_id}/approve.
    /// </summary>
    public class WorkflowApprovalRequest
    {
        /// <summary>"approve", "reject", or "revise".</summary>
        public string Decision { get; set; } = string.Empty;

        /// <summary>Optional free-text coordinator notes.</summary>
        public string? Feedback { get; set; }
    }

    // ── Response DTOs ─────────────────────────────────────────────────────────

    /// <summary>
    /// Returned by all three workflow endpoints.  The State dictionary
    /// mirrors the Python AgentState TypedDict and is left as a flexible
    /// dictionary because its shape evolves as the graph adds new keys.
    /// </summary>
    public class WorkflowStatusResponse
    {
        public string ThreadId { get; set; } = string.Empty;

        /// <summary>
        /// Full agent state key-value pairs (category, severity, matched_volunteer_ids, etc.).
        /// Serialised as-is from the Python service.
        /// </summary>
        public Dictionary<string, object?> State { get; set; } = new();

        /// <summary>
        /// True when the graph is paused at the human-approval interrupt node,
        /// waiting for a call to the approve endpoint.
        /// </summary>
        public bool AwaitingApproval { get; set; }
    }
}
