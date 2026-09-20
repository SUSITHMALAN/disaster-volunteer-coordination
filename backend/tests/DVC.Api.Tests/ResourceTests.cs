using System.ComponentModel.DataAnnotations;
using DVC.Api.Controllers;
using DVC.Application.Dtos;
using DVC.Domain.Entities;
using Microsoft.AspNetCore.Authorization;

namespace DVC.Api.Tests;

public class ResourceTests
{
    [Theory]
    [InlineData(10, 15, true, 5)]
    [InlineData(10, 10, false, 0)]
    [InlineData(10, 5, false, 0)]
    [InlineData(0, 0, false, 0)]
    public void ShortageUsesTotalNeedAndAllocation(int available, int needed, bool shortage, int difference)
    {
        var resource = new IncidentResource
        {
            AvailableQuantity = available,
            NeededQuantity = needed,
            UsedQuantity = available
        };

        Assert.Equal(shortage, resource.HasShortage);
        Assert.Equal((decimal)difference, resource.ShortageQuantity);
    }

    [Theory]
    [InlineData(-1, 10, 0, false)]
    [InlineData(10, -1, 0, false)]
    [InlineData(10, 10, -1, false)]
    [InlineData(10, 10, 11, false)]
    [InlineData(10, 20, 10, true)]
    [InlineData(0, 0, 0, true)]
    public void RequestsEnforceQuantityRules(int available, int needed, int used, bool valid)
    {
        var request = ValidRequest();
        request.AvailableQuantity = available;
        request.NeededQuantity = needed;
        request.UsedQuantity = used;
        Assert.Equal(valid, IsValid(request));
    }

    [Fact]
    public void RequestsRejectMissingIncidentInvalidCategoryAndBlankNames()
    {
        var request = ValidRequest();
        request.IncidentId = Guid.Empty;
        Assert.False(IsValid(request));
        request = ValidRequest();
        request.Category = (ResourceCategory)999;
        Assert.False(IsValid(request));
        request = ValidRequest();
        request.ResourceName = "   ";
        Assert.False(IsValid(request));
        request = ValidRequest();
        request.Unit = "";
        Assert.False(IsValid(request));
    }

    [Fact]
    public void RequestsRejectValuesThatWouldBeRoundedOrOverflowInPostgres()
    {
        var request = ValidRequest();
        request.AvailableQuantity = 1.001m;
        Assert.False(IsValid(request));
        request.AvailableQuantity = 10000000000000000m;
        Assert.False(IsValid(request));
        request.AvailableQuantity = 9999999999999999.99m;
        Assert.True(IsValid(request));
    }

    [Fact]
    public void ResourceControllerRequiresManagementRole()
    {
        var authorization = Assert.Single(typeof(ResourcesController)
            .GetCustomAttributes(typeof(AuthorizeAttribute), true).Cast<AuthorizeAttribute>());
        Assert.Equal("Coordinator,Admin", authorization.Roles);
        Assert.Empty(typeof(ResourcesController).GetMethods()
            .SelectMany(m => m.GetCustomAttributes(typeof(AllowAnonymousAttribute), true)));
    }

    private static CreateResourceRequest ValidRequest() => new()
    {
        IncidentId = Guid.NewGuid(),
        ResourceName = "Water",
        Category = ResourceCategory.Water,
        Unit = "litres"
    };

    private static bool IsValid(object request) => Validator.TryValidateObject(
        request, new ValidationContext(request), new List<ValidationResult>(), validateAllProperties: true);
}
