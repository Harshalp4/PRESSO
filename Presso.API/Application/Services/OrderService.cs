namespace Presso.API.Application.Services;

using System.Security.Cryptography;
using System.Text;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Order;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;
using Presso.API.Infrastructure.Data;

public class OrderService : IOrderService
{
    private readonly IOrderRepository _orderRepo;
    private readonly IRepository<Domain.Entities.Service> _serviceRepo;
    private readonly IRepository<GarmentType> _garmentTypeRepo;
    private readonly IRepository<PickupSlot> _slotRepo;
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<CoinsLedger> _coinsRepo;
    private readonly IFirestoreService _firestoreService;
    private readonly INotificationService _notificationService;
    private readonly IReferralService _referralService;
    private readonly AppDbContext _context;
    private readonly IMapper _mapper;
    private readonly IConfiguration _config;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        IOrderRepository orderRepo,
        IRepository<Domain.Entities.Service> serviceRepo,
        IRepository<GarmentType> garmentTypeRepo,
        IRepository<PickupSlot> slotRepo,
        IRepository<User> userRepo,
        IRepository<CoinsLedger> coinsRepo,
        IFirestoreService firestoreService,
        INotificationService notificationService,
        IReferralService referralService,
        AppDbContext context,
        IMapper mapper,
        IConfiguration config,
        ILogger<OrderService> logger)
    {
        _orderRepo = orderRepo;
        _serviceRepo = serviceRepo;
        _garmentTypeRepo = garmentTypeRepo;
        _slotRepo = slotRepo;
        _userRepo = userRepo;
        _coinsRepo = coinsRepo;
        _firestoreService = firestoreService;
        _notificationService = notificationService;
        _referralService = referralService;
        _context = context;
        _mapper = mapper;
        _config = config;
        _logger = logger;
    }

    public async Task<Result<OrderDetailDto>> CreateOrderAsync(Guid userId, CreateOrderRequest request)
    {
        await using var transaction = await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.RepeatableRead);
        try
        {
            var user = await _userRepo.GetByIdAsync(userId);
            if (user == null) return Result<OrderDetailDto>.NotFound("User not found");

            // Validate address belongs to user
            var address = await _context.Addresses.FirstOrDefaultAsync(
                a => a.Id == request.AddressId && a.UserId == userId && !a.IsDeleted);
            if (address == null) return Result<OrderDetailDto>.Failure("Address not found or does not belong to user");

            // Geo-fencing: Validate address pincode is in an active service zone
            if (!string.IsNullOrEmpty(address.Pincode))
            {
                var isServiceable = await _context.ServiceZones
                    .AnyAsync(z => z.Pincode == address.Pincode && z.IsActive);
                // Only enforce if service zones exist (skip check if no zones configured yet)
                var anyZonesConfigured = await _context.ServiceZones.AnyAsync();
                if (anyZonesConfigured && !isServiceable)
                    return Result<OrderDetailDto>.Failure($"Sorry, we don't serve pincode {address.Pincode} yet. Please use an address in our service area.");
            }

            var orderNumber = await _orderRepo.GenerateOrderNumberAsync();

            // Calculate items and subtotal
            var items = new List<OrderItem>();
            decimal subTotal = 0;

            foreach (var itemReq in request.Items)
            {
                var service = await _serviceRepo.GetByIdAsync(itemReq.ServiceId);
                if (service == null) return Result<OrderDetailDto>.Failure($"Service {itemReq.ServiceId} not found");

                GarmentType? garmentType = null;
                if (itemReq.GarmentTypeId.HasValue)
                {
                    garmentType = await _garmentTypeRepo.GetByIdAsync(itemReq.GarmentTypeId.Value);
                    if (garmentType == null) return Result<OrderDetailDto>.Failure($"Garment type {itemReq.GarmentTypeId} not found");
                }

                var basePrice = garmentType?.PriceOverride ?? service.PricePerPiece;
                decimal treatmentMultiplier = 1.0m;
                string? treatmentName = null;
                Guid? treatmentId = null;

                if (itemReq.ServiceTreatmentId.HasValue)
                {
                    var treatment = await _context.ServiceTreatments.FindAsync(itemReq.ServiceTreatmentId.Value);
                    if (treatment != null && treatment.ServiceId == service.Id)
                    {
                        treatmentMultiplier = treatment.PriceMultiplier;
                        treatmentName = treatment.Name;
                        treatmentId = treatment.Id;
                    }
                }

                var price = basePrice * treatmentMultiplier;
                var itemSubtotal = price * itemReq.Quantity;
                subTotal += itemSubtotal;

                items.Add(new OrderItem
                {
                    Id = Guid.NewGuid(),
                    ServiceId = service.Id,
                    GarmentTypeId = garmentType?.Id,
                    ServiceName = service.Name,
                    GarmentTypeName = garmentType?.Name,
                    ServiceTreatmentId = treatmentId,
                    TreatmentName = treatmentName,
                    TreatmentMultiplier = treatmentMultiplier,
                    Quantity = itemReq.Quantity,
                    PricePerPiece = price,
                    Subtotal = itemSubtotal
                });
            }

            // Read discount settings from configuration
            var settings = _config.GetSection("OrderSettings");
            var coinsPerRupee = settings.GetValue<int>("CoinsPerRupee", 10);
            var maxCoinRedemptionPct = settings.GetValue<decimal>("MaxCoinRedemptionPercent", 20) / 100m;
            var studentDiscountPct = settings.GetValue<decimal>("StudentDiscountPercent", 10) / 100m;
            var expressChargePct = settings.GetValue<decimal>("ExpressChargePercent", 25) / 100m;

            // Coin redemption
            decimal coinDiscount = 0;
            int coinsRedeemed = 0;
            if (request.CoinsToRedeem > 0)
            {
                var maxCoins = (int)(subTotal * maxCoinRedemptionPct * coinsPerRupee);
                coinsRedeemed = Math.Min(request.CoinsToRedeem, Math.Min(user.CoinBalance, maxCoins));
                coinDiscount = (decimal)coinsRedeemed / coinsPerRupee;

                user.CoinBalance -= coinsRedeemed;
                _userRepo.Update(user);

                await _coinsRepo.AddAsync(new CoinsLedger
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Amount = -coinsRedeemed,
                    Type = CoinsType.Redeemed,
                    Description = $"Redeemed for order {orderNumber}"
                });
            }

            // Student discount
            decimal studentDiscount = user.IsStudentVerified ? subTotal * studentDiscountPct : 0;

            // Admin per-user custom discount
            var userDiscount = await _context.Set<UserDiscount>()
                .Where(d => d.UserId == userId && d.IsActive
                        && (d.ExpiresAt == null || d.ExpiresAt > DateTime.UtcNow)
                        && (d.UsageLimit == null || d.UsageCount < d.UsageLimit))
                .FirstOrDefaultAsync();
            decimal adminDiscountAmount = 0;
            Guid? userDiscountId = null;
            if (userDiscount != null)
            {
                adminDiscountAmount = userDiscount.Type == Domain.Enums.DiscountType.Percentage
                    ? Math.Round((subTotal - coinDiscount - studentDiscount) * userDiscount.Value / 100, 2)
                    : Math.Min(userDiscount.Value, subTotal - coinDiscount - studentDiscount);
                userDiscount.UsageCount++;
                userDiscountId = userDiscount.Id;
            }

            decimal expressCharge = request.IsExpressDelivery ? subTotal * expressChargePct : 0;
            decimal totalAmount = subTotal - coinDiscount - studentDiscount - adminDiscountAmount + expressCharge;
            totalAmount = Math.Max(totalAmount, 0);

            // Generate OTPs
            var pickupOtp = RandomNumberGenerator.GetInt32(1000, 10000).ToString("D4");
            var deliveryOtp = RandomNumberGenerator.GetInt32(1000, 10000).ToString("D4");

            // Validate the chosen pickup template + date and enforce capacity
            // by counting orders that already booked this template on this date.
            if (request.PickupSlotId.HasValue)
            {
                if (!request.PickupDate.HasValue)
                    return Result<OrderDetailDto>.Failure("Pickup date is required when a slot is selected.");

                var slot = await _slotRepo.GetByIdAsync(request.PickupSlotId.Value);
                if (slot == null) return Result<OrderDetailDto>.Failure("Pickup slot not found");
                if (!slot.IsActive) return Result<OrderDetailDto>.Failure("Pickup slot is not available");

                var booked = await _orderRepo.Query().CountAsync(o =>
                    o.PickupSlotId == slot.Id &&
                    o.PickupDate == request.PickupDate.Value &&
                    o.Status != OrderStatus.Cancelled);
                if (booked >= slot.MaxOrders)
                    return Result<OrderDetailDto>.Failure("Pickup slot is full for the selected date.");
            }

            var order = new Order
            {
                Id = Guid.NewGuid(),
                OrderNumber = orderNumber,
                UserId = userId,
                AddressId = request.AddressId,
                PickupSlotId = request.PickupSlotId,
                PickupDate = request.PickupDate,
                Status = OrderStatus.Pending,
                SubTotal = subTotal,
                CoinDiscount = coinDiscount,
                StudentDiscount = studentDiscount,
                ExpressCharge = expressCharge,
                AdminDiscount = adminDiscountAmount,
                UserDiscountId = userDiscountId,
                TotalAmount = totalAmount,
                PickupOtpHash = HashOtp(pickupOtp),
                DeliveryOtpHash = HashOtp(deliveryOtp),
                IsExpressDelivery = request.IsExpressDelivery,
                SpecialInstructions = request.SpecialInstructions,
                CoinsRedeemed = coinsRedeemed,
                Items = items
            };

            await _orderRepo.AddAsync(order);
            await _orderRepo.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("Order {OrderNumber} created for user {UserId}", orderNumber, userId);

            // Fire-and-forget Firestore update
            _ = _firestoreService.UpdateOrderStatusAsync(order.Id, order.Status.ToString(), DateTime.UtcNow);
            _ = _notificationService.SendNotificationAsync(userId, "Order Placed", $"Your order {orderNumber} has been placed successfully!", NotificationType.OrderUpdate, order.Id);

            // Reward referral on first order
            try
            {
                var priorOrderCount = await _context.Orders
                    .CountAsync(o => o.UserId == userId && o.Id != order.Id);
                if (priorOrderCount == 0)
                {
                    await _referralService.RewardReferralAsync(userId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Referral reward failed for user {UserId} — order still placed", userId);
            }

            var result = await _orderRepo.GetOrderWithDetailsAsync(order.Id);
            return Result<OrderDetailDto>.Success(_mapper.Map<OrderDetailDto>(result!));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Error creating order for user {UserId}. Detail: {Detail}", userId, ex.InnerException?.Message ?? ex.Message);
            return Result<OrderDetailDto>.Failure($"Failed to create order: {ex.InnerException?.Message ?? ex.Message}");
        }
    }

    public async Task<Result<PaginatedResponse<OrderDto>>> GetUserOrdersAsync(Guid userId, int page, int pageSize)
    {
        var orders = await _orderRepo.GetUserOrdersAsync(userId, page, pageSize);
        var totalCount = await _orderRepo.GetUserOrderCountAsync(userId);

        var response = new PaginatedResponse<OrderDto>
        {
            Items = orders.Select(o => _mapper.Map<OrderDto>(o)).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };

        return Result<PaginatedResponse<OrderDto>>.Success(response);
    }

    public async Task<Result<OrderDetailDto>> GetOrderDetailAsync(Guid orderId, Guid userId)
    {
        var order = await _orderRepo.GetOrderWithDetailsAsync(orderId);
        if (order == null) return Result<OrderDetailDto>.NotFound("Order not found");
        if (order.UserId != userId) return Result<OrderDetailDto>.Forbidden("Access denied");
        return Result<OrderDetailDto>.Success(_mapper.Map<OrderDetailDto>(order));
    }

    public async Task<Result<OrderDetailDto>> UpdateOrderStatusAsync(Guid orderId, string status)
    {
        var order = await _orderRepo.GetOrderWithDetailsAsync(orderId);
        if (order == null) return Result<OrderDetailDto>.NotFound("Order not found");

        if (!Enum.TryParse<OrderStatus>(status, true, out var newStatus))
            return Result<OrderDetailDto>.Failure("Invalid status");

        if (!IsValidStatusTransition(order.Status, newStatus))
            return Result<OrderDetailDto>.Failure($"Cannot transition from {order.Status} to {newStatus}");

        order.Status = newStatus;
        var now = DateTime.UtcNow;
        switch (newStatus)
        {
            case OrderStatus.PickedUp: order.PickedUpAt = now; break;
            case OrderStatus.PickupInProgress: order.PickupCompletedAt = now; break;
            case OrderStatus.InProcess: order.FacilityReceivedAt = now; order.ProcessingStartedAt = now; break;
            case OrderStatus.ReadyForDelivery: order.ReadyAt = now; break;
            case OrderStatus.OutForDelivery: order.OutForDeliveryAt = now; break;
        }

        if (newStatus == OrderStatus.Delivered)
        {
            order.DeliveredAt = now;
            // Award coins based on config
            var earnSettings = _config.GetSection("OrderSettings");
            var coinEarnPct = earnSettings.GetValue<decimal>("CoinEarnPercent", 2) / 100m;
            var earnCoinsPerRupee = earnSettings.GetValue<int>("CoinsPerRupee", 10);
            var coinsEarned = (int)(order.TotalAmount * coinEarnPct * earnCoinsPerRupee);
            if (coinsEarned > 0)
            {
                order.CoinsEarned = coinsEarned;
                var user = await _userRepo.GetByIdAsync(order.UserId);
                if (user != null)
                {
                    user.CoinBalance += coinsEarned;
                    _userRepo.Update(user);
                    await _coinsRepo.AddAsync(new CoinsLedger
                    {
                        Id = Guid.NewGuid(),
                        UserId = order.UserId,
                        OrderId = order.Id,
                        Amount = coinsEarned,
                        Type = CoinsType.Earned,
                        Description = $"Earned from order {order.OrderNumber}"
                    });
                }
            }
        }

        _orderRepo.Update(order);
        await _orderRepo.SaveChangesAsync();

        _ = _firestoreService.UpdateOrderStatusAsync(order.Id, order.Status.ToString(), DateTime.UtcNow);
        _ = _notificationService.SendNotificationAsync(order.UserId, "Order Update",
            $"Your order {order.OrderNumber} status: {order.Status}", NotificationType.OrderUpdate, order.Id);

        return Result<OrderDetailDto>.Success(_mapper.Map<OrderDetailDto>(order));
    }

    public async Task<Result<bool>> ConfirmPickupOtpAsync(Guid orderId, string otp)
    {
        var order = await _orderRepo.GetByIdAsync(orderId);
        if (order == null) return Result<bool>.NotFound("Order not found");
        if (order.PickupOtpHash != HashOtp(otp)) return Result<bool>.Failure("Invalid OTP");

        order.Status = OrderStatus.PickedUp;
        order.PickedUpAt = DateTime.UtcNow;
        _orderRepo.Update(order);
        await _orderRepo.SaveChangesAsync();

        _ = _firestoreService.UpdateOrderStatusAsync(order.Id, order.Status.ToString(), DateTime.UtcNow);
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> ConfirmDeliveryOtpAsync(Guid orderId, string otp)
    {
        var order = await _orderRepo.GetByIdAsync(orderId);
        if (order == null) return Result<bool>.NotFound("Order not found");
        if (order.DeliveryOtpHash != HashOtp(otp)) return Result<bool>.Failure("Invalid OTP");

        order.Status = OrderStatus.Delivered;
        order.DeliveredAt = DateTime.UtcNow;
        _orderRepo.Update(order);
        await _orderRepo.SaveChangesAsync();

        _ = _firestoreService.UpdateOrderStatusAsync(order.Id, order.Status.ToString(), DateTime.UtcNow);
        return Result<bool>.Success(true);
    }

    public async Task<Result<OrderDetailDto>> RepeatOrderAsync(Guid userId, RepeatOrderRequest request)
    {
        var original = await _orderRepo.GetOrderWithDetailsAsync(request.OriginalOrderId);
        if (original == null) return Result<OrderDetailDto>.NotFound("Original order not found");

        var items = original.Items.Select(i => new OrderItemRequest(i.ServiceId, i.GarmentTypeId, i.Quantity)).ToList();
        var createReq = new CreateOrderRequest(request.AddressId, request.PickupSlotId, request.PickupDate, items, original.IsExpressDelivery, original.SpecialInstructions, 0);
        return await CreateOrderAsync(userId, createReq);
    }

    public async Task<Result<List<SlotDto>>> GetAvailableSlotsAsync(DateOnly date)
    {
        // Pull every active template, then count existing bookings for this
        // exact date to compute remaining capacity per template.
        var templates = await _slotRepo.Query()
            .Where(s => s.IsActive)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.StartTime)
            .ToListAsync();

        var bookedCounts = await _orderRepo.Query()
            .Where(o => o.PickupDate == date && o.PickupSlotId != null && o.Status != OrderStatus.Cancelled)
            .GroupBy(o => o.PickupSlotId!.Value)
            .Select(g => new { SlotId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.SlotId, x => x.Count);

        var dtos = templates
            .Select(s =>
            {
                var booked = bookedCounts.TryGetValue(s.Id, out var c) ? c : 0;
                var available = Math.Max(0, s.MaxOrders - booked);
                return new SlotDto(s.Id, date, s.StartTime, s.EndTime, available);
            })
            .Where(d => d.Available > 0)
            .ToList();

        return Result<List<SlotDto>>.Success(dtos);
    }

    private static readonly Dictionary<OrderStatus, OrderStatus[]> ValidTransitions = new()
    {
        [OrderStatus.Pending] = [OrderStatus.Confirmed, OrderStatus.RiderAssigned, OrderStatus.Cancelled],
        [OrderStatus.Confirmed] = [OrderStatus.RiderAssigned, OrderStatus.Cancelled],
        [OrderStatus.RiderAssigned] = [OrderStatus.PickupInProgress, OrderStatus.Cancelled],
        [OrderStatus.PickupInProgress] = [OrderStatus.PickedUp],
        [OrderStatus.PickedUp] = [OrderStatus.InProcess],
        [OrderStatus.InProcess] = [OrderStatus.ReadyForDelivery],
        [OrderStatus.ReadyForDelivery] = [OrderStatus.OutForDelivery],
        [OrderStatus.OutForDelivery] = [OrderStatus.Delivered],
        [OrderStatus.Delivered] = [],
        [OrderStatus.Cancelled] = []
    };

    private static bool IsValidStatusTransition(OrderStatus current, OrderStatus next)
        => ValidTransitions.TryGetValue(current, out var allowed) && allowed.Contains(next);

    private static string HashOtp(string otp)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(otp));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
