
using DVC.Application.Dtos;
using DVC.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AssignmentsController : ControllerBase
    {
        private readonly IAssignmentService _assignmentService;

        public AssignmentsController(
            IAssignmentService assignmentService)
        {
            _assignmentService = assignmentService;
        }

        // POST /api/assignments
        [HttpPost]
        public async Task<ActionResult<AssignmentResponse>> CreateAssignment(
            CreateAssignmentRequest request)
        {
            try
            {
                var assignment =
                    await _assignmentService.CreateAsync(request);

                return CreatedAtAction(
                    nameof(GetAssignmentHistory),
                    new { },
                    assignment);
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        // PATCH /api/assignments/{id}/status
        [HttpPatch("{id}/status")]
        public async Task<ActionResult<AssignmentResponse>> UpdateStatus(
            Guid id,
            UpdateAssignmentStatusRequest request)
        {
            try
            {
                var assignment =
                    await _assignmentService.UpdateStatusAsync(
                        id,
                        request);

                if (assignment is null)
                    return NotFound("Assignment not found.");

                return Ok(assignment);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        // GET /api/assignments/history
        // Optional filters:
        // ?volunteerId={id}
        // ?incidentId={id}
        [HttpGet("history")]
        public async Task<ActionResult<List<AssignmentResponse>>>
            GetAssignmentHistory(
                [FromQuery] Guid? volunteerId,
                [FromQuery] Guid? incidentId)
        {
            var history =
                await _assignmentService.GetHistoryAsync(
                    volunteerId,
                    incidentId);

            return Ok(history);
        }
    }
}