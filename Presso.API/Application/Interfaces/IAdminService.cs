namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Order;

public interface IAdminService
{
    Task<Result<DashboardDto>> GetDashboardAsync();
    Task<Result<bool>> AssignRiderAsync(AssignRiderRequest request);
    Task<Result<PaginatedResponse<CustomerListDto>>> GetCustomersAsync(int page, int pageSize, string? search);
    Task<Result<CustomerDetailDto>> GetCustomerDetailAsync(Guid customerId);
    Task<Result<bool>> ReviewStudentVerificationAsync(Guid verificationId, ReviewStudentVerificationRequest request);
    Task<Result<List<AdminSlotDto>>> GetSlotsAsync();
    Task<Result<AdminSlotDto>> CreateSlotAsync(CreateSlotRequest request);
    Task<Result<AdminSlotDto>> UpdateSlotAsync(Guid slotId, UpdateSlotRequest request);
    Task<Result<PaginatedResponse<PaymentListDto>>> GetPaymentsAsync(int page, int pageSize, string? status, string? search);

    // Finance
    Task<Result<PnlDto>> GetPnlAsync(int days);
    Task<Result<PaginatedResponse<ExpenseDto>>> GetExpensesAsync(int page, int pageSize, string? category);
    Task<Result<ExpenseDto>> CreateExpenseAsync(CreateExpenseRequest request);
    Task<Result<ExpenseDto>> UpdateExpenseAsync(Guid id, UpdateExpenseRequest request);
    Task<Result<bool>> DeleteExpenseAsync(Guid id);
    Task<Result<PaginatedResponse<RiderPayoutDto>>> GetPayoutsAsync(int page, int pageSize, string? status);
    Task<Result<RiderPayoutDto>> CreatePayoutAsync(CreatePayoutRequest request);
    Task<Result<RiderPayoutDto>> UpdatePayoutStatusAsync(Guid id, UpdatePayoutStatusRequest request);
    Task<Result<List<RiderPayoutSummaryDto>>> GetRiderPayoutSummariesAsync(DateOnly from, DateOnly to);

    Task<Result<AdminOrderListResponse>> GetOrdersAsync(
        int page,
        int pageSize,
        string? search,
        string? status,
        Guid? storeId,
        string? range,
        DateTime? from,
        DateTime? to);

    Task<Result<OrderDetailDto>> GetOrderDetailForAdminAsync(Guid orderId);

    // === Riders admin ===
    Task<Result<AdminRiderListResponse>> GetRidersForAdminAsync(
        int page,
        int pageSize,
        string? search,
        string? status);

    Task<Result<AdminRiderDetailDto>> GetRiderDetailForAdminAsync(Guid riderId);

    Task<Result<AdminRiderDetailDto>> CreateRiderAsync(CreateAdminRiderRequest request);

    Task<Result<AdminRiderDetailDto>> ApproveRiderAsync(Guid riderId, ApproveRiderRequest request);
    Task<Result<AdminRiderDetailDto>> RejectRiderAsync(Guid riderId, RejectRiderRequest request);
    Task<Result<AdminRiderDetailDto>> SuspendRiderAsync(Guid riderId, SuspendRiderRequest request);
    Task<Result<AdminRiderDetailDto>> ReinstateRiderAsync(Guid riderId);
    Task<Result<AdminRiderDetailDto>> UpdateRiderNotesAsync(Guid riderId, UpdateRiderNotesRequest request);
}
