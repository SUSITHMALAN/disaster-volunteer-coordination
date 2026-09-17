using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace DVC.Infrastructure.Services
{
    public class IncidentService : IIncidentService
    {
        private readonly DvcDbContext _db;

        public IncidentService(DvcDbContext db)
        {
            _db = db;
        }

        public async Task<IncidentResponse> CreateAsync(
            Guid reportedByUserId,
            CreateIncidentRequest request)
        {
            var incident = new Incident
            {
                Title = request.Title,
                Description = request.Description,
                Category = request.Category,
                Severity = request.Severity,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Zone = request.Zone,
                Address = request.Address,
                ReportedByUserId = reportedByUserId,
                RequiredSkills = request.RequiredSkills,
                RawReportText = request.RawReportText
            };

            _db.Incidents.Add(incident);
            await _db.SaveChangesAsync();

            return ToResponse(incident);
        }

        public async Task<IncidentResponse?> GetByIdAsync(Guid id)
        {
            var incident = await _db.Incidents.FindAsync(id);
            return incident is null ? null : ToResponse(incident);
        }

        public async Task<List<IncidentResponse>> GetAllAsync(
            IncidentStatus? status = null,
            IncidentCategory? category = null,
            IncidentSeverity? severity = null,
            string? zone = null)
        {
            var query = _db.Incidents.AsQueryable();

            if (status.HasValue)
                query = query.Where(i => i.Status == status.Value);

            if (category.HasValue)
                query = query.Where(i => i.Category == category.Value);

            if (severity.HasValue)
                query = query.Where(i => i.Severity == severity.Value);

            if (!string.IsNullOrWhiteSpace(zone))
                query = query.Where(i => i.Zone == zone);

            var incidents = await query
                .OrderByDescending(i => i.CreatedAtUtc)
                .ToListAsync();

            return incidents.Select(ToResponse).ToList();
        }

        public async Task<IncidentResponse?> UpdateStatusAsync(Guid id, IncidentStatus newStatus)
        {
            var incident = await _db.Incidents.FindAsync(id);
            if (incident is null)
                return null;

            if (!IsLegalTransition(incident.Status, newStatus))
            {
                throw new InvalidOperationException(
                    $"Cannot change incident status from {incident.Status} to {newStatus}.");
            }

            incident.Status = newStatus;
            incident.UpdatedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return ToResponse(incident);
        }

        private static bool IsLegalTransition(IncidentStatus current, IncidentStatus next)
        {
            if (next == IncidentStatus.Cancelled)
                return current is not IncidentStatus.Resolved and not IncidentStatus.Cancelled;

            return current switch
            {
                IncidentStatus.Reported => next == IncidentStatus.Triaged,
                IncidentStatus.Triaged => next == IncidentStatus.Matching,
                IncidentStatus.Matching => next == IncidentStatus.Assigned,
                IncidentStatus.Assigned => next == IncidentStatus.InProgress,
                IncidentStatus.InProgress => next == IncidentStatus.Resolved,
                _ => false
            };
        }

        private static IncidentResponse ToResponse(Incident incident)
        {
            return new IncidentResponse
            {
                Id = incident.Id,
                Title = incident.Title,
                Description = incident.Description,
                Category = incident.Category,
                Severity = incident.Severity,
                Status = incident.Status,
                Latitude = incident.Latitude,
                Longitude = incident.Longitude,
                Zone = incident.Zone,
                Address = incident.Address,
                ReportedByUserId = incident.ReportedByUserId,
                CreatedAtUtc = incident.CreatedAtUtc,
                UpdatedAtUtc = incident.UpdatedAtUtc,
                RequiredSkills = incident.RequiredSkills,
                RawReportText = incident.RawReportText
            };
        }
    }
}