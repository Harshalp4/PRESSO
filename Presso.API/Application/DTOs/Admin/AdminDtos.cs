namespace Presso.API.Application.DTOs.Admin;

public record DashboardDto(
    int TotalOrders, int PendingOrders, int ActiveOrders,
    int CompletedOrders, decimal TotalRevenue, decimal TodayRevenue,
    int TotalCustomers, int ActiveRiders);

public record AssignRiderRequest(Guid OrderId, Guid RiderId, string Type);

public record CustomerListDto(
    Guid Id, string? Name, string Phone, string? Email,
    bool IsStudentVerified, int CoinBalance, int OrderCount,
    decimal TotalSpent, DateTime? LastOrderAt, DateTime CreatedAt);

public record CustomerRecentOrderDto(
    Guid Id, string OrderNumber, string Status, decimal TotalAmount,
    int ItemCount, DateTime CreatedAt);

public record CustomerDetailDto(
    Guid Id,
    string? Name,
    string Phone,
    string? Email,
    bool IsStudentVerified,
    int CoinBalance,
    int OrderCount,
    decimal TotalSpent,
    decimal AverageOrderValue,
    DateTime? FirstOrderAt,
    DateTime? LastOrderAt,
    DateTime CreatedAt,
    List<CustomerRecentOrderDto> RecentOrders);

public record UpdateSlotRequest(int? MaxOrders, bool? IsActive, int? SortOrder);

public record CreateSlotRequest(TimeOnly StartTime, TimeOnly EndTime, int MaxOrders, int? SortOrder);

public record AdminSlotDto(
    Guid Id,
    TimeOnly StartTime,
    TimeOnly EndTime,
    int MaxOrders,
    bool IsActive,
    int SortOrder);

public record ReviewStudentVerificationRequest(bool Approved, string? ReviewNote);

public record PaymentListDto(
    Guid OrderId, string OrderNumber, decimal Amount,
    string PaymentStatus, string? RazorpayPaymentId, DateTime CreatedAt);

