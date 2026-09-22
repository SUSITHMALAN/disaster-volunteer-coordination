using System;
using System.Collections.Generic;

namespace DVC.Application.Dtos
{
    public class VolunteerListItem
    {
        public Guid Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public List<string> Skills { get; set; } = new();
        public bool IsAvailable { get; set; }

        public int MaximumActiveAssignments { get; set; }
        public int ActiveAssignments { get; set; }
        public List<string> Certifications { get; set; } = new();
        public string ComfortTier { get; set; } = string.Empty;
        public DateTime? AvailabilityStartUtc { get; set; }
        public DateTime? AvailabilityEndUtc { get; set; }
    }

    public class UpdateAvailabilityRequest
    {
        public bool IsAvailable { get; set; }
    }

    public class CreateMatchRequest
    {
        public Guid IncidentId { get; set; }
        public Guid VolunteerId { get; set; }
        public double Score { get; set; }
        public string? Rationale { get; set; }
    }

    public class MatchResponse
    {
        public Guid Id { get; set; }
        public Guid IncidentId { get; set; }
        public Guid VolunteerId { get; set; }
        public string VolunteerName { get; set; } = string.Empty;
        public double Score { get; set; }
        public string? Rationale { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    public class UpdateProfileRequest
    {
        public List<string> Skills { get; set; } = new();
        public bool IsAvailable { get; set; }
    }
}