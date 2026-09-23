using DVC.Application.Dtos;
using DVC.Domain.Entities;

namespace DVC.Application.Services
{
    public interface IResourceService
    {
        Task<ResourceResponse?> CreateAsync(CreateResourceRequest request);
        Task<ResourceResponse?> GetByIdAsync(Guid id);
        Task<List<ResourceResponse>> GetAllAsync(
            Guid? incidentId = null, ResourceCategory? category = null, bool? isShortage = null);
        Task<List<ResourceResponse>?> GetByIncidentAsync(
            Guid incidentId, ResourceCategory? category = null, bool? isShortage = null);
        Task<ResourceResponse?> UpdateAsync(Guid id, UpdateResourceRequest request);
        Task<bool> DeleteAsync(Guid id);
    }
}
