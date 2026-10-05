using DVC.Application.Dtos;

namespace DVC.Application.Services
{
    /// <summary>
    /// Abstraction over the FastAPI agentic-AI bridge service.
    /// Implementations call the REST endpoints exposed by api.py.
    /// </summary>
    public interface IAgentWorkflowService
    {
        /// <summary>
        /// Start a new triage + matching + validation + coordinator workflow.
        /// </summary>
        Task<WorkflowStatusResponse> StartWorkflowAsync(
            StartWorkflowRequest request,
            string? authorizationHeader,
            CancellationToken ct = default);

        /// <summary>
        /// Poll the current state of a running or paused workflow.
        /// </summary>
        Task<WorkflowStatusResponse> GetWorkflowStatusAsync(
            string threadId,
            string? authorizationHeader,
            CancellationToken ct = default);

        /// <summary>
        /// Resume a workflow waiting at the human-approval interrupt.
        /// </summary>
        Task<WorkflowStatusResponse> ApproveWorkflowAsync(
            string threadId,
            WorkflowApprovalRequest request,
            string? authorizationHeader,
            CancellationToken ct = default);
    }
}