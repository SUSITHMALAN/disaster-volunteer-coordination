using DVC.Domain.Entities;

namespace DVC.Application.Dtos
{
    public class CreateDispatchRequest
    {
        public Guid IncidentId { get; set; }

        public string IdempotencyKey { get; set; } = string.Empty;
    }

    public class DispatchResponse
    {
        public Guid Id { get; set; }

        public Guid IncidentId { get; set; }

        public string IdempotencyKey { get; set; } = string.Empty;

        public DateTime CreatedAtUtc { get; set; }
    }
}