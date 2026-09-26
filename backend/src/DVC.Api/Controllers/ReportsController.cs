using System.ComponentModel.DataAnnotations;
using DVC.Application.Dtos;
using DVC.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Coordinator,Admin")]
    public class ReportsController : ControllerBase
    {
        private readonly IReportingService _reportingService;

        public ReportsController(IReportingService reportingService)
        {
            _reportingService = reportingService;
        }

        [HttpGet("resources/summary")]
        public async Task<ActionResult<List<ResourceSummaryResponse>>> GetResourceSummary(
            [FromQuery] ResourceReportQuery query)
        {
            try
            {
                return Ok(await _reportingService.GetResourceSummaryAsync(query));
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpGet("resources/shortages")]
        public async Task<ActionResult<ResourceShortagesResponse>> GetResourceShortages(
            [FromQuery] ResourceShortageQuery query)
        {
            try
            {
                return Ok(await _reportingService.GetResourceShortagesAsync(query));
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpGet("resources/by-incident")]
        public async Task<ActionResult<List<IncidentResourceReportResponse>>> GetResourcesByIncident(
            [FromQuery] ResourceReportQuery query)
        {
            try
            {
                return Ok(await _reportingService.GetResourcesByIncidentAsync(query));
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpGet("incidents/by-zone")]
        public async Task<ActionResult<List<IncidentsByZoneResponse>>> GetIncidentsByZone()
        {
            return Ok(await _reportingService.GetIncidentsByZoneAsync());
        }

        [HttpGet("volunteers/load")]
        public async Task<ActionResult<VolunteerLoadResponse>> GetVolunteerLoad()
        {
            return Ok(await _reportingService.GetVolunteerLoadAsync());
        }

        [HttpGet("incidents/statistics")]
        public async Task<ActionResult<IncidentStatisticsResponse>> GetIncidentStatistics()
        {
            return Ok(await _reportingService.GetIncidentStatisticsAsync());
        }
    }
}
