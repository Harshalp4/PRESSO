namespace Presso.API.API.Endpoints;

using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Auth;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class AuthEndpoints
{
    public static RouteGroupBuilder MapAuthEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/auth").WithTags("Auth");

        group.MapPost("/login", async (LoginRequest request, IAuthService authService) =>
        {
            var result = await authService.LoginWithFirebaseAsync(request);
            return result.ToResult();
        }).WithValidation<LoginRequest>().RequireRateLimiting("auth");

        group.MapPost("/refresh", async (RefreshTokenRequest request, IAuthService authService) =>
        {
            var result = await authService.RefreshTokenAsync(request.RefreshToken);
            return result.ToResult();
        });

        group.MapPost("/admin-login", async (AdminLoginRequest request, IAuthService authService) =>
        {
            var result = await authService.LoginAsAdminAsync(request);
            return result.ToResult();
        }).RequireRateLimiting("auth");

        return group;
    }
}
