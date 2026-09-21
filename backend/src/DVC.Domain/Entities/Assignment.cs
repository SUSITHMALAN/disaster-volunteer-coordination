using System;

namespace DVC.Domain.Entities
{
    public enum AssignmentStatus
    {
        Assigned,
        Dispatched,
        InProgress,
        Completed,
        Cancelled
    }

    public class Assignment
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        // Incident associated with this assignment
        public Guid IncidentId { get; set; }
        public Incident? Incident { get; set; }

        // Volunteer assigned to the incident
        public Guid VolunteerId { get; set; }
        public User? Volunteer { get; set; }

        // Matching proposal that resulted in this assignment
        public Guid MatchId { get; set; }
        public VolunteerMatch? Match { get; set; }

        public AssignmentStatus Status { get; set; } = AssignmentStatus.Assigned;

        // Used by the time-window validation
        public int EstimatedDurationMinutes { get; set; }

        public DateTime AssignedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? DispatchedAtUtc { get; set; }
        public DateTime? StartedAtUtc { get; set; }
        public DateTime? CompletedAtUtc { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}