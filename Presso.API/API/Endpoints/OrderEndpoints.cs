namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Order;
using Presso.API.Application.Interfaces;

public static class OrderEndpoints
{
    public static RouteGroupBuilder MapOrderEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/orders").WithTags("Orders").RequireAuthorization();

        group.MapPost("/", async (ClaimsPrincipal user, CreateOrderRequest request, IOrderService orderService) =>
        {
            var result = await orderService.CreateOrderAsync(user.GetUserId(), request);
            return result.ToResult();
        }).WithValidation<CreateOrderRequest>().RequireRateLimiting("orders");

        group.MapGet("/", async (ClaimsPrincipal user, int page, int pageSize, IOrderService orderService) =>
        {
            var result = await orderService.GetUserOrdersAsync(user.GetUserId(), page > 0 ? page : 1, pageSize > 0 ? Math.Min(pageSize, 50) : 10);
            return result.ToResult();
        });

        group.MapGet("/{id:guid}", async (Guid id, ClaimsPrincipal user, IOrderService orderService) =>
        {
            var result = await orderService.GetOrderDetailAsync(id, user.GetUserId());
            return result.ToResult();
        });

        group.MapPatch("/{id:guid}/status", async (Guid id, UpdateOrderStatusRequest request, IOrderService orderService) =>
        {
            var result = await orderService.UpdateOrderStatusAsync(id, request.Status);
            return result.ToResult();
        }).RequireAuthorization("AdminOnly");

        group.MapPatch("/{id:guid}/confirm-pickup-otp", async (Guid id, ConfirmOtpRequest request, IOrderService orderService) =>
        {
            var result = await orderService.ConfirmPickupOtpAsync(id, request.Otp);
            return result.ToResult();
        });

        group.MapPatch("/{id:guid}/confirm-delivery-otp", async (Guid id, ConfirmOtpRequest request, IOrderService orderService) =>
        {
            var result = await orderService.ConfirmDeliveryOtpAsync(id, request.Otp);
            return result.ToResult();
        });

        group.MapPost("/repeat", async (ClaimsPrincipal user, RepeatOrderRequest request, IOrderService orderService) =>
        {
            var result = await orderService.RepeatOrderAsync(user.GetUserId(), request);
            return result.ToResult();
        });

        return group;
    }
}
