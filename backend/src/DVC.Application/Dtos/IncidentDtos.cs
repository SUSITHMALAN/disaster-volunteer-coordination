using DVC.Domain.Entities;

namespace DVC.Application.Dtos
{
    public class CreateIncidentRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public IncidentCategory Category { get; set; }
        public IncidentSeverity Severity { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? Zone { get; set; }
        public string? Address { get; set; }
        public List<string> RequiredSkills { get; set; } = new();
        public string? RawReportText { get; set; }
    }

    public class IncidentResponse
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public IncidentCategory Category { get; set; }
        public IncidentSeverity Severity { get; set; }
        public IncidentStatus Status { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? Zone { get; set; }
        public string? Address { get; set; }
        public Guid? ReportedByUserId { get; set; }
        public DateTime CreatedAtUtc { get; set; }
        public DateTime? UpdatedAtUtc { get; set; }
        public List<string> RequiredSkills { get; set; } = new();
        public string? RawReportText { get; set; }
    }

    public class UpdateIncidentStatusRequest
    {
        public IncidentStatus NewStatus { get; set; }
    }
}