using DVC.Application.Dtos;

namespace DVC.Application.Services
{
    public interface IReportingService
    {
        Task<List<ResourceSummaryResponse>> GetResourceSummaryAsync(ResourceReportQuery query);
        Task<ResourceShortagesResponse> GetResourceShortagesAsync(ResourceShortageQuery query);
        Task<List<IncidentResourceReportResponse>> GetResourcesByIncidentAsync(ResourceReportQuery query);
        Task<List<IncidentsByZoneResponse>> GetIncidentsByZoneAsync();
        Task<VolunteerLoadResponse> GetVolunteerLoadAsync();
        Task<IncidentStatisticsResponse> GetIncidentStatisticsAsync();
    }
}
