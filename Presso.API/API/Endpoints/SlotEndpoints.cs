namespace Presso.API.API.Endpoints;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;

public static class SlotEndpoints
{
    public static RouteGroupBuilder MapSlotEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/slots").WithTags("Slots").RequireAuthorization();

        group.MapGet("/", async (DateOnly date, IOrderService orderService) =>
        {
            var result = await orderService.GetAvailableSlotsAsync(date);
            return result.ToResult();
        });

        return group;
    }
}
