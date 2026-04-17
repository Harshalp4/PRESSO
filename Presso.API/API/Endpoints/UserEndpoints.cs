namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.User;
using Presso.API.Application.Interfaces;

public static class UserEndpoints
{
    public static RouteGroupBuilder MapUserEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/users").WithTags("Users").RequireAuthorization();

        group.MapGet("/me", async (ClaimsPrincipal user, IUserService userService) =>
        {
            var userId = user.GetUserId();
            var result = await userService.GetProfileAsync(userId);
            return result.ToResult();
        });

        group.MapPut("/me", async (ClaimsPrincipal user, UpdateProfileRequest request, IUserService userService) =>
        {
            var userId = user.GetUserId();
            var result = await userService.UpdateProfileAsync(userId, request);
            return result.ToResult();
        }).WithValidation<UpdateProfileRequest>();

        group.MapPost("/student-verify", async (ClaimsPrincipal user, StudentVerifyRequest request, IUserService userService) =>
        {
            var userId = user.GetUserId();
            var result = await userService.SubmitStudentVerificationAsync(userId, request);
            return result.ToResult();
        });

        group.MapGet("/savings", async (ClaimsPrincipal user, IUserService userService) =>
        {
            var userId = user.GetUserId();
            var result = await userService.GetSavingsAsync(userId);
            return result.ToResult();
        });

        group.MapPatch("/me/fcm-token", async (ClaimsPrincipal user, FcmTokenRequest request, IUserService userService) =>
        {
            var userId = user.GetUserId();
            var result = await userService.UpdateFcmTokenAsync(userId, request.Token);
            return result.ToResult();
        });

        return group;
    }
}
