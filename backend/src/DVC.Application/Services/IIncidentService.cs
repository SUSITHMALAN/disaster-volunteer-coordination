using DVC.Application.Dtos;
using DVC.Domain.Entities;

namespace DVC.Application.Services
{
    public interface IIncidentService
    {
        Task<IncidentResponse> CreateAsync(Guid reportedByUserId, CreateIncidentRequest request);
        Task<IncidentResponse?> GetByIdAsync(Guid id);
        Task<List<IncidentResponse>> GetAllAsync(
            IncidentStatus? status = null,
            IncidentCategory? category = null,
            IncidentSeverity? severity = null,
            string? zone = null);
        Task<IncidentResponse?> UpdateStatusAsync(Guid id, IncidentStatus newStatus);
    }
}