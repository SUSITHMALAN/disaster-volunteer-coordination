using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VolunteersController : ControllerBase
    {
        private readonly DvcDbContext _db;
        private readonly IAssignmentService _assignmentService;

        public VolunteersController(
            DvcDbContext db,
            IAssignmentService assignmentService)
        {
            _db = db;
            _assignmentService = assignmentService;
        }

        // GET /api/volunteers?skill=first-aid&available=true
        [HttpGet]
        public async Task<ActionResult<List<VolunteerListItem>>> GetVolunteers(
            [FromQuery] string? skill,
            [FromQuery] bool? available)
        {
            var query = _db.Users
                .Where(u => u.Role == UserRole.Volunteer);

            if (available.HasValue)
                query = query.Where(u =>
                    u.IsAvailable == available.Value);

            if (!string.IsNullOrWhiteSpace(skill))
            {
                query = query.Where(u =>
                    u.Skills != null &&
                    u.Skills.Contains(skill));
            }

            var volunteers = await query
                .Select(u => new VolunteerListItem
                {
                    Id = u.Id,
                    FullName = u.FullName,
                    Email = u.Email,
                    Skills = u.Skills ?? new List<string>(),
                    IsAvailable = u.IsAvailable,
                    MaximumActiveAssignments = u.MaximumActiveAssignments,

                    ActiveAssignments = _db.Assignments.Count(a =>
                        a.VolunteerId == u.Id &&
                        a.Status != AssignmentStatus.Completed &&
                        a.Status != AssignmentStatus.Cancelled),

                    Certifications = u.Certifications ?? new List<string>(),
                    ComfortTier = u.ComfortTier.ToString(),
                    AvailabilityStartUtc = u.AvailabilityStartUtc,
                    AvailabilityEndUtc = u.AvailabilityEndUtc
                })
                .ToListAsync();

            return Ok(volunteers);
        }

        // PATCH /api/volunteers/{id}/availability
        [HttpPatch("{id}/availability")]
        public async Task<IActionResult> UpdateAvailability(
            Guid id,
            UpdateAvailabilityRequest request)
        {
            var user = await _db.Users.FindAsync(id);

            if (user is null || user.Role != UserRole.Volunteer)
                return NotFound("Volunteer not found.");

            user.IsAvailable = request.IsAvailable;

            await _db.SaveChangesAsync();

            return NoContent();
        }

        // GET /api/volunteers/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<VolunteerListItem>> GetVolunteer(
            Guid id)
        {
            var user = await _db.Users.FindAsync(id);

            if (user is null || user.Role != UserRole.Volunteer)
                return NotFound("Volunteer not found.");

            var activeAssignments = await _db.Assignments.CountAsync(a =>
                a.VolunteerId == id &&
                a.Status != AssignmentStatus.Completed &&
                a.Status != AssignmentStatus.Cancelled);

            return Ok(new VolunteerListItem
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Skills = user.Skills ?? new List<string>(),
                IsAvailable = user.IsAvailable,
                MaximumActiveAssignments = user.MaximumActiveAssignments,
                ActiveAssignments = activeAssignments,
                Certifications = user.Certifications ?? new List<string>(),
                ComfortTier = user.ComfortTier.ToString(),
                AvailabilityStartUtc = user.AvailabilityStartUtc,
                AvailabilityEndUtc = user.AvailabilityEndUtc
            });
        }

        // PATCH /api/volunteers/{id}/profile
        [HttpPatch("{id}/profile")]
        public async Task<IActionResult> UpdateProfile(
            Guid id,
            UpdateProfileRequest request)
        {
            var user = await _db.Users.FindAsync(id);

            if (user is null || user.Role != UserRole.Volunteer)
                return NotFound("Volunteer not found.");

            user.Skills = request.Skills;
            user.IsAvailable = request.IsAvailable;

            await _db.SaveChangesAsync();

            return NoContent();
        }

        // GET /api/volunteers/{id}/capacity-check
        [HttpGet("{id}/capacity-check")]
        public async Task<ActionResult<VolunteerCapacityResponse>>
            GetCapacityCheck(Guid id)
        {
            var result =
                await _assignmentService.GetCapacityCheckAsync(id);

            if (result is null)
                return NotFound("Volunteer not found.");

            return Ok(result);
        }
    }
}