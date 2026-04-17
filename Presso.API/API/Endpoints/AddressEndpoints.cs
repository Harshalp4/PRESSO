namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.User;
using Presso.API.Application.Interfaces;

public static class AddressEndpoints
{
    public static RouteGroupBuilder MapAddressEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/addresses").WithTags("Addresses").RequireAuthorization();

        group.MapGet("/", async (ClaimsPrincipal user, IUserService userService) =>
        {
            var result = await userService.GetAddressesAsync(user.GetUserId());
            return result.ToResult();
        });

        group.MapPost("/", async (ClaimsPrincipal user, CreateAddressRequest request, IUserService userService) =>
        {
            var result = await userService.CreateAddressAsync(user.GetUserId(), request);
            return result.ToResult();
        }).WithValidation<CreateAddressRequest>();

        group.MapPut("/{id:guid}", async (Guid id, ClaimsPrincipal user, UpdateAddressRequest request, IUserService userService) =>
        {
            var result = await userService.UpdateAddressAsync(user.GetUserId(), id, request);
            return result.ToResult();
        });

        group.MapDelete("/{id:guid}", async (Guid id, ClaimsPrincipal user, IUserService userService) =>
        {
            var result = await userService.DeleteAddressAsync(user.GetUserId(), id);
            return result.ToResult();
        });

        group.MapPatch("/{id:guid}/default", async (Guid id, ClaimsPrincipal user, IUserService userService) =>
        {
            var result = await userService.SetDefaultAddressAsync(user.GetUserId(), id);
            return result.ToResult();
        });

        return group;
    }
}
