using DVC.Application.Dtos;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MatchesController : ControllerBase
    {
        private readonly DvcDbContext _db;

        public MatchesController(DvcDbContext db)
        {
            _db = db;
        }

        // GET /api/matches?incidentId=...
        [HttpGet]
        public async Task<ActionResult<List<MatchResponse>>> GetMatches(
            [FromQuery] Guid incidentId)
        {
            var matches = await _db.VolunteerMatches
                .Where(m => m.IncidentId == incidentId)
                .Include(m => m.Volunteer)
                .Select(m => new MatchResponse
                {
                    Id = m.Id,
                    IncidentId = m.IncidentId,
                    VolunteerId = m.VolunteerId,
                    VolunteerName = m.Volunteer!.FullName,
                    Score = m.Score,
                    Rationale = m.Rationale,
                    Status = m.Status.ToString()
                })
                .OrderByDescending(m => m.Score)
                .ToListAsync();

            return Ok(matches);
        }

        // POST /api/matches
        // Called by the Matching Agent after scoring.
        [HttpPost]
        public async Task<ActionResult<MatchResponse>> CreateMatch(
            CreateMatchRequest request)
        {
            var incidentExists = await _db.Incidents
                .AnyAsync(i => i.Id == request.IncidentId);

            if (!incidentExists)
                return NotFound("Incident not found.");

            var volunteer = await _db.Users.FindAsync(request.VolunteerId);

            if (volunteer is null || volunteer.Role != UserRole.Volunteer)
                return NotFound("Volunteer not found.");

            var match = new VolunteerMatch
            {
                IncidentId = request.IncidentId,
                VolunteerId = request.VolunteerId,
                Score = request.Score,
                Rationale = request.Rationale
            };

            _db.VolunteerMatches.Add(match);
            await _db.SaveChangesAsync();

            return Ok(new MatchResponse
            {
                Id = match.Id,
                IncidentId = match.IncidentId,
                VolunteerId = match.VolunteerId,
                VolunteerName = volunteer.FullName,
                Score = match.Score,
                Rationale = match.Rationale,
                Status = match.Status.ToString()
            });
        }

        // PATCH /api/matches/{id}/status
        // Coordinator/Admin approves or rejects a proposed match.
        [Authorize(Roles = "Coordinator,Admin")]
        [HttpPatch("{id}/status")]
        public async Task<ActionResult<MatchResponse>> UpdateStatus(
            Guid id,
            UpdateMatchStatusRequest request)
        {
            var match = await _db.VolunteerMatches
                .Include(m => m.Volunteer)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (match is null)
                return NotFound("Match not found.");

            if (!IsLegalTransition(match.Status, request.NewStatus))
            {
                return BadRequest(
                    $"Cannot change match status from " +
                    $"{match.Status} to {request.NewStatus}.");
            }

            match.Status = request.NewStatus;

            await _db.SaveChangesAsync();

            return Ok(new MatchResponse
            {
                Id = match.Id,
                IncidentId = match.IncidentId,
                VolunteerId = match.VolunteerId,
                VolunteerName = match.Volunteer?.FullName ?? string.Empty,
                Score = match.Score,
                Rationale = match.Rationale,
                Status = match.Status.ToString()
            });
        }

        private static bool IsLegalTransition(
            MatchStatus current,
            MatchStatus next)
        {
            return current switch
            {
                MatchStatus.Proposed =>
                    next is MatchStatus.Approved or MatchStatus.Rejected,

                // Approved is changed to Dispatched by AssignmentService,
                // not directly through this endpoint.
                MatchStatus.Approved => false,

                MatchStatus.Rejected => false,

                MatchStatus.Dispatched => false,

                _ => false
            };
        }
    }
}