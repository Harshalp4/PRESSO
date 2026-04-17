namespace Presso.API.API.Endpoints;

using Microsoft.EntityFrameworkCore;
using Presso.API.Infrastructure.Data;

public static class HealthEndpoints
{
    public static RouteGroupBuilder MapHealthEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("").WithTags("Health");

        group.MapGet("/health", async (AppDbContext context) =>
        {
            try
            {
                await context.Database.CanConnectAsync();
                return Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
            }
            catch
            {
                return Results.Json(new { status = "unhealthy", timestamp = DateTime.UtcNow }, statusCode: 503);
            }
        });

        return group;
    }
}
