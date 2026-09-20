using System.ComponentModel.DataAnnotations;
using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace DVC.Infrastructure.Services
{
    public class ResourceService : IResourceService
    {
        private readonly DvcDbContext _db;

        public ResourceService(DvcDbContext db)
        {
            _db = db;
        }

        public async Task<ResourceResponse?> CreateAsync(CreateResourceRequest request)
        {
            Validator.ValidateObject(request, new ValidationContext(request), validateAllProperties: true);
            if (!await _db.Incidents.AnyAsync(i => i.Id == request.IncidentId))
                return null;

            var resource = new IncidentResource { IncidentId = request.IncidentId };
            ApplyRequest(resource, request);
            _db.IncidentResources.Add(resource);
            await _db.SaveChangesAsync();
            return ToResponse(resource);
        }

        public async Task<ResourceResponse?> GetByIdAsync(Guid id)
        {
            var resource = await _db.IncidentResources.AsNoTracking().FirstOrDefaultAsync(r => r.Id == id);
            return resource is null ? null : ToResponse(resource);
        }

        public async Task<List<ResourceResponse>> GetAllAsync(
            Guid? incidentId = null, ResourceCategory? category = null, bool? isShortage = null)
        {
            if (category.HasValue && !Enum.IsDefined(category.Value))
                throw new ValidationException("Invalid resource category.");

            var query = _db.IncidentResources.AsNoTracking();
            if (incidentId.HasValue)
                query = query.Where(r => r.IncidentId == incidentId.Value);
            if (category.HasValue)
                query = query.Where(r => r.Category == category.Value);
            if (isShortage.HasValue)
                query = query.Where(r => (r.NeededQuantity > r.AvailableQuantity) == isShortage.Value);

            var resources = await query.OrderByDescending(r => r.CreatedAtUtc).ToListAsync();
            return resources.Select(ToResponse).ToList();
        }

        public async Task<List<ResourceResponse>?> GetByIncidentAsync(
            Guid incidentId, ResourceCategory? category = null, bool? isShortage = null)
        {
            if (!await _db.Incidents.AnyAsync(i => i.Id == incidentId))
                return null;
            return await GetAllAsync(incidentId, category, isShortage);
        }

        public async Task<ResourceResponse?> UpdateAsync(Guid id, UpdateResourceRequest request)
        {
            Validator.ValidateObject(request, new ValidationContext(request), validateAllProperties: true);
            var resource = await _db.IncidentResources.FindAsync(id);
            if (resource is null)
                return null;

            ApplyRequest(resource, request);
            resource.UpdatedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return ToResponse(resource);
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var resource = await _db.IncidentResources.FindAsync(id);
            if (resource is null)
                return false;

            _db.IncidentResources.Remove(resource);
            await _db.SaveChangesAsync();
            return true;
        }

        private static void ApplyRequest(IncidentResource resource, UpdateResourceRequest request)
        {
            resource.ResourceName = request.ResourceName.Trim();
            resource.Category = request.Category;
            resource.Unit = request.Unit.Trim();
            resource.AvailableQuantity = request.AvailableQuantity;
            resource.NeededQuantity = request.NeededQuantity;
            resource.UsedQuantity = request.UsedQuantity;
        }

        private static ResourceResponse ToResponse(IncidentResource resource)
        {
            return new ResourceResponse
            {
                Id = resource.Id,
                IncidentId = resource.IncidentId,
                ResourceName = resource.ResourceName,
                Category = resource.Category,
                Unit = resource.Unit,
                AvailableQuantity = resource.AvailableQuantity,
                NeededQuantity = resource.NeededQuantity,
                UsedQuantity = resource.UsedQuantity,
                IsShortage = resource.HasShortage,
                ShortageQuantity = resource.ShortageQuantity,
                CreatedAtUtc = resource.CreatedAtUtc,
                UpdatedAtUtc = resource.UpdatedAtUtc
            };
        }
    }
}
