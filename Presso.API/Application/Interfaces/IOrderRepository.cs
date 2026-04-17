namespace Presso.API.Application.Interfaces;

using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public interface IOrderRepository : IRepository<Order>
{
    Task<string> GenerateOrderNumberAsync();
    Task<Order?> GetOrderWithDetailsAsync(Guid orderId);
    Task<List<Order>> GetUserOrdersAsync(Guid userId, int page, int pageSize);
    Task<int> GetUserOrderCountAsync(Guid userId);

    /// <summary>
    /// Admin-scoped order search. Returns paged orders matching the filters,
    /// plus tab-count stats computed over the same (unpaginated) filter set
    /// so the UI can show accurate "Active/Delivered/Cancelled" counts for
    /// the current search context.
    /// </summary>
    Task<(List<Order> Items, int Total, int Active, int Delivered, int Cancelled)> SearchOrdersForAdminAsync(
        string? search,
        OrderStatus? status,
        Guid? storeId,
        DateTime? from,
        DateTime? to,
        int page,
        int pageSize);
}
