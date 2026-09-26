using System.ComponentModel.DataAnnotations;
using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DVC.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Coordinator,Admin")]
    public class ResourcesController : ControllerBase
    {
        private readonly IResourceService _resourceService;

        public ResourcesController(IResourceService resourceService)
        {
            _resourceService = resourceService;
        }

        [HttpPost]
        public async Task<ActionResult<ResourceResponse>> CreateResource(CreateResourceRequest request)
        {
            try
            {
                var resource = await _resourceService.CreateAsync(request);
                return resource is null
                    ? NotFound("Incident not found.")
                    : CreatedAtAction(nameof(GetResource), new { id = resource.Id }, resource);
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpGet]
        public async Task<ActionResult<List<ResourceResponse>>> GetResources(
            [FromQuery] Guid? incidentId,
            [FromQuery] ResourceCategory? category,
            [FromQuery] bool? isShortage)
        {
            try
            {
                return Ok(await _resourceService.GetAllAsync(incidentId, category, isShortage));
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpGet("{id:guid}")]
        public async Task<ActionResult<ResourceResponse>> GetResource(Guid id)
        {
            var resource = await _resourceService.GetByIdAsync(id);
            return resource is null ? NotFound("Resource not found.") : Ok(resource);
        }

        [HttpGet("incident/{incidentId:guid}")]
        public async Task<ActionResult<List<ResourceResponse>>> GetIncidentResources(
            Guid incidentId,
            [FromQuery] ResourceCategory? category,
            [FromQuery] bool? isShortage)
        {
            try
            {
                var resources = await _resourceService.GetByIncidentAsync(incidentId, category, isShortage);
                return resources is null ? NotFound("Incident not found.") : Ok(resources);
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpPut("{id:guid}")]
        public async Task<ActionResult<ResourceResponse>> UpdateResource(Guid id, UpdateResourceRequest request)
        {
            try
            {
                var resource = await _resourceService.UpdateAsync(id, request);
                return resource is null ? NotFound("Resource not found.") : Ok(resource);
            }
            catch (ValidationException exception)
            {
                return BadRequest(exception.Message);
            }
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> DeleteResource(Guid id)
        {
            return await _resourceService.DeleteAsync(id) ? NoContent() : NotFound("Resource not found.");
        }
    }
}
