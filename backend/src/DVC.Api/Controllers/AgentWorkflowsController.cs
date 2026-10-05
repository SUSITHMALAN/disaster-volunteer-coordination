using DVC.Application.Dtos;
using DVC.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DVC.Api.Controllers
{
    /// <summary>
    /// Bridges ASP.NET Core to the Python FastAPI agentic-AI service.
    /// All endpoints require a valid JWT; only Coordinators and Admins
    /// may start workflows or record approval decisions.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AgentWorkflowsController : ControllerBase
    {
        private readonly IAgentWorkflowService _agentWorkflowService;
        private readonly ILogger<AgentWorkflowsController> _logger;

        public AgentWorkflowsController(
            IAgentWorkflowService agentWorkflowService,
            ILogger<AgentWorkflowsController> logger)
        {
            _agentWorkflowService = agentWorkflowService;
            _logger = logger;
        }

        /// <summary>
        /// Start a new triage → matching → validation → coordinator workflow
        /// for a given incident.
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Coordinator,Admin")]
        public async Task<ActionResult<WorkflowStatusResponse>> StartWorkflow(
            [FromBody] StartWorkflowRequest request,
            CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(request.IncidentId))
            {
                return BadRequest("IncidentId is required.");
            }

            if (string.IsNullOrWhiteSpace(request.RawReportText))
            {
                return BadRequest("RawReportText is required.");
            }

            try
            {
                var authorizationHeader =
                    Request.Headers.Authorization.ToString();

                var result =
                    await _agentWorkflowService.StartWorkflowAsync(
                        request,
                        authorizationHeader,
                        ct);

                return Ok(result);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Agent service unreachable while starting workflow for incident {IncidentId}",
                    request.IncidentId);

                return StatusCode(
                    503,
                    "The agentic-AI service is currently unavailable. Please try again later.");
            }
        }

        /// <summary>
        /// Poll the current state of a running or paused workflow.
        /// </summary>
        [HttpGet("{threadId}")]
        public async Task<ActionResult<WorkflowStatusResponse>> GetWorkflowStatus(
            string threadId,
            CancellationToken ct)
        {
            try
            {
                var authorizationHeader =
                    Request.Headers.Authorization.ToString();

                var result =
                    await _agentWorkflowService.GetWorkflowStatusAsync(
                        threadId,
                        authorizationHeader,
                        ct);

                return Ok(result);
            }
            catch (HttpRequestException ex)
                when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                return NotFound(
                    $"Workflow '{threadId}' not found.");
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Agent service unreachable while fetching workflow {ThreadId}",
                    threadId);

                return StatusCode(
                    503,
                    "The agentic-AI service is currently unavailable.");
            }
        }

        /// <summary>
        /// Submit a human approval, rejection, or revision request for a
        /// workflow that is paused at the coordinator interrupt node.
        /// </summary>
        [HttpPost("{threadId}/approve")]
        [Authorize(Roles = "Coordinator,Admin")]
        public async Task<ActionResult<WorkflowStatusResponse>> ApproveWorkflow(
            string threadId,
            [FromBody] WorkflowApprovalRequest request,
            CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(request.Decision))
            {
                return BadRequest(
                    "Decision is required (approve / reject / revise).");
            }

            try
            {
                var authorizationHeader =
                    Request.Headers.Authorization.ToString();

                var result =
                    await _agentWorkflowService.ApproveWorkflowAsync(
                        threadId,
                        request,
                        authorizationHeader,
                        ct);

                return Ok(result);
            }
            catch (HttpRequestException ex)
                when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                return NotFound(
                    $"Workflow '{threadId}' not found.");
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Agent service unreachable while approving workflow {ThreadId}",
                    threadId);

                return StatusCode(
                    503,
                    "The agentic-AI service is currently unavailable.");
            }
        }
    }
}