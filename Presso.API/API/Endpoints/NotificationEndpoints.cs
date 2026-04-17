namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class NotificationEndpoints
{
    public static RouteGroupBuilder MapNotificationEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/notifications").WithTags("Notifications").RequireAuthorization();

        group.MapGet("/", async (ClaimsPrincipal user, int page, int pageSize, INotificationService notifService) =>
        {
            var result = await notifService.GetNotificationsAsync(user.GetUserId(), page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 10);
            return result.ToResult();
        });

        group.MapPatch("/{id:guid}/read", async (Guid id, ClaimsPrincipal user, INotificationService notifService) =>
        {
            var result = await notifService.MarkAsReadAsync(user.GetUserId(), id);
            return result.ToResult();
        });

        group.MapPatch("/read-all", async (ClaimsPrincipal user, INotificationService notifService) =>
        {
            var result = await notifService.MarkAllAsReadAsync(user.GetUserId());
            return result.ToResult();
        });

        return group;
    }
}
