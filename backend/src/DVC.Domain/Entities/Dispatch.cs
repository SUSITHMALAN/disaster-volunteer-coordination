namespace DVC.Domain.Entities
{
    public class Dispatch
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid IncidentId { get; set; }
        public Incident? Incident { get; set; }

        public string IdempotencyKey { get; set; } = string.Empty;

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}