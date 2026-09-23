using DVC.Application.Dtos;

namespace DVC.Application.Services
{
    /// <summary>
    /// Abstraction over the FastAPI agentic-AI bridge service.
    /// Implementations call the three REST endpoints exposed by api.py.
    /// </summary>
    public interface IAgentWorkflowService
    {
        /// <summary>
        /// Start a new triage + matching + validation + coordinator workflow
        /// for the given incident.  Returns immediately when the graph pauses
        /// at the human-approval interrupt.
        /// </summary>
        Task<WorkflowStatusResponse> StartWorkflowAsync(StartWorkflowRequest request, CancellationToken ct = default);

        /// <summary>
        /// Poll the current state of a running or paused workflow.
        /// </summary>
        Task<WorkflowStatusResponse> GetWorkflowStatusAsync(string threadId, CancellationToken ct = default);

        /// <summary>
        /// Resume a workflow that is waiting at the human-approval interrupt.
        /// </summary>
        Task<WorkflowStatusResponse> ApproveWorkflowAsync(string threadId, WorkflowApprovalRequest request, CancellationToken ct = default);
    }
}
