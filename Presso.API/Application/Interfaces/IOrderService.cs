namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Order;

public interface IOrderService
{
    Task<Result<OrderDetailDto>> CreateOrderAsync(Guid userId, CreateOrderRequest request);
    Task<Result<PaginatedResponse<OrderDto>>> GetUserOrdersAsync(Guid userId, int page, int pageSize);
    Task<Result<OrderDetailDto>> GetOrderDetailAsync(Guid orderId, Guid userId);
    Task<Result<OrderDetailDto>> UpdateOrderStatusAsync(Guid orderId, string status);
    Task<Result<bool>> ConfirmPickupOtpAsync(Guid orderId, string otp);
    Task<Result<bool>> ConfirmDeliveryOtpAsync(Guid orderId, string otp);
    Task<Result<OrderDetailDto>> RepeatOrderAsync(Guid userId, RepeatOrderRequest request);
    Task<Result<List<SlotDto>>> GetAvailableSlotsAsync(DateOnly date);
}
