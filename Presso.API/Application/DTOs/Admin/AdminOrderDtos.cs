namespace Presso.API.Application.DTOs.Admin;

using Presso.API.Application.DTOs.Common;

public record AdminOrderListItemDto(
    Guid Id,
    string OrderNumber,
    string Status,
    string? FacilityStage,
    string PaymentStatus,
    decimal TotalAmount,
    int ItemCount,
    Guid CustomerId,
    string? CustomerName,
    string CustomerPhone,
    string? CurrentRiderName,
    Guid? AssignedStoreId,
    string? AssignedStoreName,
    bool IsExpressDelivery,
    DateTime CreatedAt);

public record AdminOrderStatsDto(
    int All,
    int Active,
    int Delivered,
    int Cancelled);

public record AdminOrderListResponse(
    PaginatedResponse<AdminOrderListItemDto> Orders,
    AdminOrderStatsDto Stats);
