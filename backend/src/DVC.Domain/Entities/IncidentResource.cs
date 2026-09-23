namespace DVC.Domain.Entities
{
    public enum ResourceCategory
    {
        Water,
        FirstAid,
        Food,
        Transport,
        Other
    }

    public class IncidentResource
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid IncidentId { get; set; }
        public Incident? Incident { get; set; }

        public string ResourceName { get; set; } = string.Empty;
        public ResourceCategory Category { get; set; } = ResourceCategory.Other;
        public string Unit { get; set; } = string.Empty;

        // Total quantity allocated to this incident, including quantity already used.
        // Recording usage does not reduce this value.
        public decimal AvailableQuantity { get; set; }

        // Total requirement for this incident, in the same unit as the allocation.
        public decimal NeededQuantity { get; set; }
        public decimal UsedQuantity { get; set; }

        public bool HasShortage => NeededQuantity > AvailableQuantity;
        public decimal ShortageQuantity => Math.Max(NeededQuantity - AvailableQuantity, 0m);
        public decimal RemainingQuantity => AvailableQuantity - UsedQuantity;

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAtUtc { get; set; }
    }
}
