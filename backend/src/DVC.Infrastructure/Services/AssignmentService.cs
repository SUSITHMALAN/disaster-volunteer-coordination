using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace DVC.Infrastructure.Services
{
    public class AssignmentService : IAssignmentService
    {
        private readonly DvcDbContext _db;

        public AssignmentService(DvcDbContext db)
        {
            _db = db;
        }

        public async Task<AssignmentResponse> CreateAsync(
            CreateAssignmentRequest request)
        {
            if (request.EstimatedDurationMinutes <= 0)
            {
                throw new InvalidOperationException(
                    "Estimated duration must be greater than zero.");
            }

            var match = await _db.VolunteerMatches
                .Include(m => m.Incident)
                .Include(m => m.Volunteer)
                .FirstOrDefaultAsync(m => m.Id == request.MatchId);

            if (match is null)
                throw new KeyNotFoundException("Volunteer match not found.");

            if (match.Incident is null)
                throw new InvalidOperationException(
                    "The matched incident could not be found.");

            if (match.Volunteer is null)
                throw new InvalidOperationException(
                    "The matched volunteer could not be found.");

            if (match.Status != MatchStatus.Approved)
            {
                throw new InvalidOperationException(
                    "Only approved volunteer matches can be assigned.");
            }

            var volunteer = match.Volunteer;
            var incident = match.Incident;

            if (!volunteer.IsAvailable)
            {
                throw new InvalidOperationException(
                    "Capacity validation failed: volunteer is not available.");
            }

            var activeAssignments = await _db.Assignments
                .CountAsync(a =>
                    a.VolunteerId == volunteer.Id &&
                    a.Status != AssignmentStatus.Completed &&
                    a.Status != AssignmentStatus.Cancelled);

            if (activeAssignments >= volunteer.MaximumActiveAssignments)
            {
                throw new InvalidOperationException(
                    "Capacity validation failed: volunteer has reached maximum capacity.");
            }

            var requiredSkills = incident.RequiredSkills ?? new List<string>();
            var certifications = volunteer.Certifications ?? new List<string>();

            var missingCertifications = requiredSkills
                .Where(required =>
                    !certifications.Any(certification =>
                        string.Equals(
                            certification.Trim(),
                            required.Trim(),
                            StringComparison.OrdinalIgnoreCase)))
                .ToList();

            if (missingCertifications.Count > 0)
            {
                throw new InvalidOperationException(
                    $"Certification validation failed: missing required certification(s): " +
                    $"{string.Join(", ", missingCertifications)}.");
            }

            if (incident.Severity > volunteer.ComfortTier)
            {
                throw new InvalidOperationException(
                    $"Severity validation failed: incident severity " +
                    $"{incident.Severity} exceeds volunteer comfort tier " +
                    $"{volunteer.ComfortTier}.");
            }

            var now = DateTime.UtcNow;

            if (volunteer.AvailabilityStartUtc.HasValue &&
                now < volunteer.AvailabilityStartUtc.Value)
            {
                throw new InvalidOperationException(
                    "Time-window validation failed: volunteer availability has not started.");
            }

            var estimatedEnd = now.AddMinutes(
                request.EstimatedDurationMinutes);

            if (volunteer.AvailabilityEndUtc.HasValue &&
                estimatedEnd > volunteer.AvailabilityEndUtc.Value)
            {
                throw new InvalidOperationException(
                    "Time-window validation failed: volunteer availability does not cover the estimated duration.");
            }

            var hasExistingAssignment = await _db.Assignments
                .AnyAsync(a =>
                    a.MatchId == match.Id &&
                    a.Status != AssignmentStatus.Cancelled &&
                    a.Status != AssignmentStatus.Completed);

            if (hasExistingAssignment)
            {
                throw new InvalidOperationException(
                    "An active assignment already exists for this match.");
            }

            var assignment = new Assignment
            {
                IncidentId = match.IncidentId,
                VolunteerId = match.VolunteerId,
                MatchId = match.Id,
                Status = AssignmentStatus.Assigned,
                EstimatedDurationMinutes =
                    request.EstimatedDurationMinutes,
                AssignedAtUtc = now,
                CreatedAtUtc = now
            };

            _db.Assignments.Add(assignment);

            match.Status = MatchStatus.Dispatched;

            if (incident.Status == IncidentStatus.Matching)
            {
                incident.Status = IncidentStatus.Assigned;
                incident.UpdatedAtUtc = now;
            }

            await _db.SaveChangesAsync();

            return ToResponse(assignment);
        }

        public async Task<AssignmentResponse?> UpdateStatusAsync(
            Guid id,
            UpdateAssignmentStatusRequest request)
        {
            var assignment = await _db.Assignments
                .FirstOrDefaultAsync(a => a.Id == id);

            if (assignment is null)
                return null;

            if (!IsLegalTransition(
                    assignment.Status,
                    request.NewStatus))
            {
                throw new InvalidOperationException(
                    $"Cannot change assignment status from " +
                    $"{assignment.Status} to {request.NewStatus}.");
            }

            var now = DateTime.UtcNow;

            assignment.Status = request.NewStatus;

            switch (request.NewStatus)
            {
                case AssignmentStatus.Dispatched:
                    assignment.DispatchedAtUtc = now;
                    break;

                case AssignmentStatus.InProgress:
                    assignment.StartedAtUtc = now;
                    break;

                case AssignmentStatus.Completed:
                    assignment.CompletedAtUtc = now;
                    break;
            }

            await _db.SaveChangesAsync();

            return ToResponse(assignment);
        }

        public async Task<List<AssignmentResponse>> GetHistoryAsync(
            Guid? volunteerId = null,
            Guid? incidentId = null)
        {
            var query = _db.Assignments.AsQueryable();

            if (volunteerId.HasValue)
            {
                query = query.Where(a =>
                    a.VolunteerId == volunteerId.Value);
            }

            if (incidentId.HasValue)
            {
                query = query.Where(a =>
                    a.IncidentId == incidentId.Value);
            }

            var assignments = await query
                .OrderByDescending(a => a.CreatedAtUtc)
                .ToListAsync();

            return assignments
                .Select(ToResponse)
                .ToList();
        }

        public async Task<VolunteerCapacityResponse?> GetCapacityCheckAsync(
            Guid volunteerId)
        {
            var volunteer = await _db.Users
                .FirstOrDefaultAsync(u =>
                    u.Id == volunteerId &&
                    u.Role == UserRole.Volunteer);

            if (volunteer is null)
                return null;

            var activeAssignments = await _db.Assignments
                .CountAsync(a =>
                    a.VolunteerId == volunteerId &&
                    a.Status != AssignmentStatus.Completed &&
                    a.Status != AssignmentStatus.Cancelled);

            return new VolunteerCapacityResponse
            {
                VolunteerId = volunteer.Id,
                MaximumActiveAssignments =
                    volunteer.MaximumActiveAssignments,
                ActiveAssignments = activeAssignments,
                IsAvailable = volunteer.IsAvailable,
                HasCapacity =
                    volunteer.IsAvailable &&
                    activeAssignments <
                    volunteer.MaximumActiveAssignments
            };
        }

        private static bool IsLegalTransition(
            AssignmentStatus current,
            AssignmentStatus next)
        {
            if (next == AssignmentStatus.Cancelled)
            {
                return current is
                    AssignmentStatus.Assigned or
                    AssignmentStatus.Dispatched or
                    AssignmentStatus.InProgress;
            }

            return current switch
            {
                AssignmentStatus.Assigned =>
                    next == AssignmentStatus.Dispatched,

                AssignmentStatus.Dispatched =>
                    next == AssignmentStatus.InProgress,

                AssignmentStatus.InProgress =>
                    next == AssignmentStatus.Completed,

                _ => false
            };
        }

        private static AssignmentResponse ToResponse(
            Assignment assignment)
        {
            return new AssignmentResponse
            {
                Id = assignment.Id,
                IncidentId = assignment.IncidentId,
                VolunteerId = assignment.VolunteerId,
                MatchId = assignment.MatchId,
                Status = assignment.Status,
                EstimatedDurationMinutes =
                    assignment.EstimatedDurationMinutes,
                AssignedAtUtc = assignment.AssignedAtUtc,
                DispatchedAtUtc = assignment.DispatchedAtUtc,
                StartedAtUtc = assignment.StartedAtUtc,
                CompletedAtUtc = assignment.CompletedAtUtc,
                CreatedAtUtc = assignment.CreatedAtUtc
            };
        }
    }
}