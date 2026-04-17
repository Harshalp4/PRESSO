namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class CoinsEndpoints
{
    public static RouteGroupBuilder MapCoinsEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/coins").WithTags("Coins").RequireAuthorization();

        group.MapGet("/balance", async (ClaimsPrincipal user, ICoinsService coinsService) =>
        {
            var result = await coinsService.GetBalanceAsync(user.GetUserId());
            return result.ToResult();
        });

        group.MapGet("/history", async (ClaimsPrincipal user, int page, int pageSize, ICoinsService coinsService) =>
        {
            var result = await coinsService.GetHistoryAsync(user.GetUserId(), page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 10);
            return result.ToResult();
        });

        return group;
    }
}
