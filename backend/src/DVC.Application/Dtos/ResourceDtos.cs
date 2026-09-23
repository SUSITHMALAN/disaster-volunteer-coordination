using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using DVC.Domain.Entities;

namespace DVC.Application.Dtos
{
    public class UpdateResourceRequest : IValidatableObject
    {
        [Required, StringLength(200)]
        public string ResourceName { get; set; } = string.Empty;

        [EnumDataType(typeof(ResourceCategory))]
        public ResourceCategory Category { get; set; } = ResourceCategory.Other;

        [Required, StringLength(50)]
        public string Unit { get; set; } = string.Empty;

        // Missing values must not silently reset quantities to zero on PUT.
        [JsonRequired]
        public decimal AvailableQuantity { get; set; }
        [JsonRequired]
        public decimal NeededQuantity { get; set; }
        [JsonRequired]
        public decimal UsedQuantity { get; set; }

        public virtual IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            var quantities = new[]
            {
                (nameof(AvailableQuantity), AvailableQuantity),
                (nameof(NeededQuantity), NeededQuantity),
                (nameof(UsedQuantity), UsedQuantity)
            };

            foreach (var (name, quantity) in quantities)
            {
                if (quantity < 0 || quantity > 9999999999999999.99m)
                    yield return new ValidationResult(
                        $"{name} must be between 0 and 9999999999999999.99.", new[] { name });
                if (decimal.Round(quantity, 2) != quantity)
                    yield return new ValidationResult(
                        $"{name} must have at most two decimal places.", new[] { name });
            }

            if (UsedQuantity > AvailableQuantity)
                yield return new ValidationResult(
                    "Used quantity cannot exceed the quantity allocated to the incident.",
                    new[] { nameof(UsedQuantity), nameof(AvailableQuantity) });
        }
    }

    public class CreateResourceRequest : UpdateResourceRequest
    {
        public Guid IncidentId { get; set; }

        public override IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            foreach (var result in base.Validate(validationContext))
                yield return result;

            if (IncidentId == Guid.Empty)
                yield return new ValidationResult("Incident ID is required.", new[] { nameof(IncidentId) });
        }
    }

    public class ResourceResponse
    {
        public Guid Id { get; set; }
        public Guid IncidentId { get; set; }
        public string ResourceName { get; set; } = string.Empty;
        public ResourceCategory Category { get; set; }
        public string Unit { get; set; } = string.Empty;
        public decimal AvailableQuantity { get; set; }
        public decimal NeededQuantity { get; set; }
        public decimal UsedQuantity { get; set; }
        public bool IsShortage { get; set; }
        public decimal ShortageQuantity { get; set; }
        public DateTime CreatedAtUtc { get; set; }
        public DateTime? UpdatedAtUtc { get; set; }
    }
}
