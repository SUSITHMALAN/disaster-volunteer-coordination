using DVC.Application.Dtos;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using DVC.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace DVC.Api.Tests;

public class AssignmentServiceTests
{
    private static DvcDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<DvcDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new DvcDbContext(options);
    }

    [Fact]
    public async Task UpdateStatusAsync_AssignedToDispatched_UpdatesStatus()
    {
        await using var db = CreateContext();

        var assignment = new Assignment
        {
            Id = Guid.NewGuid(),
            IncidentId = Guid.NewGuid(),
            VolunteerId = Guid.NewGuid(),
            MatchId = Guid.NewGuid(),
            Status = AssignmentStatus.Assigned,
            EstimatedDurationMinutes = 60,
            AssignedAtUtc = DateTime.UtcNow,
            CreatedAtUtc = DateTime.UtcNow
        };

        db.Assignments.Add(assignment);
        await db.SaveChangesAsync();

        var service = new AssignmentService(db);

        var request = new UpdateAssignmentStatusRequest
        {
            NewStatus = AssignmentStatus.Dispatched
        };

        var result = await service.UpdateStatusAsync(
            assignment.Id,
            request);

        Assert.NotNull(result);
        Assert.Equal(
            AssignmentStatus.Dispatched,
            result.Status);
        Assert.NotNull(result.DispatchedAtUtc);
    }

    [Fact]
    public async Task UpdateStatusAsync_AssignedToCompleted_ThrowsInvalidOperationException()
    {
        await using var db = CreateContext();

        var assignment = new Assignment
        {
            Id = Guid.NewGuid(),
            IncidentId = Guid.NewGuid(),
            VolunteerId = Guid.NewGuid(),
            MatchId = Guid.NewGuid(),
            Status = AssignmentStatus.Assigned,
            EstimatedDurationMinutes = 60,
            AssignedAtUtc = DateTime.UtcNow,
            CreatedAtUtc = DateTime.UtcNow
        };

        db.Assignments.Add(assignment);
        await db.SaveChangesAsync();

        var service = new AssignmentService(db);

        var request = new UpdateAssignmentStatusRequest
        {
            NewStatus = AssignmentStatus.Completed
        };

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.UpdateStatusAsync(
                assignment.Id,
                request));
    }

      [Fact]
      public async Task UpdateStatusAsync_AssignedToCancelled_UpdatesStatus()
      {
          await using var db = CreateContext();

          var assignment = new Assignment
          {
              Id = Guid.NewGuid(),
              IncidentId = Guid.NewGuid(),
              VolunteerId = Guid.NewGuid(),
              MatchId = Guid.NewGuid(),
              Status = AssignmentStatus.Assigned,
              EstimatedDurationMinutes = 60,
              AssignedAtUtc = DateTime.UtcNow,
              CreatedAtUtc = DateTime.UtcNow
          };

          db.Assignments.Add(assignment);
          await db.SaveChangesAsync();

          var service = new AssignmentService(db);

          var request = new UpdateAssignmentStatusRequest
          {
              NewStatus = AssignmentStatus.Cancelled
          };

          var result = await service.UpdateStatusAsync(
              assignment.Id,
              request);

          Assert.NotNull(result);
          Assert.Equal(
              AssignmentStatus.Cancelled,
              result.Status);
      }

      [Fact]
      public async Task GetCapacityCheckAsync_WithAvailableCapacity_ReturnsHasCapacityTrue()
      {
          await using var db = CreateContext();

          var volunteer = new User
          {
              Id = Guid.NewGuid(),
              Email = "volunteer@test.com",
              PasswordHash = "hashed-password",
              Role = UserRole.Volunteer,
              IsAvailable = true,
              MaximumActiveAssignments = 2
          };

          db.Users.Add(volunteer);

          db.Assignments.Add(new Assignment
          {
              Id = Guid.NewGuid(),
              IncidentId = Guid.NewGuid(),
              VolunteerId = volunteer.Id,
              MatchId = Guid.NewGuid(),
              Status = AssignmentStatus.Assigned,
              EstimatedDurationMinutes = 60,
              AssignedAtUtc = DateTime.UtcNow,
              CreatedAtUtc = DateTime.UtcNow
          });

          await db.SaveChangesAsync();

          var service = new AssignmentService(db);

          var result = await service.GetCapacityCheckAsync(
              volunteer.Id);

          Assert.NotNull(result);
          Assert.Equal(1, result.ActiveAssignments);
          Assert.Equal(2, result.MaximumActiveAssignments);
          Assert.True(result.IsAvailable);
          Assert.True(result.HasCapacity);
      }

      [Fact]
      public async Task GetCapacityCheckAsync_AtMaximumCapacity_ReturnsHasCapacityFalse()
      {
          await using var db = CreateContext();

          var volunteer = new User
          {
              Id = Guid.NewGuid(),
              Email = "fullcapacity@test.com",
              PasswordHash = "hashed-password",
              Role = UserRole.Volunteer,
              IsAvailable = true,
              MaximumActiveAssignments = 1
          };

          db.Users.Add(volunteer);

          db.Assignments.Add(new Assignment
          {
              Id = Guid.NewGuid(),
              IncidentId = Guid.NewGuid(),
              VolunteerId = volunteer.Id,
              MatchId = Guid.NewGuid(),
              Status = AssignmentStatus.Assigned,
              EstimatedDurationMinutes = 60,
              AssignedAtUtc = DateTime.UtcNow,
              CreatedAtUtc = DateTime.UtcNow
          });

          await db.SaveChangesAsync();

          var service = new AssignmentService(db);

          var result = await service.GetCapacityCheckAsync(
              volunteer.Id);

          Assert.NotNull(result);
          Assert.Equal(1, result.ActiveAssignments);
          Assert.Equal(1, result.MaximumActiveAssignments);
          Assert.False(result.HasCapacity);
      }

      [Fact]
      public async Task GetHistoryAsync_CanFilterByVolunteer()
      {
          await using var db = CreateContext();

          var volunteerId = Guid.NewGuid();
          var otherVolunteerId = Guid.NewGuid();

          db.Assignments.AddRange(
              new Assignment
              {
                  Id = Guid.NewGuid(),
                  IncidentId = Guid.NewGuid(),
                  VolunteerId = volunteerId,
                  MatchId = Guid.NewGuid(),
                  Status = AssignmentStatus.Assigned,
                  EstimatedDurationMinutes = 60,
                  AssignedAtUtc = DateTime.UtcNow,
                  CreatedAtUtc = DateTime.UtcNow
              },
              new Assignment
              {
                  Id = Guid.NewGuid(),
                  IncidentId = Guid.NewGuid(),
                  VolunteerId = otherVolunteerId,
                  MatchId = Guid.NewGuid(),
                  Status = AssignmentStatus.Assigned,
                  EstimatedDurationMinutes = 60,
                  AssignedAtUtc = DateTime.UtcNow,
                  CreatedAtUtc = DateTime.UtcNow
              });

          await db.SaveChangesAsync();

          var service = new AssignmentService(db);

          var result = await service.GetHistoryAsync(
              volunteerId: volunteerId);

          Assert.Single(result);
          Assert.Equal(
              volunteerId,
              result[0].VolunteerId);
      }

      [Fact]
      public async Task CreateAsync_WithInvalidDuration_ThrowsInvalidOperationException()
      {
          await using var db = CreateContext();

          var service = new AssignmentService(db);

          var request = new CreateAssignmentRequest
          {
              MatchId = Guid.NewGuid(),
              EstimatedDurationMinutes = 0
          };

          await Assert.ThrowsAsync<InvalidOperationException>(
              () => service.CreateAsync(request));
      }
}