using System;
using System.Collections.Generic;

namespace DVC.Domain.Entities
{
    public enum IncidentCategory
    {
        Flood,
        Landslide,
        PowerOutage,
        MedicalEmergency,
        StructuralDamage,
        Other
    }

    public enum IncidentSeverity
    {
        Low,
        Medium,
        High,
        Critical
    }

    public enum IncidentStatus
    {
        Reported,       // just came in, not yet triaged
        Triaged,        // agent has classified it
        Matching,       // looking for volunteers
        Assigned,       // volunteer(s) assigned, pending dispatch
        InProgress,     // dispatched and being worked
        Resolved,
        Cancelled
    }

    public class Incident
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        public IncidentCategory Category { get; set; }
        public IncidentSeverity Severity { get; set; }
        public IncidentStatus Status { get; set; } = IncidentStatus.Reported;

        // Location — kept simple for now; can extend to PostGIS point later if needed
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? Zone { get; set; }          // human-readable area/zone name
        public string? Address { get; set; }

        // Who reported it (FK to a future User/Requester entity — nullable for now
        // since shared auth isn't wired up yet)
        public Guid? ReportedByUserId { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAtUtc { get; set; }

        // Skills needed — simple string list for now (e.g. "first-aid", "heavy-lifting")
        // Student 2's matching agent will consume this
        public List<string> RequiredSkills { get; set; } = new();

        // Optional: raw text as originally submitted, before the Triage Agent
        // structures it into the fields above (useful for audit/debugging the agent)
        public string? RawReportText { get; set; }
    }
}