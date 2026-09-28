using DVC.Application.Dtos;

namespace DVC.Application.Services
{
    public interface IDispatchService
    {
        Task<DispatchResponse> CreateAsync(
            CreateDispatchRequest request);

        Task<DispatchResponse?> GetByIdAsync(
            Guid id);

        Task<List<DispatchResponse>> GetHistoryAsync(
            Guid? incidentId = null);
    }
}