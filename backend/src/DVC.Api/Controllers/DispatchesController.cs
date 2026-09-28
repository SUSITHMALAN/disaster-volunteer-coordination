using DVC.Application.Dtos;
using DVC.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DispatchesController : ControllerBase
    {
        private readonly IDispatchService _dispatchService;

        public DispatchesController(
            IDispatchService dispatchService)
        {
            _dispatchService = dispatchService;
        }

        // POST /api/dispatches
        [HttpPost]
        public async Task<ActionResult<DispatchResponse>> CreateDispatch(
            CreateDispatchRequest request)
        {
            try
            {
                var dispatch =
                    await _dispatchService.CreateAsync(request);

                return CreatedAtAction(
                    nameof(GetDispatch),
                    new { id = dispatch.Id },
                    dispatch);
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

        // GET /api/dispatches/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<DispatchResponse>> GetDispatch(
            Guid id)
        {
            var dispatch =
                await _dispatchService.GetByIdAsync(id);

            if (dispatch is null)
                return NotFound("Dispatch not found.");

            return Ok(dispatch);
        }

        // GET /api/dispatches/history
        // Optional filter:
        // ?incidentId={id}
        [HttpGet("history")]
        public async Task<ActionResult<List<DispatchResponse>>>
            GetDispatchHistory(
                [FromQuery] Guid? incidentId)
        {
            var history =
                await _dispatchService.GetHistoryAsync(
                    incidentId);

            return Ok(history);
        }
    }
}