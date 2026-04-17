namespace Presso.API.Application.Services;

using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Rider;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public class RiderService : IRiderService
{
    private readonly IRepository<Rider> _riderRepo;
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<OrderAssignment> _assignmentRepo;
    private readonly IRepository<Order> _orderRepo;
    private readonly IFirestoreService _firestoreService;
    private readonly IAzureBlobService _blobService;
    private readonly IMapper _mapper;
    private readonly decimal _riderPayPerDelivery;
    private readonly int _offerWindowSeconds;

    // Assignment statuses that "occupy" an order and block new offers being created.
    // Cancelled, Expired, Declined are "dead" and allow re-offering.
    // InTransitToFacility: rider is carrying the order back — still active.
    private static readonly AssignmentStatus[] _activeStatuses =
    {
        AssignmentStatus.Offered,
        AssignmentStatus.Assigned,
        AssignmentStatus.Accepted,
        AssignmentStatus.InProgress,
        AssignmentStatus.Completed,
        AssignmentStatus.InTransitToFacility
    };

    public RiderService(
        IRepository<Rider> riderRepo,
        IRepository<User> userRepo,
        IRepository<OrderAssignment> assignmentRepo,
        IRepository<Order> orderRepo,
        IFirestoreService firestoreService,
        IAzureBlobService blobService,
        IMapper mapper,
        IConfiguration config)
    {
        _riderRepo = riderRepo;
        _userRepo = userRepo;
        _assignmentRepo = assignmentRepo;
        _orderRepo = orderRepo;
        _firestoreService = firestoreService;
        _blobService = blobService;
        _mapper = mapper;
        _riderPayPerDelivery = config.GetValue<decimal>("OrderSettings:RiderPayPerDelivery", 30);
        _offerWindowSeconds = config.GetValue<int>("OrderSettings:RiderOfferSeconds", 60);
    }

    // Blob storage container is private — raw URLs return 401 to anonymous
    // clients (including Flutter's Image.network). Wrap each URL in a
    // time-limited SAS token so the images render on the rider's device.
    private List<string> ToSasUrls(List<string>? urls)
    {
        if (urls == null || urls.Count == 0) return new List<string>();
        return urls.Select(u => _blobService.GenerateSasUrl(u, 60)).ToList();
    }

    public async Task<Result<List<RiderDto>>> GetAllRidersAsync()
    {
        var riders = await _riderRepo.Query().Include(r => r.User).ToListAsync();
        return Result<List<RiderDto>>.Success(riders.Select(r => _mapper.Map<RiderDto>(r)).ToList());
    }

    public async Task<Result<RiderDto>> CreateRiderAsync(CreateRiderRequest request)
    {
        var user = await _userRepo.GetByIdAsync(request.UserId);
        if (user == null) return Result<RiderDto>.NotFound("User not found");

        user.Role = UserRole.Rider;
        _userRepo.Update(user);

        var rider = new Rider
        {
            Id = Guid.NewGuid(),
            UserId = request.UserId,
            VehicleNumber = request.VehicleNumber,
            IsActive = true
        };

        await _riderRepo.AddAsync(rider);
        await _riderRepo.SaveChangesAsync();

        rider.User = user;
        return Result<RiderDto>.Success(_mapper.Map<RiderDto>(rider));
    }

    public async Task<Result<bool>> UpdateAvailabilityAsync(Guid riderId, bool isAvailable)
    {
        var rider = await _riderRepo.GetByIdAsync(riderId);
        if (rider == null) return Result<bool>.NotFound("Rider not found");

        rider.IsAvailable = isAvailable;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> UpdateLocationAsync(Guid riderId, LocationUpdateRequest request)
    {
        var rider = await _riderRepo.GetByIdAsync(riderId);
        if (rider == null) return Result<bool>.NotFound("Rider not found");

        rider.CurrentLat = request.Lat;
        rider.CurrentLng = request.Lng;
        rider.LastLocationUpdate = DateTime.UtcNow;
        _riderRepo.Update(rider);
        await _riderRepo.SaveChangesAsync();

        _ = _firestoreService.UpdateRiderLocationAsync(riderId, request.Lat, request.Lng);
        return Result<bool>.Success(true);
    }

    public async Task<Result<RiderJobsResponseDto>> GetRiderJobsAsync(
        Guid riderId,
        string? search = null,
        DateOnly? date = null)
    {
        // Step 1: lazy-expire any Offered assignments whose window has passed. This
        // runs cheaply on every rider fetch so we don't need a background worker.
        await ExpireStaleOffersAsync();

        // Step 2: auto-dispatch. Any order needing pickup/delivery that has no
        // currently-active assignment gets offered to the requesting rider.
        // Cancelled/Expired/Declined assignments are treated as "dead" and allow re-offering.
        var pickupStatuses = new[] { OrderStatus.Pending, OrderStatus.Confirmed, OrderStatus.RiderAssigned };
        var deliveryStatuses = new[] { OrderStatus.ReadyForDelivery };

        var unassignedPickups = await _orderRepo.Query()
            .Where(o => pickupStatuses.Contains(o.Status)
                && !o.Assignments.Any(a => a.Type == AssignmentType.Pickup && _activeStatuses.Contains(a.Status)))
            .ToListAsync();

        var unassignedDeliveries = await _orderRepo.Query()
            .Where(o => deliveryStatuses.Contains(o.Status)
                && !o.Assignments.Any(a => a.Type == AssignmentType.Delivery && _activeStatuses.Contains(a.Status)))
            .ToListAsync();

        var now = DateTime.UtcNow;
        var expiresAt = now.AddSeconds(_offerWindowSeconds);
        foreach (var o in unassignedPickups)
        {
            await _assignmentRepo.AddAsync(new OrderAssignment
            {
                Id = Guid.NewGuid(),
                OrderId = o.Id,
                RiderId = riderId,
                Type = AssignmentType.Pickup,
                Status = AssignmentStatus.Offered,
                AssignedAt = now,
                OfferExpiresAt = expiresAt,
                CreatedAt = now,
                UpdatedAt = now
            });
        }
        foreach (var o in unassignedDeliveries)
        {
            await _assignmentRepo.AddAsync(new OrderAssignment
            {
                Id = Guid.NewGuid(),
                OrderId = o.Id,
                RiderId = riderId,
                Type = AssignmentType.Delivery,
                Status = AssignmentStatus.Offered,
                AssignedAt = now,
                OfferExpiresAt = expiresAt,
                CreatedAt = now,
                UpdatedAt = now
            });
        }
        if (unassignedPickups.Count > 0 || unassignedDeliveries.Count > 0)
        {
            await _assignmentRepo.SaveChangesAsync();
        }

        // Step 3: load this rider's active assignments with all the rich data the app needs.
        // Also include Completed/ReceivedAtFacility pickups whose order hasn't been
        // delivered yet — those feed the "At Facility" tab so the rider has
        // read-only visibility of in-flight pickups currently being processed.
        var query = _assignmentRepo.Query()
            .Where(a => a.RiderId == riderId
                && (a.Status == AssignmentStatus.Offered
                    || a.Status == AssignmentStatus.Assigned
                    || a.Status == AssignmentStatus.Accepted
                    || a.Status == AssignmentStatus.InProgress
                    || a.Status == AssignmentStatus.InTransitToFacility
                    || (a.Type == AssignmentType.Pickup
                        && (a.Status == AssignmentStatus.Completed
                            || a.Status == AssignmentStatus.ReceivedAtFacility)
                        && a.Order.Status != OrderStatus.Delivered
                        && a.Order.Status != OrderStatus.Cancelled)));

        // Server-side search: match against order number (case-insensitive
        // contains). Keeps the client dumb — all filtering lives here.
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(a => a.Order.OrderNumber.ToLower().Contains(term));
        }

        // Server-side date filter: match assignment.AssignedAt by calendar day.
        if (date is DateOnly d)
        {
            var dayStart = new DateTime(d.Year, d.Month, d.Day, 0, 0, 0, DateTimeKind.Utc);
            var dayEnd = dayStart.AddDays(1);
            query = query.Where(a =>
                a.AssignedAt >= dayStart && a.AssignedAt < dayEnd);
        }

        var assignments = await query
            .Include(a => a.Order).ThenInclude(o => o.User)
            .Include(a => a.Order).ThenInclude(o => o.Address)
            .Include(a => a.Order).ThenInclude(o => o.PickupSlot)
            .Include(a => a.Order).ThenInclude(o => o.Items)
            .OrderByDescending(a => a.AssignedAt)
            .ToListAsync();

        RiderAssignmentDto ToDto(OrderAssignment a) => BuildAssignmentDto(a);

        // Partition pickups by status on the server so the dashboard tabs
        // are pure render:
        //   Pickup tab     → not yet picked up
        //   To Drop tab    → picked up, rider is carrying it back (InTransit)
        //   At Facility    → dropped off, order in process at facility
        var pickupJobs = assignments
            .Where(a => a.Type == AssignmentType.Pickup
                && (a.Status == AssignmentStatus.Offered
                    || a.Status == AssignmentStatus.Assigned
                    || a.Status == AssignmentStatus.Accepted
                    || a.Status == AssignmentStatus.InProgress))
            .Select(ToDto)
            .ToList();
        var toDropJobs = assignments
            .Where(a => a.Type == AssignmentType.Pickup
                && a.Status == AssignmentStatus.InTransitToFacility)
            .Select(ToDto)
            .ToList();
        var atFacilityJobs = assignments
            .Where(a => a.Type == AssignmentType.Pickup
                && (a.Status == AssignmentStatus.Completed
                    || a.Status == AssignmentStatus.ReceivedAtFacility))
            .Select(ToDto)
            .ToList();
        var deliveryJobs = assignments
            .Where(a => a.Type == AssignmentType.Delivery)
            .Select(ToDto)
            .ToList();

        var todayStart = DateTime.UtcNow.Date;
        var completedToday = await _assignmentRepo.Query()
            .CountAsync(a => a.RiderId == riderId
                && a.Status == AssignmentStatus.Completed
                && a.CompletedAt >= todayStart);

        var pendingCount = pickupJobs.Count + toDropJobs.Count
            + atFacilityJobs.Count + deliveryJobs.Count;

        return Result<RiderJobsResponseDto>.Success(new RiderJobsResponseDto(
            pickupJobs, toDropJobs, atFacilityJobs, deliveryJobs,
            completedToday, pendingCount));
    }

    // Marks any Offered assignments whose window has passed as Expired.
    // Safe to call on every rider action — cheap guard that removes the need for a worker.
    private async Task ExpireStaleOffersAsync()
    {
        var now = DateTime.UtcNow;
        var stale = await _assignmentRepo.Query()
            .Where(a => a.Status == AssignmentStatus.Offered
                && a.OfferExpiresAt != null
                && a.OfferExpiresAt < now)
            .ToListAsync();
        if (stale.Count == 0) return;
        foreach (var a in stale)
        {
            a.Status = AssignmentStatus.Expired;
            a.UpdatedAt = now;
            _assignmentRepo.Update(a);
        }
        await _assignmentRepo.SaveChangesAsync();
    }

    // Builds the rich DTO used by every rider-assignment response so shape stays in sync.
    private RiderAssignmentDto BuildAssignmentDto(OrderAssignment a)
    {
        var order = a.Order;
        var garmentCount = order.Items?.Sum(i => i.Quantity) ?? 0;
        string? pickupSlotDisplay = null;
        if (order.PickupSlot != null)
        {
            var slot = order.PickupSlot;
            pickupSlotDisplay = order.PickupDate.HasValue
                ? $"{order.PickupDate.Value:dd MMM}, {slot.StartTime:hh\\:mm}-{slot.EndTime:hh\\:mm}"
                : $"{slot.StartTime:hh\\:mm}-{slot.EndTime:hh\\:mm}";
        }

        int? secondsRemaining = null;
        if (a.Status == AssignmentStatus.Offered && a.OfferExpiresAt is DateTime exp)
        {
            var remaining = (int)Math.Ceiling((exp - DateTime.UtcNow).TotalSeconds);
            secondsRemaining = remaining < 0 ? 0 : remaining;
        }

        decimal? payout = a.Type == AssignmentType.Delivery ? _riderPayPerDelivery : null;

        return new RiderAssignmentDto(
            a.Id,
            a.Type.ToString(),
            a.Status.ToString(),
            a.AssignedAt,
            null,
            a.CompletedAt,
            new RiderAssignmentOrderDto(
                order.Id,
                order.OrderNumber,
                order.Status.ToString(),
                garmentCount,
                null,
                order.SpecialInstructions,
                false,
                order.IsExpressDelivery,
                pickupSlotDisplay,
                ToSasUrls(order.PickupPhotoUrls),
                order.FacilityStage,
                order.FacilityReceivedAt,
                order.ProcessingStartedAt,
                order.ReadyAt,
                order.OutForDeliveryAt,
                order.DeliveredAt),
            new RiderAssignmentCustomerDto(
                order.User?.Name ?? "",
                MaskPhone(order.User?.Phone ?? "")),
            new RiderAssignmentAddressDto(
                string.IsNullOrEmpty(order.Address.Label) ? null : order.Address.Label,
                order.Address.AddressLine1,
                order.Address.AddressLine2,
                order.Address.City,
                order.Address.Pincode,
                order.Address.Lat,
                order.Address.Lng),
            a.OfferExpiresAt,
            secondsRemaining,
            payout);
    }

    // Public hook so the endpoint layer can reuse the same DTO builder.
    public RiderAssignmentDto ToAssignmentDto(OrderAssignment a) => BuildAssignmentDto(a);

    private static string MaskPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone) || phone.Length < 4) return phone;
        return new string('X', phone.Length - 4) + phone[^4..];
    }

    public async Task<Result<EarningsDto>> GetEarningsAsync(Guid riderId)
    {
        var rider = await _riderRepo.GetByIdAsync(riderId);
        if (rider == null) return Result<EarningsDto>.NotFound("Rider not found");

        var completedAssignments = await _assignmentRepo.Query()
            .Where(a => a.RiderId == riderId && a.Status == AssignmentStatus.Completed)
            .ToListAsync();

        var now = DateTime.UtcNow;
        var weekStart = now.AddDays(-(int)now.DayOfWeek);
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var weekEarnings = completedAssignments.Count(a => a.CompletedAt >= weekStart) * _riderPayPerDelivery;
        var monthEarnings = completedAssignments.Count(a => a.CompletedAt >= monthStart) * _riderPayPerDelivery;

        return Result<EarningsDto>.Success(new EarningsDto(
            rider.TodayEarnings,
            weekEarnings,
            monthEarnings,
            completedAssignments.Count));
    }
}
