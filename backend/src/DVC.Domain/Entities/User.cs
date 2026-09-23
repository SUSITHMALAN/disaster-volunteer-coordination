using System;
using System.Collections.Generic;

namespace DVC.Domain.Entities
{
    public enum UserRole
    {
        Requester,
        Volunteer,
        Coordinator,
        Admin
    }

    public class User
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;

        public UserRole Role { get; set; }

        // Volunteer-specific
        public List<string>? Skills { get; set; }
        public bool IsAvailable { get; set; } = true;

        // Maximum number of active assignments allowed
        public int MaximumActiveAssignments { get; set; } = 1;

        // Certifications held by the volunteer
        public List<string>? Certifications { get; set; }

        // Highest incident severity the volunteer is comfortable handling
        public IncidentSeverity ComfortTier { get; set; } = IncidentSeverity.Low;

        // Declared availability window
        public DateTime? AvailabilityStartUtc { get; set; }
        public DateTime? AvailabilityEndUtc { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}