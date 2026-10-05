using DVC.Api.Controllers;
using DVC.Application.Dtos;
using DVC.Domain.Entities;
using DVC.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DVC.Api.Tests;

public class VolunteerEndpointsTests
{
    private static DvcDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<DvcDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new DvcDbContext(options);
    }

    [Fact]
    public async Task GetVolunteers_ReturnsOnlyVolunteersMatchingSkillAndAvailability()
    {
        await using var db = CreateContext();

        var vol1 = new User
        {
            Id = Guid.NewGuid(),
            FullName = "Volunteer One",
            Email = "vol1@example.com",
            Role = UserRole.Volunteer,
            Skills = new List<string> { "first-aid", "driving" },
            IsAvailable = true
        };

        var vol2 = new User
        {
            Id = Guid.NewGuid(),
            FullName = "Volunteer Two",
            Email = "vol2@example.com",
            Role = UserRole.Volunteer,
            Skills = new List<string> { "cooking" },
            IsAvailable = false
        };

        db.Users.AddRange(vol1, vol2);
        await db.SaveChangesAsync();

        var controller = new VolunteersController(db, null!);

        var actionResult = await controller.GetVolunteers("first-aid",true,null);
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var items = Assert.IsType<List<VolunteerListItem>>(okResult.Value);

        Assert.Single(items);
        Assert.Equal(vol1.Id, items[0].Id);
        Assert.Equal("Volunteer One", items[0].FullName);
    }

    [Fact]
    public async Task GetVolunteer_ReturnsNotFound_WhenVolunteerDoesNotExist()
    {
        await using var db = CreateContext();

        var controller = new VolunteersController(db, null!);

        var actionResult = await controller.GetVolunteer(Guid.NewGuid());
        Assert.IsType<NotFoundObjectResult>(actionResult.Result);
    }

    [Fact]
    public async Task GetVolunteer_ReturnsVolunteer_WhenFound()
    {
        await using var db = CreateContext();

        var vol = new User
        {
            Id = Guid.NewGuid(),
            FullName = "Jane Volunteer",
            Email = "jane@example.com",
            Role = UserRole.Volunteer,
            Skills = new List<string> { "first-aid" },
            IsAvailable = true
        };

        db.Users.Add(vol);
        await db.SaveChangesAsync();

        var controller = new VolunteersController(db, null!);

        var actionResult = await controller.GetVolunteer(vol.Id);
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var item = Assert.IsType<VolunteerListItem>(okResult.Value);

        Assert.Equal(vol.Id, item.Id);
        Assert.Equal("Jane Volunteer", item.FullName);
    }

    [Fact]
    public async Task UpdateAvailability_UpdatesAvailabilityState()
    {
        await using var db = CreateContext();

        var vol = new User
        {
            Id = Guid.NewGuid(),
            FullName = "Volunteer Three",
            Email = "vol3@example.com",
            Role = UserRole.Volunteer,
            IsAvailable = true
        };

        db.Users.Add(vol);
        await db.SaveChangesAsync();

        var controller = new VolunteersController(db, null!);

        var result = await controller.UpdateAvailability(vol.Id, new UpdateAvailabilityRequest { IsAvailable = false });
        Assert.IsType<NoContentResult>(result);

        var updatedVol = await db.Users.FindAsync(vol.Id);
        Assert.NotNull(updatedVol);
        Assert.False(updatedVol.IsAvailable);
    }

    [Fact]
    public async Task UpdateProfile_UpdatesSkillsAndAvailability()
    {
        await using var db = CreateContext();

        var vol = new User
        {
            Id = Guid.NewGuid(),
            FullName = "Volunteer Four",
            Email = "vol4@example.com",
            Role = UserRole.Volunteer,
            Skills = new List<string> { "logistic" },
            IsAvailable = false
        };

        db.Users.Add(vol);
        await db.SaveChangesAsync();

        var controller = new VolunteersController(db, null!);

        var request = new UpdateProfileRequest
        {
            Skills = new List<string> { "first-aid", "rescue" },
            IsAvailable = true
        };

        var result = await controller.UpdateProfile(vol.Id, request);
        Assert.IsType<NoContentResult>(result);

        var updatedVol = await db.Users.FindAsync(vol.Id);
        Assert.NotNull(updatedVol);
        Assert.True(updatedVol.IsAvailable);
        Assert.Contains("first-aid", updatedVol.Skills!);
        Assert.Contains("rescue", updatedVol.Skills!);
    }
}
