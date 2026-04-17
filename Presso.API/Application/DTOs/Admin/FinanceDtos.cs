namespace Presso.API.Application.DTOs.Admin;

// ──── P&L / Earnings ────
public record PnlDto(
    decimal TotalRevenue,
    decimal TodayRevenue,
    decimal WeekRevenue,
    decimal MonthRevenue,
    int CapturedCount,
    int PendingCount,
    int FailedCount,
    int RefundedCount,
    decimal AvgOrderValue,
    decimal TotalCoinDiscount,
    decimal TotalStudentDiscount,
    decimal TotalAdminDiscount,
    decimal TotalExpressCharge,
    decimal TotalExpenses,
    decimal TotalRiderPayouts,
    decimal NetEarnings,
    List<DailyRevenueDto> DailyRevenue);

public record DailyRevenueDto(DateOnly Date, decimal Revenue, int OrderCount);

// ──── Expenses ────
public record ExpenseDto(
    Guid Id,
    string Category,
    string Description,
    decimal Amount,
    DateOnly Date,
    string? Reference,
    DateTime CreatedAt);

public record CreateExpenseRequest(
    string Category,
    string Description,
    decimal Amount,
    DateOnly Date,
    string? Reference);

public record UpdateExpenseRequest(
    string? Category,
    string? Description,
    decimal? Amount,
    DateOnly? Date,
    string? Reference);

// ──── Payouts ────
public record RiderPayoutDto(
    Guid Id,
    Guid RiderId,
    string RiderName,
    string RiderPhone,
    decimal Amount,
    int DeliveryCount,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    string Status,
    DateTime? PaidAt,
    string? Reference,
    string? Notes,
    DateTime CreatedAt);

public record CreatePayoutRequest(
    Guid RiderId,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    string? Notes);

public record UpdatePayoutStatusRequest(
    string Status,
    string? Reference);

// Rider summary for payout generation screen
public record RiderPayoutSummaryDto(
    Guid RiderId,
    string Name,
    string Phone,
    int CompletedDeliveries,
    decimal AmountOwed,
    decimal AmountPaid);
