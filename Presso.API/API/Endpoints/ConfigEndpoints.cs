namespace Presso.API.API.Endpoints;

using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Infrastructure.Data;

public static class ConfigEndpoints
{
    public static RouteGroupBuilder MapConfigEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/config").WithTags("Config");

        group.MapGet("/", async (AppDbContext db) =>
        {
            var configs = await db.AppConfigs.ToDictionaryAsync(c => c.Key, c => c.Value);
            return Results.Ok(ApiResponse<Dictionary<string, string>>.Ok(configs));
        });

        return group;
    }
}
