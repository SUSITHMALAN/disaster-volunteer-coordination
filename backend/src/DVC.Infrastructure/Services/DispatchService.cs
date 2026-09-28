using DVC.Application.Dtos;
using DVC.Application.Services;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace DVC.Infrastructure.Services
{
    public class DispatchService : IDispatchService
    {
        private readonly DvcDbContext _db;

        public DispatchService(DvcDbContext db)
        {
            _db = db;
        }

        public async Task<DispatchResponse> CreateAsync(
            CreateDispatchRequest request)
        {
            if (request.IncidentId == Guid.Empty)
            {
                throw new InvalidOperationException(
                    "Incident ID is required.");
            }

            if (string.IsNullOrWhiteSpace(request.IdempotencyKey))
            {
                throw new InvalidOperationException(
                    "Idempotency key is required.");
            }

            var idempotencyKey = request.IdempotencyKey.Trim();

            var existingDispatch = await _db.Dispatches
                .FirstOrDefaultAsync(d =>
                    d.IdempotencyKey == idempotencyKey);

            if (existingDispatch is not null)
            {
                if (existingDispatch.IncidentId != request.IncidentId)
                {
                    throw new InvalidOperationException(
                        "The idempotency key is already associated with another incident.");
                }

                return ToResponse(existingDispatch);
            }

            var incident = await _db.Incidents
                .FirstOrDefaultAsync(i =>
                    i.Id == request.IncidentId);

            if (incident is null)
            {
                throw new KeyNotFoundException(
                    "Incident not found.");
            }

            if (incident.Status != IncidentStatus.Assigned)
            {
                throw new InvalidOperationException(
                    "The incident must be assigned before it can be dispatched.");
            }

            var dispatch = new Dispatch
            {
                IncidentId = incident.Id,
                IdempotencyKey = idempotencyKey,
                CreatedAtUtc = DateTime.UtcNow
            };

            _db.Dispatches.Add(dispatch);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                var concurrentDispatch = await _db.Dispatches
                    .FirstOrDefaultAsync(d =>
                        d.IdempotencyKey == idempotencyKey);

                if (concurrentDispatch is not null)
                {
                    if (concurrentDispatch.IncidentId != request.IncidentId)
                    {
                        throw new InvalidOperationException(
                            "The idempotency key is already associated with another incident.");
                    }

                    return ToResponse(concurrentDispatch);
                }

                throw;
            }

            return ToResponse(dispatch);
        }

        public async Task<DispatchResponse?> GetByIdAsync(
            Guid id)
        {
            var dispatch = await _db.Dispatches
                .FirstOrDefaultAsync(d => d.Id == id);

            return dispatch is null
                ? null
                : ToResponse(dispatch);
        }

        public async Task<List<DispatchResponse>> GetHistoryAsync(
            Guid? incidentId = null)
        {
            var query = _db.Dispatches.AsQueryable();

            if (incidentId.HasValue)
            {
                query = query.Where(d =>
                    d.IncidentId == incidentId.Value);
            }

            var dispatches = await query
                .OrderByDescending(d => d.CreatedAtUtc)
                .ToListAsync();

            return dispatches
                .Select(ToResponse)
                .ToList();
        }

        private static DispatchResponse ToResponse(
            Dispatch dispatch)
        {
            return new DispatchResponse
            {
                Id = dispatch.Id,
                IncidentId = dispatch.IncidentId,
                IdempotencyKey = dispatch.IdempotencyKey,
                CreatedAtUtc = dispatch.CreatedAtUtc
            };
        }
    }
}