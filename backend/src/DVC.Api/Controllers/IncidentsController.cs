using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class IncidentsController : ControllerBase
    {
        private readonly IIncidentService _incidentService;

        public IncidentsController(IIncidentService incidentService)
        {
            _incidentService = incidentService;
        }

        [HttpPost]
        [Authorize(Roles = "Requester,Coordinator,Admin")]
        public async Task<ActionResult<IncidentResponse>> CreateIncident(CreateIncidentRequest request)
        {
            var userId = GetAuthenticatedUserId();
            if (userId is null)
                return Unauthorized("The authenticated user ID is missing or invalid.");

            var incident = await _incidentService.CreateAsync(userId.Value, request);
            return CreatedAtAction(nameof(GetIncident), new { id = incident.Id }, incident);
        }

        [HttpGet]
        [Authorize]
        public async Task<ActionResult<List<IncidentResponse>>> GetIncidents(
            [FromQuery] IncidentStatus? status,
            [FromQuery] IncidentCategory? category,
            [FromQuery] IncidentSeverity? severity,
            [FromQuery] string? zone)
        {
            var incidents = await _incidentService.GetAllAsync(status, category, severity, zone);
            return Ok(incidents);
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<IncidentResponse>> GetIncident(Guid id)
        {
            var incident = await _incidentService.GetByIdAsync(id);
            return incident is null ? NotFound("Incident not found.") : Ok(incident);
        }

        [HttpPatch("{id}/status")]
        [Authorize(Roles = "Coordinator,Admin")]
        public async Task<ActionResult<IncidentResponse>> UpdateStatus(
            Guid id,
            UpdateIncidentStatusRequest request)
        {
            try
            {
                var incident = await _incidentService.UpdateStatusAsync(id, request.NewStatus);
                return incident is null ? NotFound("Incident not found.") : Ok(incident);
            }
            catch (InvalidOperationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        private Guid? GetAuthenticatedUserId()
        {
            var userIdValue = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                ?? User.FindFirstValue(ClaimTypes.NameIdentifier);

            return Guid.TryParse(userIdValue, out var userId) ? userId : null;
        }
    }
}