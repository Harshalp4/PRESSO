namespace Presso.API.Application.Services;

using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Order;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public class AdminService : IAdminService
{
    private readonly IOrderRepository _orderRepo;
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<Rider> _riderRepo;
    private readonly IRepository<OrderAssignment> _assignmentRepo;
    private readonly IRepository<PickupSlot> _slotRepo;
    private readonly IRepository<StudentVerification> _verificationRepo;
    private readonly IRepository<Expense> _expenseRepo;
    private readonly IRepository<RiderPayout> _payoutRepo;
    private readonly INotificationService _notificationService;
    private readonly IMapper _mapper;
    private readonly decimal _riderPayPerDelivery;

    public AdminService(
        IOrderRepository orderRepo,
        IRepository<User> userRepo,
        IRepository<Rider> riderRepo,
        IRepository<OrderAssignment> assignmentRepo,
        IRepository<PickupSlot> slotRepo,
        IRepository<StudentVerification> verificationRepo,
        IRepository<Expense> expenseRepo,
        IRepository<RiderPayout> payoutRepo,
        INotificationService notificationService,
        IMapper mapper,
        IConfiguration config)
    {
        _orderRepo = orderRepo;
        _userRepo = userRepo;
        _riderRepo = riderRepo;
        _assignmentRepo = assignmentRepo;
        _slotRepo = slotRepo;
        _verificationRepo = verificationRepo;
        _expenseRepo = expenseRepo;
        _payoutRepo = payoutRepo;
        _notificationService = notificationService;
        _mapper = mapper;
        _riderPayPerDelivery = config.GetValue<decimal>("OrderSettings:RiderPayPerDelivery", 30);
    }

    public async Task<Result<DashboardDto>> GetDashboardAsync()
    {
        var today = DateTime.UtcNow.Date;
        var totalOrders = await _orderRepo.CountAsync();
        var pendingOrders = await _orderRepo.CountAsync(o => o.Status == OrderStatus.Pending);
        var activeOrders = await _orderRepo.CountAsync(o =>
            o.Status != OrderStatus.Delivered && o.Status != OrderStatus.Cancelled && o.Status != OrderStatus.Pending);
        var completedOrders = await _orderRepo.CountAsync(o => o.Status == OrderStatus.Delivered);
        var totalRevenue = await _orderRepo.Query()
            .Where(o => o.PaymentStatus == PaymentStatus.Captured)
            .SumAsync(o => o.TotalAmount);
        var todayRevenue = await _orderRepo.Query()
            .Where(o => o.PaymentStatus == PaymentStatus.Captured && o.CreatedAt.Date == today)
            .SumAsync(o => o.TotalAmount);
        var totalCustomers = await _userRepo.CountAsync(u => u.Role == UserRole.Customer);
        var activeRiders = await _riderRepo.CountAsync(r => r.IsAvailable && r.IsActive);

        return Result<DashboardDto>.Success(new DashboardDto(
            totalOrders, pendingOrders, activeOrders, completedOrders,
            totalRevenue, todayRevenue, totalCustomers, activeRiders));
    }

    public async Task<Result<bool>> AssignRiderAsync(AssignRiderRequest request)
    {
        var order = await _orderRepo.GetByIdAsync(request.OrderId);
        if (order == null) return Result<bool>.NotFound("Order not found");

        var rider = await _riderRepo.GetByIdAsync(request.RiderId);
        if (rider == null) return Result<bool>.NotFound("Rider not found");

        if (!Enum.TryParse<AssignmentType>(request.Type, true, out var type))
            return Result<bool>.Failure("Invalid assignment type");

        var assignment = new OrderAssignment
        {
            Id = Guid.NewGuid(),
            OrderId = request.OrderId,
            RiderId = request.RiderId,
            Type = type,
            Status = AssignmentStatus.Assigned
        };

        await _assignmentRepo.AddAsync(assignment);

        if (order.Status == OrderStatus.Pending || order.Status == OrderStatus.Confirmed)
            order.Status = OrderStatus.RiderAssigned;

        _orderRepo.Update(order);
        await _orderRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<PaginatedResponse<CustomerListDto>>> GetCustomersAsync(int page, int pageSize, string? search)
    {
        var query = _userRepo.Query().Where(u => u.Role == UserRole.Customer);

        if (!string.IsNullOrWhiteSpace(search))
        {
            // Case-insensitive search across name / phone / email. ILike
            // matches the pattern used elsewhere (Orders, Riders) so the
            // portal has a consistent UX.
            var pattern = $"%{search.Trim()}%";
            query = query.Where(u =>
                (u.Name != null && EF.Functions.ILike(u.Name, pattern))
                || EF.Functions.ILike(u.Phone, pattern)
                || (u.Email != null && EF.Functions.ILike(u.Email, pattern)));
        }

        var totalCount = await query.CountAsync();

        // Count only paid/completed orders for spend totals — pending/failed
        // payments would otherwise inflate "total spent" beyond what the
        // customer actually handed over.
        var customers = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new CustomerListDto(
                u.Id,
                u.Name,
                u.Phone,
                u.Email,
                u.IsStudentVerified,
                u.CoinBalance,
                u.Orders.Count,
                u.Orders
                    .Where(o => o.PaymentStatus == PaymentStatus.Captured)
                    .Sum(o => (decimal?)o.TotalAmount) ?? 0m,
                u.Orders
                    .OrderByDescending(o => o.CreatedAt)
                    .Select(o => (DateTime?)o.CreatedAt)
                    .FirstOrDefault(),
                u.CreatedAt))
            .ToListAsync();

        return Result<PaginatedResponse<CustomerListDto>>.Success(new PaginatedResponse<CustomerListDto>
        {
            Items = customers, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    public async Task<Result<CustomerDetailDto>> GetCustomerDetailAsync(Guid customerId)
    {
        var user = await _userRepo.Query()
            .FirstOrDefaultAsync(u => u.Id == customerId && u.Role == UserRole.Customer);
        if (user == null)
            return Result<CustomerDetailDto>.NotFound("Customer not found");

        // Pull the order aggregates in a single round-trip so /customers/{id}
        // stays cheap — the recent list is capped at 10 for the sidebar view.
        var orderStats = await _orderRepo.Query()
            .Where(o => o.UserId == customerId)
            .GroupBy(o => 1)
            .Select(g => new
            {
                Count = g.Count(),
                Paid = g.Where(o => o.PaymentStatus == PaymentStatus.Captured)
                        .Sum(o => (decimal?)o.TotalAmount) ?? 0m,
                First = g.Min(o => (DateTime?)o.CreatedAt),
                Last = g.Max(o => (DateTime?)o.CreatedAt),
            })
            .FirstOrDefaultAsync();

        var recent = await _orderRepo.Query()
            .Where(o => o.UserId == customerId)
            .OrderByDescending(o => o.CreatedAt)
            .Take(10)
            .Select(o => new CustomerRecentOrderDto(
                o.Id,
                o.OrderNumber,
                o.Status.ToString(),
                o.TotalAmount,
                o.Items.Sum(i => i.Quantity),
                o.CreatedAt))
            .ToListAsync();

        var count = orderStats?.Count ?? 0;
        var totalSpent = orderStats?.Paid ?? 0m;
        var avg = count > 0 ? totalSpent / count : 0m;

        return Result<CustomerDetailDto>.Success(new CustomerDetailDto(
            user.Id,
            user.Name,
            user.Phone,
            user.Email,
            user.IsStudentVerified,
            user.CoinBalance,
            count,
            totalSpent,
            avg,
            orderStats?.First,
            orderStats?.Last,
            user.CreatedAt,
            recent));
    }

    public async Task<Result<bool>> ReviewStudentVerificationAsync(Guid verificationId, ReviewStudentVerificationRequest request)
    {
        var verification = await _verificationRepo.GetByIdAsync(verificationId);
        if (verification == null) return Result<bool>.NotFound("Verification not found");

        verification.Status = request.Approved ? VerificationStatus.Approved : VerificationStatus.Rejected;
        verification.ReviewNote = request.ReviewNote;
        _verificationRepo.Update(verification);

        if (request.Approved)
        {
            var user = await _userRepo.GetByIdAsync(verification.UserId);
            if (user != null)
            {
                user.IsStudentVerified = true;
                _userRepo.Update(user);
            }
        }

        await _verificationRepo.SaveChangesAsync();

        var message = request.Approved
            ? "Your student verification has been approved! You now get student discounts."
            : $"Your student verification was rejected.{(request.ReviewNote != null ? $" Reason: {request.ReviewNote}" : "")}";
        _ = _notificationService.SendNotificationAsync(verification.UserId, "Student Verification Update", message, NotificationType.General);

        return Result<bool>.Success(true);
    }

    public async Task<Result<List<AdminSlotDto>>> GetSlotsAsync()
    {
        var slots = await _slotRepo.Query()
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.StartTime)
            .Select(s => new AdminSlotDto(
                s.Id, s.StartTime, s.EndTime,
                s.MaxOrders, s.IsActive, s.SortOrder))
            .ToListAsync();

        return Result<List<AdminSlotDto>>.Success(slots);
    }

    public async Task<Result<AdminSlotDto>> CreateSlotAsync(CreateSlotRequest request)
    {
        // Reject duplicate templates before hitting the DB's unique index
        // so the caller gets a clean error message instead of a raw SQL fault.
        var exists = await _slotRepo.Query().AnyAsync(s =>
            s.StartTime == request.StartTime &&
            s.EndTime == request.EndTime);
        if (exists)
            return Result<AdminSlotDto>.Failure("A slot with this time window already exists.");

        var slot = new PickupSlot
        {
            Id = Guid.NewGuid(),
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            MaxOrders = request.MaxOrders,
            SortOrder = request.SortOrder ?? 0,
            IsActive = true
        };

        await _slotRepo.AddAsync(slot);
        await _slotRepo.SaveChangesAsync();
        return Result<AdminSlotDto>.Success(ToAdminSlotDto(slot));
    }

    public async Task<Result<AdminSlotDto>> UpdateSlotAsync(Guid slotId, UpdateSlotRequest request)
    {
        var slot = await _slotRepo.GetByIdAsync(slotId);
        if (slot == null) return Result<AdminSlotDto>.NotFound("Slot not found");

        if (request.MaxOrders.HasValue) slot.MaxOrders = request.MaxOrders.Value;
        if (request.IsActive.HasValue) slot.IsActive = request.IsActive.Value;
        if (request.SortOrder.HasValue) slot.SortOrder = request.SortOrder.Value;

        _slotRepo.Update(slot);
        await _slotRepo.SaveChangesAsync();
        return Result<AdminSlotDto>.Success(ToAdminSlotDto(slot));
    }

    private static AdminSlotDto ToAdminSlotDto(PickupSlot s) =>
        new(s.Id, s.StartTime, s.EndTime, s.MaxOrders, s.IsActive, s.SortOrder);

    public async Task<Result<PaginatedResponse<PaymentListDto>>> GetPaymentsAsync(int page, int pageSize, string? status, string? search)
    {
        var query = _orderRepo.Query().Where(o => o.PaymentStatus != PaymentStatus.Pending);

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<PaymentStatus>(status, true, out var ps))
            query = query.Where(o => o.PaymentStatus == ps);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(o => o.OrderNumber.ToLower().Contains(term)
                || (o.RazorpayPaymentId != null && o.RazorpayPaymentId.ToLower().Contains(term)));
        }

        var totalCount = await query.CountAsync();
        var payments = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o => new PaymentListDto(
                o.Id, o.OrderNumber, o.TotalAmount,
                o.PaymentStatus.ToString(), o.RazorpayPaymentId, o.CreatedAt))
            .ToListAsync();

        return Result<PaginatedResponse<PaymentListDto>>.Success(new PaginatedResponse<PaymentListDto>
        {
            Items = payments, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    public async Task<Result<PnlDto>> GetPnlAsync(int days)
    {
        var now = DateTime.UtcNow;
        var todayStart = now.Date;
        var weekStart = todayStart.AddDays(-(int)now.DayOfWeek);
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var windowStart = todayStart.AddDays(-days + 1);

        var captured = _orderRepo.Query().Where(o => o.PaymentStatus == PaymentStatus.Captured);

        var totalRevenue = await captured.SumAsync(o => o.TotalAmount);
        var todayRevenue = await captured.Where(o => o.CreatedAt >= todayStart).SumAsync(o => o.TotalAmount);
        var weekRevenue = await captured.Where(o => o.CreatedAt >= weekStart).SumAsync(o => o.TotalAmount);
        var monthRevenue = await captured.Where(o => o.CreatedAt >= monthStart).SumAsync(o => o.TotalAmount);
        var capturedCount = await captured.CountAsync();
        var avgOrderValue = capturedCount > 0 ? totalRevenue / capturedCount : 0;

        var pendingCount = await _orderRepo.CountAsync(o => o.PaymentStatus == PaymentStatus.Pending);
        var failedCount = await _orderRepo.CountAsync(o => o.PaymentStatus == PaymentStatus.Failed);
        var refundedCount = await _orderRepo.CountAsync(o => o.PaymentStatus == PaymentStatus.Refunded);

        var totalCoinDiscount = await captured.SumAsync(o => o.CoinDiscount);
        var totalStudentDiscount = await captured.SumAsync(o => o.StudentDiscount);
        var totalAdminDiscount = await captured.SumAsync(o => o.AdminDiscount);
        var totalExpressCharge = await captured.SumAsync(o => o.ExpressCharge);

        var totalExpenses = await _expenseRepo.Query().SumAsync(e => e.Amount);
        var totalRiderPayouts = await _payoutRepo.Query()
            .Where(p => p.Status == PayoutStatus.Paid)
            .SumAsync(p => p.Amount);
        var netEarnings = totalRevenue - totalExpenses - totalRiderPayouts;

        var dailyRevenue = await captured
            .Where(o => o.CreatedAt >= windowStart)
            .GroupBy(o => o.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Revenue = g.Sum(o => o.TotalAmount), Count = g.Count() })
            .OrderBy(g => g.Date)
            .ToListAsync();

        var dailyDtos = dailyRevenue
            .Select(d => new DailyRevenueDto(DateOnly.FromDateTime(d.Date), d.Revenue, d.Count))
            .ToList();

        return Result<PnlDto>.Success(new PnlDto(
            totalRevenue, todayRevenue, weekRevenue, monthRevenue,
            capturedCount, pendingCount, failedCount, refundedCount,
            avgOrderValue,
            totalCoinDiscount, totalStudentDiscount, totalAdminDiscount, totalExpressCharge,
            totalExpenses, totalRiderPayouts, netEarnings,
            dailyDtos));
    }

    public async Task<Result<AdminOrderListResponse>> GetOrdersAsync(
        int page,
        int pageSize,
        string? search,
        string? status,
        Guid? storeId,
        string? range,
        DateTime? from,
        DateTime? to)
    {
        // Parse the optional status string into the enum. An unknown value
        // is a caller error — fail fast rather than silently returning all.
        OrderStatus? parsedStatus = null;
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (!Enum.TryParse<OrderStatus>(status, true, out var parsed))
                return Result<AdminOrderListResponse>.Failure($"Invalid status '{status}'");
            parsedStatus = parsed;
        }

        // Resolve the range token into concrete from/to timestamps. When
        // range == "custom" the caller must supply from/to directly; for
        // any other token we compute them server-side so the same policy
        // applies to every client.
        var now = DateTime.UtcNow;
        DateTime? resolvedFrom;
        DateTime? resolvedTo;
        switch ((range ?? "30d").ToLowerInvariant())
        {
            case "7d":
                resolvedFrom = now.AddDays(-7);
                resolvedTo = null;
                break;
            case "30d":
                resolvedFrom = now.AddDays(-30);
                resolvedTo = null;
                break;
            case "month":
                resolvedFrom = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                resolvedTo = null;
                break;
            case "all":
                resolvedFrom = null;
                resolvedTo = null;
                break;
            case "custom":
                // Normalize "to" to end-of-day so inclusive date picks work.
                resolvedFrom = from;
                resolvedTo = to.HasValue
                    ? DateTime.SpecifyKind(to.Value.Date.AddDays(1).AddTicks(-1), DateTimeKind.Utc)
                    : null;
                break;
            default:
                resolvedFrom = now.AddDays(-30);
                resolvedTo = null;
                break;
        }

        var (items, filteredTotal, active, delivered, cancelled) =
            await _orderRepo.SearchOrdersForAdminAsync(search, parsedStatus, storeId, resolvedFrom, resolvedTo, page, pageSize);

        var dtoItems = items.Select(o =>
        {
            // "Current rider" = the latest assignment on the order, preferring
            // an active (Delivery) leg over a completed (Pickup) leg.
            var latestAssignment = o.Assignments
                .OrderByDescending(a => a.AssignedAt)
                .FirstOrDefault();
            var riderName = latestAssignment?.Rider?.User?.Name;

            return new AdminOrderListItemDto(
                o.Id,
                o.OrderNumber,
                o.Status.ToString(),
                o.FacilityStage,
                o.PaymentStatus.ToString(),
                o.TotalAmount,
                o.Items.Sum(i => i.Quantity),
                o.UserId,
                o.User?.Name,
                o.User?.Phone ?? string.Empty,
                riderName,
                o.AssignedStoreId,
                o.AssignedStore?.Name,
                o.IsExpressDelivery,
                o.CreatedAt);
        }).ToList();

        return Result<AdminOrderListResponse>.Success(new AdminOrderListResponse(
            new PaginatedResponse<AdminOrderListItemDto>
            {
                Items = dtoItems,
                TotalCount = filteredTotal,
                Page = page,
                PageSize = pageSize
            },
            new AdminOrderStatsDto(
                All: active + delivered + cancelled,
                Active: active,
                Delivered: delivered,
                Cancelled: cancelled)));
    }

    public async Task<Result<OrderDetailDto>> GetOrderDetailForAdminAsync(Guid orderId)
    {
        // Reuses the same Include graph and AutoMapper profile as the
        // customer detail endpoint. The only difference is we skip the
        // `order.UserId == caller` guard because this path is gated by
        // the AdminOnly policy at the route level.
        var order = await _orderRepo.GetOrderWithDetailsAsync(orderId);
        if (order == null) return Result<OrderDetailDto>.NotFound("Order not found");
        return Result<OrderDetailDto>.Success(_mapper.Map<OrderDetailDto>(order));
    }

    // ============================================================
    // Riders admin
    // ============================================================

    public async Task<Result<AdminRiderListResponse>> GetRidersForAdminAsync(
        int page,
        int pageSize,
        string? search,
        string? status)
    {
        RiderStatus? parsedStatus = null;
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (!Enum.TryParse<RiderStatus>(status, true, out var s))
                return Result<AdminRiderListResponse>.Failure($"Invalid status '{status}'");
            parsedStatus = s;
        }

        // Base query — every filter but status is applied here so stats
        // reflect the filtered dataset while each tab still shows its
        // own status count.
        var baseQuery = _riderRepo.Query().Include(r => r.User).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = $"%{search.Trim()}%";
            baseQuery = baseQuery.Where(r =>
                (r.User != null && EF.Functions.ILike(r.User.Name ?? string.Empty, term)) ||
                (r.User != null && EF.Functions.ILike(r.User.Phone ?? string.Empty, term)) ||
                EF.Functions.ILike(r.VehicleNumber ?? string.Empty, term));
        }

        // Stats (filter-aware, status-agnostic) so tab counts always add up
        // to the "All" count regardless of which tab the user clicked.
        var statsGroups = await baseQuery
            .GroupBy(r => r.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync();

        var stats = new AdminRiderStatsDto(
            All: statsGroups.Sum(x => x.Count),
            Pending: statsGroups.FirstOrDefault(x => x.Status == RiderStatus.Pending)?.Count ?? 0,
            Approved: statsGroups.FirstOrDefault(x => x.Status == RiderStatus.Approved)?.Count ?? 0,
            Suspended: statsGroups.FirstOrDefault(x => x.Status == RiderStatus.Suspended)?.Count ?? 0,
            Rejected: statsGroups.FirstOrDefault(x => x.Status == RiderStatus.Rejected)?.Count ?? 0);

        // Page the query with the status filter applied.
        var filteredQuery = parsedStatus.HasValue
            ? baseQuery.Where(r => r.Status == parsedStatus.Value)
            : baseQuery;

        var total = await filteredQuery.CountAsync();
        var riders = await filteredQuery
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        // Lifetime delivery count is a cheap per-rider query. Pulled
        // in a single round-trip via a grouped sub-query.
        var riderIds = riders.Select(r => r.Id).ToList();
        var deliveryCounts = await _assignmentRepo.Query()
            .Where(a => riderIds.Contains(a.RiderId)
                && a.Type == AssignmentType.Delivery
                && a.Status == AssignmentStatus.Completed)
            .GroupBy(a => a.RiderId)
            .Select(g => new { RiderId = g.Key, Count = g.Count() })
            .ToListAsync();
        var deliveryCountMap = deliveryCounts.ToDictionary(x => x.RiderId, x => x.Count);

        var items = riders.Select(r => new AdminRiderListItemDto(
            r.Id,
            r.UserId,
            r.User?.Name,
            r.User?.Phone ?? string.Empty,
            r.VehicleNumber,
            r.Status.ToString(),
            r.IsActive,
            r.IsAvailable,
            r.TodayEarnings,
            deliveryCountMap.TryGetValue(r.Id, out var c) ? c : 0,
            r.CreatedAt,
            r.ApprovedAt)).ToList();

        return Result<AdminRiderListResponse>.Success(new AdminRiderListResponse(
            new PaginatedResponse<AdminRiderListItemDto>
            {
                Items = items,
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            },
            stats));
    }

    public async Task<Result<AdminRiderDetailDto>> GetRiderDetailForAdminAsync(Guid riderId)
    {
        var rider = await _riderRepo.Query()
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == riderId);
        if (rider == null) return Result<AdminRiderDetailDto>.NotFound("Rider not found");
        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    public async Task<Result<AdminRiderDetailDto>> CreateRiderAsync(CreateAdminRiderRequest request)
    {
        // Normalize the phone once — trim whitespace and strip spaces so
        // "+91 98765 43210" and "+919876543210" don't create duplicates.
        var phone = (request.Phone ?? string.Empty).Trim().Replace(" ", string.Empty);
        if (string.IsNullOrEmpty(phone))
            return Result<AdminRiderDetailDto>.Failure("Phone number is required.");

        var now = DateTime.UtcNow;
        var name = string.IsNullOrWhiteSpace(request.Name) ? null : request.Name.Trim();
        var vehicle = string.IsNullOrWhiteSpace(request.VehicleNumber)
            ? null
            : request.VehicleNumber.Trim();

        // Look up an existing user on this phone. Three cases:
        //   1. No user exists → create User + Rider
        //   2. User exists without a Rider row → flip role, attach a Rider
        //   3. User exists with a Rider row → reject (admin should open the
        //      existing rider's page instead of silently overwriting).
        var user = await _userRepo.Query()
            .Include(u => u.Rider)
            .FirstOrDefaultAsync(u => u.Phone == phone);

        if (user == null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                Phone = phone,
                Name = name,
                Role = UserRole.Rider,
                IsActive = true,
                // FirebaseUid is populated on first OTP login; leave blank
                // for admin-provisioned rows. ReferralCode is unused for
                // riders but the column is non-null.
                FirebaseUid = string.Empty,
                ReferralCode = string.Empty,
                CreatedAt = now,
                UpdatedAt = now,
            };
            await _userRepo.AddAsync(user);
        }
        else
        {
            if (user.Rider != null)
                return Result<AdminRiderDetailDto>.Failure(
                    "A rider already exists for this phone number.");

            user.Role = UserRole.Rider;
            if (name != null && string.IsNullOrWhiteSpace(user.Name))
                user.Name = name;
            user.UpdatedAt = now;
            _userRepo.Update(user);
        }

        var rider = new Rider
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            VehicleNumber = vehicle,
            IsActive = true,
            IsAvailable = false,
            // Admin is vouching for this rider — skip the Pending review
            // step and mark them Approved immediately with an audit trail.
            Status = RiderStatus.Approved,
            ApprovedAt = now,
            AdminNotes = request.AdminNotes,
            CreatedAt = now,
            UpdatedAt = now,
        };
        await _riderRepo.AddAsync(rider);
        await _riderRepo.SaveChangesAsync();

        rider.User = user;
        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    public async Task<Result<AdminRiderDetailDto>> ApproveRiderAsync(Guid riderId, ApproveRiderRequest request)
    {
        var rider = await _riderRepo.Query()
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == riderId);
        if (rider == null) return Result<AdminRiderDetailDto>.NotFound("Rider not found");

        if (rider.Status == RiderStatus.Rejected)
            return Result<AdminRiderDetailDto>.Failure("Rejected riders cannot be approved — create a new account.");

        rider.Status = RiderStatus.Approved;
        rider.ApprovedAt ??= DateTime.UtcNow;
        rider.SuspendedAt = null;
        rider.RejectionReason = null;
        if (request.AdminNotes != null) rider.AdminNotes = request.AdminNotes;
        rider.UpdatedAt = DateTime.UtcNow;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();

        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    public async Task<Result<AdminRiderDetailDto>> RejectRiderAsync(Guid riderId, RejectRiderRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Reason))
            return Result<AdminRiderDetailDto>.Failure("A rejection reason is required.");

        var rider = await _riderRepo.Query()
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == riderId);
        if (rider == null) return Result<AdminRiderDetailDto>.NotFound("Rider not found");

        if (rider.Status == RiderStatus.Approved)
            return Result<AdminRiderDetailDto>.Failure("Suspend an approved rider instead of rejecting.");

        rider.Status = RiderStatus.Rejected;
        rider.RejectionReason = request.Reason.Trim();
        if (request.AdminNotes != null) rider.AdminNotes = request.AdminNotes;
        rider.UpdatedAt = DateTime.UtcNow;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();

        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    public async Task<Result<AdminRiderDetailDto>> SuspendRiderAsync(Guid riderId, SuspendRiderRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Reason))
            return Result<AdminRiderDetailDto>.Failure("A suspension reason is required.");

        var rider = await _riderRepo.Query()
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == riderId);
        if (rider == null) return Result<AdminRiderDetailDto>.NotFound("Rider not found");

        if (rider.Status != RiderStatus.Approved)
            return Result<AdminRiderDetailDto>.Failure("Only approved riders can be suspended.");

        rider.Status = RiderStatus.Suspended;
        rider.SuspendedAt = DateTime.UtcNow;
        rider.RejectionReason = request.Reason.Trim();
        rider.IsAvailable = false; // pull them off the dispatch board immediately
        if (request.AdminNotes != null) rider.AdminNotes = request.AdminNotes;
        rider.UpdatedAt = DateTime.UtcNow;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();

        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    public async Task<Result<AdminRiderDetailDto>> ReinstateRiderAsync(Guid riderId)
    {
        var rider = await _riderRepo.Query()
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == riderId);
        if (rider == null) return Result<AdminRiderDetailDto>.NotFound("Rider not found");

        if (rider.Status != RiderStatus.Suspended)
            return Result<AdminRiderDetailDto>.Failure("Only suspended riders can be reinstated.");

        rider.Status = RiderStatus.Approved;
        rider.SuspendedAt = null;
        rider.RejectionReason = null;
        rider.UpdatedAt = DateTime.UtcNow;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();

        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    public async Task<Result<AdminRiderDetailDto>> UpdateRiderNotesAsync(Guid riderId, UpdateRiderNotesRequest request)
    {
        var rider = await _riderRepo.Query()
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == riderId);
        if (rider == null) return Result<AdminRiderDetailDto>.NotFound("Rider not found");

        rider.AdminNotes = request.AdminNotes;
        rider.UpdatedAt = DateTime.UtcNow;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();

        return Result<AdminRiderDetailDto>.Success(await BuildRiderDetailAsync(rider));
    }

    /// Projects a hydrated Rider into the detail DTO, computing on-the-fly
    /// aggregates (lifetime deliveries + in-flight assignment count).
    private async Task<AdminRiderDetailDto> BuildRiderDetailAsync(Rider rider)
    {
        var completedDeliveries = await _assignmentRepo.Query()
            .CountAsync(a => a.RiderId == rider.Id
                && a.Type == AssignmentType.Delivery
                && a.Status == AssignmentStatus.Completed);

        var inFlight = await _assignmentRepo.Query()
            .CountAsync(a => a.RiderId == rider.Id
                && (a.Status == AssignmentStatus.Offered
                    || a.Status == AssignmentStatus.Assigned
                    || a.Status == AssignmentStatus.Accepted
                    || a.Status == AssignmentStatus.InProgress
                    || a.Status == AssignmentStatus.InTransitToFacility));

        return new AdminRiderDetailDto(
            rider.Id,
            rider.UserId,
            rider.User?.Name,
            rider.User?.Phone ?? string.Empty,
            rider.VehicleNumber,
            rider.Status.ToString(),
            rider.IsActive,
            rider.IsAvailable,
            rider.TodayEarnings,
            completedDeliveries,
            inFlight,
            rider.CurrentLat,
            rider.CurrentLng,
            rider.LastLocationUpdate,
            rider.CreatedAt,
            rider.ApprovedAt,
            rider.SuspendedAt,
            rider.RejectionReason,
            rider.AdminNotes);
    }

    // ============================================================
    // Expenses
    // ============================================================

    public async Task<Result<PaginatedResponse<ExpenseDto>>> GetExpensesAsync(int page, int pageSize, string? category)
    {
        var query = _expenseRepo.Query().AsQueryable();
        if (!string.IsNullOrWhiteSpace(category) && Enum.TryParse<ExpenseCategory>(category, true, out var cat))
            query = query.Where(e => e.Category == cat);

        var totalCount = await query.CountAsync();
        var items = await query
            .OrderByDescending(e => e.Date).ThenByDescending(e => e.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new ExpenseDto(e.Id, e.Category.ToString(), e.Description, e.Amount, e.Date, e.Reference, e.CreatedAt))
            .ToListAsync();

        return Result<PaginatedResponse<ExpenseDto>>.Success(new PaginatedResponse<ExpenseDto>
        {
            Items = items, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    public async Task<Result<ExpenseDto>> CreateExpenseAsync(CreateExpenseRequest request)
    {
        if (!Enum.TryParse<ExpenseCategory>(request.Category, true, out var cat))
            return Result<ExpenseDto>.Failure($"Invalid category '{request.Category}'");
        if (request.Amount <= 0)
            return Result<ExpenseDto>.Failure("Amount must be greater than zero");

        var expense = new Expense
        {
            Id = Guid.NewGuid(),
            Category = cat,
            Description = request.Description,
            Amount = request.Amount,
            Date = request.Date,
            Reference = request.Reference
        };
        await _expenseRepo.AddAsync(expense);
        await _expenseRepo.SaveChangesAsync();

        return Result<ExpenseDto>.Success(new ExpenseDto(
            expense.Id, expense.Category.ToString(), expense.Description,
            expense.Amount, expense.Date, expense.Reference, expense.CreatedAt));
    }

    public async Task<Result<ExpenseDto>> UpdateExpenseAsync(Guid id, UpdateExpenseRequest request)
    {
        var expense = await _expenseRepo.GetByIdAsync(id);
        if (expense == null) return Result<ExpenseDto>.NotFound("Expense not found");

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            if (!Enum.TryParse<ExpenseCategory>(request.Category, true, out var cat))
                return Result<ExpenseDto>.Failure($"Invalid category '{request.Category}'");
            expense.Category = cat;
        }
        if (request.Description != null) expense.Description = request.Description;
        if (request.Amount is > 0) expense.Amount = request.Amount.Value;
        if (request.Date.HasValue) expense.Date = request.Date.Value;
        if (request.Reference != null) expense.Reference = request.Reference;

        _expenseRepo.Update(expense);
        await _expenseRepo.SaveChangesAsync();

        return Result<ExpenseDto>.Success(new ExpenseDto(
            expense.Id, expense.Category.ToString(), expense.Description,
            expense.Amount, expense.Date, expense.Reference, expense.CreatedAt));
    }

    public async Task<Result<bool>> DeleteExpenseAsync(Guid id)
    {
        var expense = await _expenseRepo.GetByIdAsync(id);
        if (expense == null) return Result<bool>.NotFound("Expense not found");

        _expenseRepo.Remove(expense);
        await _expenseRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    // ============================================================
    // Payouts
    // ============================================================

    public async Task<Result<PaginatedResponse<RiderPayoutDto>>> GetPayoutsAsync(int page, int pageSize, string? status)
    {
        var query = _payoutRepo.Query().Include(p => p.Rider).ThenInclude(r => r.User).AsQueryable();
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<PayoutStatus>(status, true, out var ps))
            query = query.Where(p => p.Status == ps);

        var totalCount = await query.CountAsync();
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var dtos = items.Select(p => new RiderPayoutDto(
            p.Id, p.RiderId, p.Rider.User.Name ?? "", p.Rider.User.Phone,
            p.Amount, p.DeliveryCount, p.PeriodStart, p.PeriodEnd,
            p.Status.ToString(), p.PaidAt, p.Reference, p.Notes, p.CreatedAt)).ToList();

        return Result<PaginatedResponse<RiderPayoutDto>>.Success(new PaginatedResponse<RiderPayoutDto>
        {
            Items = dtos, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    public async Task<Result<RiderPayoutDto>> CreatePayoutAsync(CreatePayoutRequest request)
    {
        var rider = await _riderRepo.Query().Include(r => r.User).FirstOrDefaultAsync(r => r.Id == request.RiderId);
        if (rider == null) return Result<RiderPayoutDto>.NotFound("Rider not found");

        var periodStartDt = request.PeriodStart.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var periodEndDt = request.PeriodEnd.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc).AddDays(1);

        var deliveryCount = await _assignmentRepo.Query()
            .CountAsync(a => a.RiderId == request.RiderId
                && a.Type == AssignmentType.Delivery
                && a.Status == AssignmentStatus.Completed
                && a.CompletedAt >= periodStartDt
                && a.CompletedAt < periodEndDt);

        var amount = deliveryCount * _riderPayPerDelivery;

        var payout = new RiderPayout
        {
            Id = Guid.NewGuid(),
            RiderId = request.RiderId,
            Amount = amount,
            DeliveryCount = deliveryCount,
            PeriodStart = request.PeriodStart,
            PeriodEnd = request.PeriodEnd,
            Status = PayoutStatus.Pending,
            Notes = request.Notes
        };
        await _payoutRepo.AddAsync(payout);
        await _payoutRepo.SaveChangesAsync();

        return Result<RiderPayoutDto>.Success(new RiderPayoutDto(
            payout.Id, payout.RiderId, rider.User.Name ?? "", rider.User.Phone,
            payout.Amount, payout.DeliveryCount, payout.PeriodStart, payout.PeriodEnd,
            payout.Status.ToString(), payout.PaidAt, payout.Reference, payout.Notes, payout.CreatedAt));
    }

    public async Task<Result<RiderPayoutDto>> UpdatePayoutStatusAsync(Guid id, UpdatePayoutStatusRequest request)
    {
        var payout = await _payoutRepo.Query().Include(p => p.Rider).ThenInclude(r => r.User)
            .FirstOrDefaultAsync(p => p.Id == id);
        if (payout == null) return Result<RiderPayoutDto>.NotFound("Payout not found");

        if (!Enum.TryParse<PayoutStatus>(request.Status, true, out var newStatus))
            return Result<RiderPayoutDto>.Failure($"Invalid status '{request.Status}'");

        payout.Status = newStatus;
        if (newStatus == PayoutStatus.Paid)
            payout.PaidAt = DateTime.UtcNow;
        if (request.Reference != null)
            payout.Reference = request.Reference;

        _payoutRepo.Update(payout);
        await _payoutRepo.SaveChangesAsync();

        return Result<RiderPayoutDto>.Success(new RiderPayoutDto(
            payout.Id, payout.RiderId, payout.Rider.User.Name ?? "", payout.Rider.User.Phone,
            payout.Amount, payout.DeliveryCount, payout.PeriodStart, payout.PeriodEnd,
            payout.Status.ToString(), payout.PaidAt, payout.Reference, payout.Notes, payout.CreatedAt));
    }

    public async Task<Result<List<RiderPayoutSummaryDto>>> GetRiderPayoutSummariesAsync(DateOnly from, DateOnly to)
    {
        var fromDt = from.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var toDt = to.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc).AddDays(1);

        var riders = await _riderRepo.Query().Include(r => r.User).Where(r => r.Status == RiderStatus.Approved).ToListAsync();
        var summaries = new List<RiderPayoutSummaryDto>();

        foreach (var rider in riders)
        {
            var completedDeliveries = await _assignmentRepo.Query()
                .CountAsync(a => a.RiderId == rider.Id
                    && a.Type == AssignmentType.Delivery
                    && a.Status == AssignmentStatus.Completed
                    && a.CompletedAt >= fromDt
                    && a.CompletedAt < toDt);

            var amountOwed = completedDeliveries * _riderPayPerDelivery;
            var amountPaid = await _payoutRepo.Query()
                .Where(p => p.RiderId == rider.Id && p.Status == PayoutStatus.Paid
                    && p.PeriodStart >= from && p.PeriodEnd <= to)
                .SumAsync(p => p.Amount);

            summaries.Add(new RiderPayoutSummaryDto(
                rider.Id, rider.User.Name ?? "", rider.User.Phone,
                completedDeliveries, amountOwed, amountPaid));
        }

        return Result<List<RiderPayoutSummaryDto>>.Success(
            summaries.Where(s => s.CompletedDeliveries > 0 || s.AmountPaid > 0)
                .OrderByDescending(s => s.AmountOwed - s.AmountPaid)
                .ToList());
    }
}
