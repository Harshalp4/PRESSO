namespace Presso.API.Infrastructure.Repositories;

using Microsoft.EntityFrameworkCore;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;
using Presso.API.Infrastructure.Data;

public class OrderRepository : Repository<Order>, IOrderRepository
{
    public OrderRepository(AppDbContext context) : base(context) { }

    public async Task<string> GenerateOrderNumberAsync()
    {
        var result = await _context.Database
            .SqlQueryRaw<int>(@"SELECT nextval('""OrderNumberSequence""') AS ""Value""")
            .FirstAsync();
        var date = DateTime.UtcNow.ToString("yyyyMMdd");
        return $"PRE-{date}-{result:D4}";
    }

    public async Task<Order?> GetOrderWithDetailsAsync(Guid orderId)
    {
        return await _dbSet
            .Include(o => o.Items).ThenInclude(i => i.ServiceTreatment)
            .Include(o => o.Address)
            .Include(o => o.PickupSlot)
            .Include(o => o.Assignments)
                .ThenInclude(a => a.Rider)
                    .ThenInclude(r => r.User)
            .Include(o => o.User)
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }

    public async Task<List<Order>> GetUserOrdersAsync(Guid userId, int page, int pageSize)
    {
        return await _dbSet
            .Where(o => o.UserId == userId)
            .Include(o => o.PickupSlot)
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<int> GetUserOrderCountAsync(Guid userId)
    {
        return await _dbSet.CountAsync(o => o.UserId == userId);
    }

    public async Task<(List<Order> Items, int Total, int Active, int Delivered, int Cancelled)> SearchOrdersForAdminAsync(
        string? search,
        OrderStatus? status,
        Guid? storeId,
        DateTime? from,
        DateTime? to,
        int page,
        int pageSize)
    {
        // Base query is pre-search/status/date and post-includes so that the
        // list query and the tab-stats query share the same filter set except
        // for status (stats are computed per-status).
        var baseQuery = _dbSet
            .Include(o => o.User)
            .Include(o => o.Items)
            .Include(o => o.AssignedStore)
            .Include(o => o.Assignments)
                .ThenInclude(a => a.Rider)
                    .ThenInclude(r => r.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            var like = $"%{term}%";
            baseQuery = baseQuery.Where(o =>
                EF.Functions.ILike(o.OrderNumber, like) ||
                (o.User.Name != null && EF.Functions.ILike(o.User.Name, like)) ||
                EF.Functions.ILike(o.User.Phone, like));
        }

        if (storeId.HasValue)
            baseQuery = baseQuery.Where(o => o.AssignedStoreId == storeId.Value);

        if (from.HasValue)
            baseQuery = baseQuery.Where(o => o.CreatedAt >= from.Value);

        if (to.HasValue)
            baseQuery = baseQuery.Where(o => o.CreatedAt < to.Value);

        // Stats: computed once over the current filter context (ignoring the
        // status filter so the tabs always add up to "All"). We do a single
        // GroupBy so Postgres can return all buckets in one round-trip.
        var statsByStatus = await baseQuery
            .GroupBy(o => o.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync();

        var active = statsByStatus
            .Where(s => s.Status != OrderStatus.Delivered && s.Status != OrderStatus.Cancelled)
            .Sum(s => s.Count);
        var delivered = statsByStatus.FirstOrDefault(s => s.Status == OrderStatus.Delivered)?.Count ?? 0;
        var cancelled = statsByStatus.FirstOrDefault(s => s.Status == OrderStatus.Cancelled)?.Count ?? 0;
        var total = active + delivered + cancelled;

        // Now apply the status filter (if any) to the page query.
        var pageQuery = baseQuery;
        if (status.HasValue)
            pageQuery = pageQuery.Where(o => o.Status == status.Value);

        var filteredTotal = status.HasValue
            ? statsByStatus.FirstOrDefault(s => s.Status == status.Value)?.Count ?? 0
            : total;

        var items = await pageQuery
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, filteredTotal, active, delivered, cancelled);
    }
}
