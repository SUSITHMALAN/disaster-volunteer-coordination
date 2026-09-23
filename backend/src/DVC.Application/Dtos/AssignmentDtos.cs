using DVC.Domain.Entities;

namespace DVC.Application.Dtos
{
    public class CreateAssignmentRequest
    {
        public Guid MatchId { get; set; }
        public int EstimatedDurationMinutes { get; set; }
    }

    public class UpdateAssignmentStatusRequest
    {
        public AssignmentStatus NewStatus { get; set; }
    }

    public class AssignmentResponse
    {
        public Guid Id { get; set; }
        public Guid IncidentId { get; set; }
        public Guid VolunteerId { get; set; }
        public Guid MatchId { get; set; }
        public AssignmentStatus Status { get; set; }
        public int EstimatedDurationMinutes { get; set; }
        public DateTime AssignedAtUtc { get; set; }
        public DateTime? DispatchedAtUtc { get; set; }
        public DateTime? StartedAtUtc { get; set; }
        public DateTime? CompletedAtUtc { get; set; }
        public DateTime CreatedAtUtc { get; set; }
    }

    public class VolunteerCapacityResponse
    {
        public Guid VolunteerId { get; set; }
        public int MaximumActiveAssignments { get; set; }
        public int ActiveAssignments { get; set; }
        public bool IsAvailable { get; set; }
        public bool HasCapacity { get; set; }
    }
}