using DVC.Application.Dtos;

namespace DVC.Application.Services
{
    public interface IAssignmentService
    {
        Task<AssignmentResponse> CreateAsync(CreateAssignmentRequest request);

        Task<AssignmentResponse?> UpdateStatusAsync(
            Guid id,
            UpdateAssignmentStatusRequest request);

        Task<List<AssignmentResponse>> GetHistoryAsync(
            Guid? volunteerId = null,
            Guid? incidentId = null);

        Task<VolunteerCapacityResponse?> GetCapacityCheckAsync(
            Guid volunteerId);
    }
}