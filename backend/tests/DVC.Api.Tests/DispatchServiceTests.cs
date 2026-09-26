using DVC.Application.Dtos;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using DVC.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace DVC.Api.Tests;

public class DispatchServiceTests
{
    private static DvcDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<DvcDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new DvcDbContext(options);
    }

    private static Incident CreateAssignedIncident()
    {
        return new Incident
        {
            Id = Guid.NewGuid(),
            Title = "Flood Incident",
            Description = "Local flooding",
            Category = IncidentCategory.Flood,
            Severity = IncidentSeverity.Medium,
            Status = IncidentStatus.Assigned,
            RequiredSkills = new List<string>()
        };
    }

    [Fact]
    public async Task CreateAsync_CreatesDispatchForAssignedIncident()
    {
        await using var db = CreateContext();

        var incident = CreateAssignedIncident();

        db.Incidents.Add(incident);
        await db.SaveChangesAsync();

        var service = new DispatchService(db);

        var request = new CreateDispatchRequest
        {
            IncidentId = incident.Id,
            IdempotencyKey = "dispatch-test-001"
        };

        var result = await service.CreateAsync(request);

        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal(incident.Id, result.IncidentId);
        Assert.Equal(
            "dispatch-test-001",
            result.IdempotencyKey);

        var storedDispatch = await db.Dispatches
            .SingleAsync();

        Assert.Equal(result.Id, storedDispatch.Id);
    }

    [Fact]
    public async Task CreateAsync_WithUnassignedIncident_ThrowsInvalidOperationException()
    {
        await using var db = CreateContext();

        var incident = CreateAssignedIncident();
        incident.Status = IncidentStatus.Matching;

        db.Incidents.Add(incident);
        await db.SaveChangesAsync();

        var service = new DispatchService(db);

        var request = new CreateDispatchRequest
        {
            IncidentId = incident.Id,
            IdempotencyKey = "dispatch-unassigned-001"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.CreateAsync(request));
    }

    [Fact]
    public async Task CreateAsync_WithSameIdempotencyKey_ReturnsExistingDispatch()
    {
        await using var db = CreateContext();

        var incident = CreateAssignedIncident();

        db.Incidents.Add(incident);
        await db.SaveChangesAsync();

        var service = new DispatchService(db);

        var request = new CreateDispatchRequest
        {
            IncidentId = incident.Id,
            IdempotencyKey = "dispatch-idempotent-001"
        };

        var first = await service.CreateAsync(request);
        var second = await service.CreateAsync(request);

        Assert.Equal(first.Id, second.Id);

        var dispatchCount =
            await db.Dispatches.CountAsync();

        Assert.Equal(1, dispatchCount);
    }

    [Fact]
    public async Task CreateAsync_WithSameKeyForDifferentIncident_ThrowsInvalidOperationException()
    {
        await using var db = CreateContext();

        var firstIncident = CreateAssignedIncident();
        var secondIncident = CreateAssignedIncident();

        db.Incidents.AddRange(
            firstIncident,
            secondIncident);

        await db.SaveChangesAsync();

        var service = new DispatchService(db);

        var firstRequest = new CreateDispatchRequest
        {
            IncidentId = firstIncident.Id,
            IdempotencyKey = "dispatch-conflict-001"
        };

        var secondRequest = new CreateDispatchRequest
        {
            IncidentId = secondIncident.Id,
            IdempotencyKey = "dispatch-conflict-001"
        };

        await service.CreateAsync(firstRequest);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.CreateAsync(secondRequest));
    }

    [Fact]
    public async Task CreateAsync_WithUnknownIncident_ThrowsKeyNotFoundException()
    {
        await using var db = CreateContext();

        var service = new DispatchService(db);

        var request = new CreateDispatchRequest
        {
            IncidentId = Guid.NewGuid(),
            IdempotencyKey = "dispatch-invalid-001"
        };

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => service.CreateAsync(request));
    }

    [Fact]
    public async Task GetHistoryAsync_CanFilterByIncident()
    {
        await using var db = CreateContext();

        var firstIncident = CreateAssignedIncident();
        var secondIncident = CreateAssignedIncident();

        db.Incidents.AddRange(
            firstIncident,
            secondIncident);

        db.Dispatches.AddRange(
            new Dispatch
            {
                IncidentId = firstIncident.Id,
                IdempotencyKey = "dispatch-history-001"
            },
            new Dispatch
            {
                IncidentId = secondIncident.Id,
                IdempotencyKey = "dispatch-history-002"
            });

        await db.SaveChangesAsync();

        var service = new DispatchService(db);

        var result =
            await service.GetHistoryAsync(firstIncident.Id);

        Assert.Single(result);
        Assert.Equal(
            firstIncident.Id,
            result[0].IncidentId);
    }
}