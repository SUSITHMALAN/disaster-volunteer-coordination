using System.ComponentModel.DataAnnotations;
using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace DVC.Infrastructure.Services
{
    public class ReportingService : IReportingService
    {
        private readonly DvcDbContext _db;

        public ReportingService(DvcDbContext db)
        {
            _db = db;
        }

        public Task<List<ResourceSummaryResponse>> GetResourceSummaryAsync(ResourceReportQuery query)
        {
            return FilterResources(query)
                .GroupBy(r => new { r.ResourceName, r.Category, r.Unit })
                .Select(g => new ResourceSummaryResponse
                {
                    ResourceName = g.Key.ResourceName,
                    Category = g.Key.Category,
                    Unit = g.Key.Unit,
                    ResourceCount = g.Count(),
                    ShortageResourceCount = g.Count(r => r.NeededQuantity > r.AvailableQuantity),
                    TotalAvailable = g.Sum(r => r.AvailableQuantity),
                    TotalNeeded = g.Sum(r => r.NeededQuantity),
                    TotalUsed = g.Sum(r => r.UsedQuantity),
                    TotalShortage = g.Sum(r => r.NeededQuantity > r.AvailableQuantity
                        ? r.NeededQuantity - r.AvailableQuantity : 0m)
                })
                .OrderBy(r => r.Category).ThenBy(r => r.ResourceName).ThenBy(r => r.Unit)
                .ToListAsync();
        }

        public async Task<ResourceShortagesResponse> GetResourceShortagesAsync(ResourceShortageQuery query)
        {
            var shortages = FilterResources(query)
                .Where(r => r.NeededQuantity > r.AvailableQuantity);

            var count = await shortages.CountAsync();
            var items = await shortages.OrderBy(r => r.IncidentId).ThenBy(r => r.Id)
                .Skip((query.Page - 1) * query.PageSize).Take(query.PageSize)
                .Select(r => new ResourceResponse
                {
                    Id = r.Id,
                    IncidentId = r.IncidentId,
                    ResourceName = r.ResourceName,
                    Category = r.Category,
                    Unit = r.Unit,
                    AvailableQuantity = r.AvailableQuantity,
                    NeededQuantity = r.NeededQuantity,
                    UsedQuantity = r.UsedQuantity,
                    IsShortage = true,
                    ShortageQuantity = r.NeededQuantity - r.AvailableQuantity,
                    CreatedAtUtc = r.CreatedAtUtc,
                    UpdatedAtUtc = r.UpdatedAtUtc
                }).ToListAsync();

            return new ResourceShortagesResponse
            {
                TotalCount = count, Page = query.Page, PageSize = query.PageSize, Items = items
            };
        }

        public Task<List<IncidentResourceReportResponse>> GetResourcesByIncidentAsync(ResourceReportQuery query)
        {
            // Incidents without resource records have no resource distribution rows.
            return FilterResources(query)
                .GroupBy(r => new { r.IncidentId, IncidentTitle = r.Incident!.Title,
                    r.ResourceName, r.Category, r.Unit })
                .Select(g => new IncidentResourceReportResponse
                {
                    IncidentId = g.Key.IncidentId,
                    IncidentTitle = g.Key.IncidentTitle,
                    ResourceName = g.Key.ResourceName,
                    Category = g.Key.Category,
                    Unit = g.Key.Unit,
                    ResourceCount = g.Count(),
                    ShortageResourceCount = g.Count(r => r.NeededQuantity > r.AvailableQuantity),
                    TotalAvailable = g.Sum(r => r.AvailableQuantity),
                    TotalNeeded = g.Sum(r => r.NeededQuantity),
                    TotalUsed = g.Sum(r => r.UsedQuantity),
                    TotalShortage = g.Sum(r => r.NeededQuantity > r.AvailableQuantity
                        ? r.NeededQuantity - r.AvailableQuantity : 0m)
                })
                .OrderBy(r => r.IncidentId).ThenBy(r => r.Category)
                .ThenBy(r => r.ResourceName).ThenBy(r => r.Unit).ToListAsync();
        }

        public Task<List<IncidentsByZoneResponse>> GetIncidentsByZoneAsync()
        {
            return _db.Incidents.AsNoTracking()
                .GroupBy(i => i.Zone == null || i.Zone.Trim() == "" ? null : i.Zone.Trim())
                .Select(g => new IncidentsByZoneResponse
                {
                    Zone = g.Key,
                    TotalIncidents = g.Count(),
                    ActiveIncidents = g.Count(i => i.Status != IncidentStatus.Resolved &&
                        i.Status != IncidentStatus.Cancelled),
                    ResolvedIncidents = g.Count(i => i.Status == IncidentStatus.Resolved),
                    CancelledIncidents = g.Count(i => i.Status == IncidentStatus.Cancelled)
                }).OrderBy(r => r.Zone).ToListAsync();
        }

        public async Task<VolunteerLoadResponse> GetVolunteerLoadAsync()
        {
            // Start from Users to retain volunteers with zero qualifying matches.
            var volunteers = await _db.Users.AsNoTracking().Where(u => u.Role == UserRole.Volunteer)
                .Select(u => new VolunteerLoadItem
                {
                    VolunteerId = u.Id,
                    VolunteerName = u.FullName,
                    IsAvailable = u.IsAvailable,
                    ActiveIncidentCount = _db.VolunteerMatches
                        .Where(m => m.VolunteerId == u.Id &&
                            (m.Status == MatchStatus.Approved || m.Status == MatchStatus.Dispatched) &&
                            m.Incident!.Status != IncidentStatus.Resolved &&
                            m.Incident.Status != IncidentStatus.Cancelled)
                        .Select(m => m.IncidentId).Distinct().Count()
                })
                .OrderByDescending(v => v.ActiveIncidentCount).ThenBy(v => v.VolunteerId).ToListAsync();

            return new VolunteerLoadResponse { Volunteers = volunteers };
        }

        public async Task<IncidentStatisticsResponse> GetIncidentStatisticsAsync()
        {
            var distribution = await _db.Incidents.AsNoTracking()
                .GroupBy(i => new { i.Status, i.Category, i.Severity })
                .Select(g => new IncidentStatisticsItem
                {
                    Status = g.Key.Status,
                    Category = g.Key.Category,
                    Severity = g.Key.Severity,
                    IncidentCount = g.Count()
                }).OrderBy(i => i.Status).ThenBy(i => i.Category).ThenBy(i => i.Severity).ToListAsync();

            return new IncidentStatisticsResponse
            {
                // Only the small, already aggregated distribution is summed in memory.
                TotalIncidents = distribution.Sum(i => i.IncidentCount),
                Distribution = distribution
            };
        }

        private IQueryable<IncidentResource> FilterResources(ResourceReportQuery query)
        {
            Validator.ValidateObject(query, new ValidationContext(query), validateAllProperties: true);
            var resources = _db.IncidentResources.AsNoTracking();
            if (query.IncidentId.HasValue)
                resources = resources.Where(r => r.IncidentId == query.IncidentId.Value);
            if (query.Category.HasValue)
                resources = resources.Where(r => r.Category == query.Category.Value);
            return resources;
        }
    }
}
