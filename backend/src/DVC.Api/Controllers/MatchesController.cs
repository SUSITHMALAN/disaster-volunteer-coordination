using DVC.Application.Dtos;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
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
        public async Task<ActionResult<List<MatchResponse>>> GetMatches([FromQuery] Guid incidentId)
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

        // POST /api/matches  — called by the Matching Agent after scoring
        [HttpPost]
        public async Task<ActionResult<MatchResponse>> CreateMatch(CreateMatchRequest request)
        {
            var incidentExists = await _db.Incidents.AnyAsync(i => i.Id == request.IncidentId);
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
    }
}