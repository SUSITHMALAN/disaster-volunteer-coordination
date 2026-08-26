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

        // Volunteer-specific — nullable since irrelevant for other roles
        public List<string>? Skills { get; set; }
        public bool IsAvailable { get; set; } = true;

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}