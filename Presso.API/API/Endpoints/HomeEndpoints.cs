namespace Presso.API.API.Endpoints;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class HomeEndpoints
{
    public static RouteGroupBuilder MapHomeEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/home").WithTags("Home");

        group.MapGet("/daily-message", async (IDailyMessageService messageService) =>
        {
            var result = await messageService.GetTodayMessageAsync();
            return result.ToResult();
        });

        group.MapGet("/ai-tip", async (string? context, IDailyMessageService messageService) =>
        {
            var result = await messageService.GetAiTipAsync(context);
            return result.ToResult();
        });

        return group;
    }
}
