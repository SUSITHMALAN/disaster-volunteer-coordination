using System;

namespace DVC.Domain.Entities
{
    public enum MatchStatus
    {
        Proposed,   // scored by the Matching Agent, awaiting validation/approval
        Approved,   // passed validation + human approval
        Rejected,
        Dispatched  // Coordinator Agent has dispatched this volunteer
    }

    public class VolunteerMatch
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid IncidentId { get; set; }
        public Incident? Incident { get; set; }

        public Guid VolunteerId { get; set; }
        public User? Volunteer { get; set; }

        public double Score { get; set; }
        public string? Rationale { get; set; }   // LLM-generated explanation text

        public MatchStatus Status { get; set; } = MatchStatus.Proposed;

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}