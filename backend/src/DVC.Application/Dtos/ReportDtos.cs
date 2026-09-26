using System.ComponentModel.DataAnnotations;
using DVC.Domain.Entities;

namespace DVC.Application.Dtos
{
    public class ResourceReportQuery
    {
        public Guid? IncidentId { get; set; }

        [EnumDataType(typeof(ResourceCategory))]
        public ResourceCategory? Category { get; set; }
    }

    public class ResourceShortageQuery : ResourceReportQuery
    {
        [Range(1, 1000000)]
        public int Page { get; set; } = 1;

        [Range(1, 200)]
        public int PageSize { get; set; } = 50;
    }

    // Quantities are only aggregated within the same resource, category and unit.
    public class ResourceSummaryResponse
    {
        public string ResourceName { get; set; } = string.Empty;
        public ResourceCategory Category { get; set; }
        public string Unit { get; set; } = string.Empty;
        public int ResourceCount { get; set; }
        public int ShortageResourceCount { get; set; }
        public decimal TotalAvailable { get; set; }
        public decimal TotalNeeded { get; set; }
        public decimal TotalUsed { get; set; }
        public decimal TotalShortage { get; set; }
    }

    public class IncidentResourceReportResponse : ResourceSummaryResponse
    {
        public Guid IncidentId { get; set; }
        public string IncidentTitle { get; set; } = string.Empty;
    }

    public class ResourceShortagesResponse
    {
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public List<ResourceResponse> Items { get; set; } = new();
    }

    public class IncidentsByZoneResponse
    {
        // Null means the incident has no recorded zone.
        public string? Zone { get; set; }
        public int TotalIncidents { get; set; }
        public int ActiveIncidents { get; set; }
        public int ResolvedIncidents { get; set; }
        public int CancelledIncidents { get; set; }
    }

    public class VolunteerLoadResponse
    {
        public string Basis { get; set; } =
            "Distinct non-resolved/non-cancelled incidents with Approved or Dispatched matches; " +
            "recorded match load only, not task hours or volunteer capacity.";
        public List<VolunteerLoadItem> Volunteers { get; set; } = new();
    }

    public class VolunteerLoadItem
    {
        public Guid VolunteerId { get; set; }
        public string VolunteerName { get; set; } = string.Empty;
        public bool IsAvailable { get; set; }
        public int ActiveIncidentCount { get; set; }
    }

    public class IncidentStatisticsResponse
    {
        public int TotalIncidents { get; set; }
        public List<IncidentStatisticsItem> Distribution { get; set; } = new();
        public bool ResponseTimeAvailable { get; set; } = false;
        public string ResponseTimeUnavailableReason { get; set; } =
            "The database does not record first-response, dispatch or arrival timestamps. " +
            "UpdatedAtUtc is not a response-time measurement.";
    }

    public class IncidentStatisticsItem
    {
        public IncidentStatus Status { get; set; }
        public IncidentCategory Category { get; set; }
        public IncidentSeverity Severity { get; set; }
        public int IncidentCount { get; set; }
    }
}
