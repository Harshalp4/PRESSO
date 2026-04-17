namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

/// <summary>
/// Facility (laundry processing centre) operations endpoints, consumed by the
/// Presso operations app facility role. Mirrors the wireframe screens:
///   - Dashboard list (GET /api/facility/orders)
///   - Detail (GET /api/facility/orders/{id})
///   - Status updates with sub-stage (PATCH /api/facility/orders/{id}/status)
///   - Shoe sub-status (PATCH /api/facility/orders/{id}/shoe-status) — stub
///   - Scan-to-receive (POST /api/facility/orders/scan)
///   - Stats summary (GET /api/facility/stats)
///
/// Sub-stage notes:
///   The customer-facing OrderStatus enum has a single InProcess bucket. The
///   facility wireframes show four sub-stages (AtFacility / Washing / Ironing /
///   Ready). We persist the sub-stage in Order.FacilityStage and translate
///   to/from OrderStatus on the wire so neither the customer app nor the
///   admin views need to change.
/// </summary>
public static class FacilityEndpoints
{
    private const string StageAtFacility = "AtFacility";
    private const string StageWashing = "Washing";
    private const string StageIroning = "Ironing";
    private const string StageReady = "Ready";

    private static readonly string[] AllowedStages =
        { StageAtFacility, StageWashing, StageIroning, StageReady };

    /// <summary>Effective wire status combining OrderStatus + FacilityStage.</summary>
    private static string WireStatus(Order o)
    {
        if (o.Status == OrderStatus.InProcess && !string.IsNullOrEmpty(o.FacilityStage))
            return o.FacilityStage!;
        if (o.Status == OrderStatus.ReadyForDelivery)
            return StageReady;
        return o.Status.ToString();
    }

    public static RouteGroupBuilder MapFacilityEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/facility").WithTags("Facility").RequireAuthorization();

        // GET /api/facility/orders?date=YYYY-MM-DD&storeId=...
        // Returns the list of orders currently relevant to the facility — anything
        // from PickedUp through ReadyForDelivery (i.e. in the four-bucket flow).
        group.MapGet("/orders", async (
            IRepository<Order> orderRepo,
            string? storeId,
            string? date,
            string? status) =>
        {
            // "active" (default) = orders the facility is currently working on.
            // "completed" = orders that have left the facility floor
            //   (handed to rider for delivery or already delivered), so staff
            //   can audit what they shipped today.
            var isCompleted = string.Equals(status, "completed", StringComparison.OrdinalIgnoreCase);
            var activeStatuses = new[]
            {
                OrderStatus.PickedUp,
                OrderStatus.InProcess,
                OrderStatus.ReadyForDelivery,
            };
            var completedStatuses = new[]
            {
                OrderStatus.OutForDelivery,
                OrderStatus.Delivered,
            };
            var bucket = isCompleted ? completedStatuses : activeStatuses;

            var query = orderRepo.Query()
                .Where(o => bucket.Contains(o.Status));

            if (!string.IsNullOrWhiteSpace(storeId) && Guid.TryParse(storeId, out var storeGuid))
            {
                query = query.Where(o => o.AssignedStoreId == storeGuid);
            }

            if (!string.IsNullOrWhiteSpace(date) && DateTime.TryParse(date, out var dayLocal))
            {
                var dayStart = DateTime.SpecifyKind(dayLocal.Date, DateTimeKind.Utc);
                var dayEnd = dayStart.AddDays(1);
                query = query.Where(o =>
                    (o.FacilityReceivedAt ?? o.PickupCompletedAt ?? o.CreatedAt) >= dayStart &&
                    (o.FacilityReceivedAt ?? o.PickupCompletedAt ?? o.CreatedAt) < dayEnd);
            }

            var orders = await query
                .Include(o => o.User)
                .Include(o => o.Items)
                .OrderByDescending(o => o.UpdatedAt)
                .Take(200)
                .ToListAsync();

            var list = orders.Select(o => (object)new
            {
                id = o.Id,
                orderNumber = o.OrderNumber,
                customerName = o.User?.Name ?? "Customer",
                garmentCount = o.Items?.Sum(i => i.Quantity) ?? 0,
                serviceNames = o.Items?.Select(i => i.ServiceName)
                    .Where(s => !string.IsNullOrEmpty(s)).Distinct().ToList()
                    ?? new List<string>(),
                status = WireStatus(o),
                statusUpdatedAt = o.UpdatedAt,
                hasShoeItems = false,
                specialInstructions = o.SpecialInstructions,
                facilityNotes = o.FacilityNotes,
                isExpressDelivery = o.IsExpressDelivery,
            }).ToList();

            return Result<List<object>>.Success(list).ToResult();
        });

        // GET /api/facility/orders/{id}
        group.MapGet("/orders/{id:guid}", async (
            Guid id,
            IRepository<Order> orderRepo,
            IAzureBlobService blobService) =>
        {
            var order = await orderRepo.Query()
                .Where(o => o.Id == id)
                .Include(o => o.User)
                .Include(o => o.Items)
                .Include(o => o.PickupSlot)
                .FirstOrDefaultAsync();

            if (order == null) return Result<object>.NotFound("Order not found").ToResult();

            return Result<object>.Success(BuildDetail(order, blobService)).ToResult();
        });

        // PATCH /api/facility/orders/{id}/status
        // Body: { status: "AtFacility"|"Washing"|"Ironing"|"Ready", notes?: string }
        // Translates the facility sub-stage to the underlying OrderStatus and
        // stamps the appropriate timestamp.
        group.MapPatch("/orders/{id:guid}/status", async (
            Guid id,
            FacilityStatusUpdateRequest request,
            IRepository<Order> orderRepo) =>
        {
            if (string.IsNullOrWhiteSpace(request.Status) ||
                !AllowedStages.Contains(request.Status, StringComparer.OrdinalIgnoreCase))
            {
                return Result<object>.Failure(
                    $"Invalid status. Allowed: {string.Join(", ", AllowedStages)}").ToResult();
            }

            var order = await orderRepo.GetByIdAsync(id);
            if (order == null) return Result<object>.NotFound("Order not found").ToResult();

            var stage = AllowedStages.First(s => string.Equals(s, request.Status, StringComparison.OrdinalIgnoreCase));
            var now = DateTime.UtcNow;

            switch (stage)
            {
                case StageAtFacility:
                    order.Status = OrderStatus.InProcess;
                    order.FacilityStage = StageAtFacility;
                    order.FacilityReceivedAt ??= now;
                    break;
                case StageWashing:
                    order.Status = OrderStatus.InProcess;
                    order.FacilityStage = StageWashing;
                    order.ProcessingStartedAt ??= now;
                    break;
                case StageIroning:
                    order.Status = OrderStatus.InProcess;
                    order.FacilityStage = StageIroning;
                    order.ProcessingStartedAt ??= now;
                    break;
                case StageReady:
                    order.Status = OrderStatus.ReadyForDelivery;
                    order.FacilityStage = StageReady;
                    order.ReadyAt ??= now;
                    break;
            }

            if (!string.IsNullOrWhiteSpace(request.Notes))
            {
                order.FacilityNotes = request.Notes;
            }
            order.UpdatedAt = now;
            orderRepo.Update(order);
            await orderRepo.SaveChangesAsync();

            return Result<object>.Success(new { id = order.Id, status = WireStatus(order) }).ToResult();
        });

        // PATCH /api/facility/orders/{id}/shoe-status
        // Stub — shoe items aren't modeled in the schema yet. Accepts the call
        // and returns 200 so the operations app doesn't break, but does nothing.
        group.MapPatch("/orders/{id:guid}/shoe-status", async (
            Guid id,
            FacilityShoeStatusRequest request,
            IRepository<Order> orderRepo) =>
        {
            var order = await orderRepo.GetByIdAsync(id);
            if (order == null) return Result<object>.NotFound("Order not found").ToResult();
            await Task.CompletedTask;
            return Result<object>.Success(new { id = order.Id, shoeItemId = request.ShoeItemId, status = request.Status, persisted = false }).ToResult();
        });

        // POST /api/facility/drop/verify { otp: "4729" }
        // Facility-side half of the rider→facility drop-off handshake.
        // The rider tapped "Drop at Facility" and their phone now shows a
        // 4-digit OTP. Facility staff types it here. On success:
        //   - assignment.Status → ReceivedAtFacility (removes it from rider's "To Drop" list)
        //   - assignment.CompletedAt stamped (rider's job is done)
        //   - order.Status → InProcess + FacilityStage = AtFacility
        //   - DropOtp cleared so a stale code can't be replayed
        group.MapPost("/drop/verify", async (
            FacilityDropVerifyRequest request,
            IRepository<OrderAssignment> assignmentRepo,
            IRepository<Order> orderRepo,
            IAzureBlobService blobService,
            IRealtimePusher pusher) =>
        {
            if (string.IsNullOrWhiteSpace(request.Otp) || request.Otp.Length != 4)
                return Result<object>.Failure("A 4-digit OTP is required").ToResult();

            var now = DateTime.UtcNow;

            // Match on OTP + status + unexpired. We scope to
            // InTransitToFacility so a reused/stale code from a past
            // assignment can't accidentally verify. If two assignments
            // happen to collide on the same 4-digit code in the same
            // 5-minute window (1 in 10,000), we take the earliest.
            var assignment = await assignmentRepo.Query()
                .Where(a => a.DropOtp == request.Otp
                    && a.Status == AssignmentStatus.InTransitToFacility
                    && a.DropOtpExpiresAt != null
                    && a.DropOtpExpiresAt > now)
                .OrderBy(a => a.DropOtpExpiresAt)
                .FirstOrDefaultAsync();

            if (assignment == null)
                return Result<object>.Failure("Invalid or expired code").ToResult();

            var order = await orderRepo.Query()
                .Where(o => o.Id == assignment.OrderId)
                .Include(o => o.User)
                .Include(o => o.Items)
                .Include(o => o.PickupSlot)
                .FirstOrDefaultAsync();
            if (order == null)
                return Result<object>.NotFound("Order not found").ToResult();

            assignment.Status = AssignmentStatus.ReceivedAtFacility;
            assignment.DroppedAtFacilityAt = now;
            assignment.CompletedAt = now;
            assignment.DropOtp = null;
            assignment.DropOtpExpiresAt = null;
            assignment.UpdatedAt = now;
            assignmentRepo.Update(assignment);

            order.Status = OrderStatus.InProcess;
            order.FacilityStage = StageAtFacility;
            order.FacilityReceivedAt ??= now;
            order.UpdatedAt = now;
            orderRepo.Update(order);

            await orderRepo.SaveChangesAsync();

            // Realtime nudge to every connected facility client so the new
            // bag pops into their queue immediately instead of waiting for
            // the next poll. Fire-and-forget — failures here must not block
            // the drop-off response.
            _ = pusher.PushToRoleAsync("FacilityStaff", "ReceiveNotification", new
            {
                title = $"New bag received: #{order.OrderNumber}",
                body = $"{order.User?.Name ?? "Customer"} · pickup dropped at facility",
                type = "OrderReceivedAtFacility",
                orderId = order.Id,
                orderNumber = order.OrderNumber,
            });

            return Result<object>.Success(BuildDetail(order, blobService)).ToResult();
        });

        // POST /api/facility/orders/{id}/reset-to-ready — recovery action.
        // Pulls a delivery back into the facility Ready bucket when it has
        // drifted into OutForDelivery prematurely (e.g. a rider tapped
        // Arrived before actually collecting the bag). Cancels any active
        // Delivery assignment so the facility can re-dispatch cleanly.
        group.MapPost("/orders/{id:guid}/reset-to-ready", async (
            Guid id,
            IRepository<Order> orderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IAzureBlobService blobService) =>
        {
            var order = await orderRepo.Query()
                .Where(o => o.Id == id)
                .Include(o => o.User)
                .Include(o => o.Items)
                .Include(o => o.PickupSlot)
                .FirstOrDefaultAsync();
            if (order == null) return Result<object>.NotFound("Order not found").ToResult();

            // Only recover from post-ready states; refuse to rewind once
            // the bag has actually been delivered.
            if (order.Status == OrderStatus.Delivered)
                return Result<object>.Failure("Order already delivered; cannot reset.").ToResult();

            var now = DateTime.UtcNow;
            order.Status = OrderStatus.ReadyForDelivery;
            order.FacilityStage = StageReady;
            order.ReadyAt ??= now;
            order.OutForDeliveryAt = null;
            order.UpdatedAt = now;
            orderRepo.Update(order);

            var activeDeliveries = await assignmentRepo.Query()
                .Where(a => a.OrderId == order.Id
                    && a.Type == AssignmentType.Delivery
                    && a.Status != AssignmentStatus.Completed
                    && a.Status != AssignmentStatus.Cancelled
                    && a.Status != AssignmentStatus.Expired
                    && a.Status != AssignmentStatus.Declined)
                .ToListAsync();
            foreach (var a in activeDeliveries)
            {
                a.Status = AssignmentStatus.Cancelled;
                a.UpdatedAt = now;
                assignmentRepo.Update(a);
            }

            await orderRepo.SaveChangesAsync();

            return Result<object>.Success(BuildDetail(order, blobService)).ToResult();
        });

        // POST /api/facility/orders/scan { orderNumber: "PRX..." }
        // Look up by order number; if currently PickedUp, transition to InProcess/AtFacility.
        group.MapPost("/orders/scan", async (
            FacilityScanRequest request,
            IRepository<Order> orderRepo,
            IAzureBlobService blobService) =>
        {
            if (string.IsNullOrWhiteSpace(request.OrderNumber))
                return Result<object>.Failure("orderNumber is required").ToResult();

            var order = await orderRepo.Query()
                .Where(o => o.OrderNumber == request.OrderNumber)
                .Include(o => o.User)
                .Include(o => o.Items)
                .Include(o => o.PickupSlot)
                .FirstOrDefaultAsync();

            if (order == null) return Result<object>.NotFound("Order not found").ToResult();

            if (order.Status == OrderStatus.PickedUp)
            {
                order.Status = OrderStatus.InProcess;
                order.FacilityStage = StageAtFacility;
                order.FacilityReceivedAt ??= DateTime.UtcNow;
                order.UpdatedAt = DateTime.UtcNow;
                orderRepo.Update(order);
                await orderRepo.SaveChangesAsync();
            }

            return Result<object>.Success(BuildDetail(order, blobService)).ToResult();
        });

        // GET /api/facility/stats — counts for the four-bucket dashboard.
        group.MapGet("/stats", async (IRepository<Order> orderRepo) =>
        {
            var todayStart = DateTime.UtcNow.Date;

            var inProcessOrders = await orderRepo.Query()
                .Where(o => o.Status == OrderStatus.InProcess)
                .Select(o => new { o.FacilityStage, o.FacilityReceivedAt, o.ReadyAt })
                .ToListAsync();

            // "At Facility" also includes raw PickedUp orders — the rider has
            // dropped the bag but the facility hasn't scanned it in yet. They
            // were falling through the cracks (visible in the list but not in
            // any stat bucket) which made the dashboard numbers look wrong.
            var pickedUpCount = await orderRepo.Query()
                .CountAsync(o => o.Status == OrderStatus.PickedUp);
            var atFacility = pickedUpCount + inProcessOrders.Count(o =>
                o.FacilityStage == StageAtFacility || string.IsNullOrEmpty(o.FacilityStage));
            var washing = inProcessOrders.Count(o => o.FacilityStage == StageWashing);
            var ironing = inProcessOrders.Count(o => o.FacilityStage == StageIroning);

            var ready = await orderRepo.Query()
                .CountAsync(o => o.Status == OrderStatus.ReadyForDelivery);

            var deliveredToday = await orderRepo.Query()
                .CountAsync(o => o.Status == OrderStatus.Delivered
                    && o.DeliveredAt != null
                    && o.DeliveredAt >= todayStart);

            // Avg processing time (hours) over orders delivered in the last 7 days.
            var weekAgo = DateTime.UtcNow.AddDays(-7);
            var recent = await orderRepo.Query()
                .Where(o => o.DeliveredAt != null && o.DeliveredAt >= weekAgo
                    && o.FacilityReceivedAt != null && o.ReadyAt != null)
                .Select(o => new { o.FacilityReceivedAt, o.ReadyAt })
                .ToListAsync();

            double avgProcessingHours = 0;
            if (recent.Count > 0)
            {
                avgProcessingHours = recent
                    .Average(r => (r.ReadyAt!.Value - r.FacilityReceivedAt!.Value).TotalHours);
            }

            return Result<object>.Success(new
            {
                atFacility,
                washing,
                ironing,
                ready,
                deliveredToday,
                avgProcessingHours = Math.Round(avgProcessingHours, 1),
            }).ToResult();
        });

        // GET /api/facility/nearest?lat&lng — wireframe screen 7 "Drop at facility".
        // Returns the nearest active store location (or the first active one if no
        // coordinates are supplied).
        group.MapGet("/nearest", async (
            double? lat,
            double? lng,
            IRepository<StoreLocation> storeRepo) =>
        {
            var stores = await storeRepo.Query()
                .Where(s => s.IsActive)
                .ToListAsync();
            if (stores.Count == 0)
                return Result<object>.NotFound("No facility available").ToResult();

            StoreLocation nearest;
            double? distanceKm = null;
            if (lat.HasValue && lng.HasValue)
            {
                nearest = stores
                    .OrderBy(s => HaversineKm(lat.Value, lng.Value, s.Latitude, s.Longitude))
                    .First();
                distanceKm = HaversineKm(lat.Value, lng.Value, nearest.Latitude, nearest.Longitude);
            }
            else
            {
                nearest = stores[0];
            }

            return Result<object>.Success(new
            {
                id = nearest.Id,
                name = nearest.Name,
                addressLine1 = nearest.AddressLine1,
                addressLine2 = nearest.AddressLine2,
                latitude = nearest.Latitude,
                longitude = nearest.Longitude,
                isOpen = true, // Always "OPEN" for now per wireframe
                hours = "24/7",
                distanceKm,
                etaMinutes = distanceKm.HasValue ? (int)Math.Ceiling(distanceKm.Value / 0.4) : (int?)null,
            }).ToResult();
        });

        // GET /api/facility/orders/{id}/suggested-rider — wireframe screen 14 "Dispatch".
        // Returns the nearest online & available rider for the facility to dispatch this
        // delivery to. Distance is measured from the order's AssignedStore (or the rider's
        // current location if the store has no coordinates).
        group.MapGet("/orders/{id:guid}/suggested-rider", async (
            Guid id,
            IRepository<Order> orderRepo,
            IRepository<Rider> riderRepo,
            IRepository<StoreLocation> storeRepo) =>
        {
            var order = await orderRepo.GetByIdAsync(id);
            if (order == null) return Result<object>.NotFound("Order not found").ToResult();

            double? refLat = null, refLng = null;
            if (order.AssignedStoreId is Guid sid)
            {
                var store = await storeRepo.GetByIdAsync(sid);
                if (store != null) { refLat = store.Latitude; refLng = store.Longitude; }
            }

            var candidates = await riderRepo.Query()
                .Include(r => r.User)
                .Where(r => r.IsActive && r.IsAvailable
                    && r.CurrentLat != null && r.CurrentLng != null)
                .ToListAsync();

            if (candidates.Count == 0)
                return Result<object>.NotFound("No online rider available").ToResult();

            Rider best;
            double? bestDistance = null;
            if (refLat.HasValue && refLng.HasValue)
            {
                best = candidates
                    .OrderBy(r => HaversineKm(refLat.Value, refLng.Value, r.CurrentLat!.Value, r.CurrentLng!.Value))
                    .First();
                bestDistance = HaversineKm(refLat.Value, refLng.Value, best.CurrentLat!.Value, best.CurrentLng!.Value);
            }
            else
            {
                best = candidates[0];
            }

            return Result<object>.Success(new
            {
                id = best.Id,
                name = best.User?.Name ?? "Rider",
                phone = best.User?.Phone ?? "",
                rating = 4.8, // Not modeled yet — wireframe shows a static rating.
                distanceKm = bestDistance,
                isOnline = true,
            }).ToResult();
        });

        // POST /api/facility/orders/{id}/dispatch { riderId } — wireframe screen 14.
        // Creates a Delivery OrderAssignment with Status=Offered so the rider sees
        // an offer screen with a 60s countdown. OrderStatus stays ReadyForDelivery
        // until the rider actually accepts.
        group.MapPost("/orders/{id:guid}/dispatch", async (
            Guid id,
            FacilityDispatchRequest request,
            IRepository<Order> orderRepo,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IConfiguration config) =>
        {
            var order = await orderRepo.GetByIdAsync(id);
            if (order == null) return Result<object>.NotFound("Order not found").ToResult();

            // Accept either the four-bucket "Ready" sub-stage or the underlying status.
            var readyForDispatch =
                order.Status == OrderStatus.ReadyForDelivery ||
                (order.Status == OrderStatus.InProcess && order.FacilityStage == StageReady);
            if (!readyForDispatch)
                return Result<object>.Failure($"Order is not ready for dispatch (status={order.Status}).").ToResult();

            var rider = await riderRepo.GetByIdAsync(request.RiderId);
            if (rider == null) return Result<object>.NotFound("Rider not found").ToResult();

            // Guard: don't create a second active Delivery assignment for the same order.
            var existing = await assignmentRepo.Query()
                .AnyAsync(a => a.OrderId == order.Id
                    && a.Type == AssignmentType.Delivery
                    && (a.Status == AssignmentStatus.Offered
                        || a.Status == AssignmentStatus.Accepted
                        || a.Status == AssignmentStatus.InProgress
                        || a.Status == AssignmentStatus.Completed));
            if (existing)
                return Result<object>.Failure("A delivery is already in flight for this order.").ToResult();

            var now = DateTime.UtcNow;
            var offerSeconds = config.GetValue<int>("OrderSettings:RiderOfferSeconds", 60);
            var assignment = new OrderAssignment
            {
                Id = Guid.NewGuid(),
                OrderId = order.Id,
                RiderId = rider.Id,
                Type = AssignmentType.Delivery,
                Status = AssignmentStatus.Offered,
                AssignedAt = now,
                OfferExpiresAt = now.AddSeconds(offerSeconds),
                CreatedAt = now,
                UpdatedAt = now,
            };
            await assignmentRepo.AddAsync(assignment);

            // Promote order to ReadyForDelivery (in case it was still in the InProcess/Ready bucket).
            if (order.Status == OrderStatus.InProcess)
            {
                order.Status = OrderStatus.ReadyForDelivery;
                order.ReadyAt ??= now;
                order.UpdatedAt = now;
                orderRepo.Update(order);
            }

            await assignmentRepo.SaveChangesAsync();

            return Result<object>.Success(new
            {
                assignmentId = assignment.Id,
                riderId = rider.Id,
                offerExpiresAt = assignment.OfferExpiresAt,
                secondsRemaining = offerSeconds,
            }).ToResult();
        });

        return group;
    }

    private static double HaversineKm(double lat1, double lng1, double lat2, double lng2)
    {
        const double R = 6371.0; // km
        double dLat = (lat2 - lat1) * Math.PI / 180;
        double dLng = (lng2 - lng1) * Math.PI / 180;
        double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                   Math.Cos(lat1 * Math.PI / 180) * Math.Cos(lat2 * Math.PI / 180) *
                   Math.Sin(dLng / 2) * Math.Sin(dLng / 2);
        return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static object BuildDetail(Order order, IAzureBlobService blobService)
    {
        var items = (order.Items ?? new List<OrderItem>()).Select(i => (object)new
        {
            serviceName = i.ServiceName,
            garmentTypeName = i.GarmentTypeName ?? "",
            quantity = i.Quantity,
            pricePerPiece = i.PricePerPiece,
            subtotal = i.Subtotal,
            treatmentName = i.TreatmentName,
        }).ToList();

        string? pickupSlotDisplay = null;
        if (order.PickupSlot != null)
        {
            var slot = order.PickupSlot;
            pickupSlotDisplay = order.PickupDate.HasValue
                ? $"{order.PickupDate.Value:dd MMM}, {slot.StartTime:hh\\:mm}-{slot.EndTime:hh\\:mm}"
                : $"{slot.StartTime:hh\\:mm}-{slot.EndTime:hh\\:mm}";
        }

        var timeline = new List<object>();
        void AddIf(DateTime? ts, string status, string? note = null)
        {
            if (ts.HasValue) timeline.Add(new { status, timestamp = ts.Value, note });
        }
        AddIf(order.CreatedAt, "Created");
        AddIf(order.PickupCompletedAt, "PickedUp");
        AddIf(order.FacilityReceivedAt, StageAtFacility);
        AddIf(order.ProcessingStartedAt, order.FacilityStage ?? StageWashing);
        AddIf(order.ReadyAt, StageReady);
        AddIf(order.OutForDeliveryAt, "OutForDelivery");
        AddIf(order.DeliveredAt, "Delivered");

        return new
        {
            id = order.Id,
            orderNumber = order.OrderNumber,
            customerName = order.User?.Name ?? "Customer",
            status = WireStatus(order),
            createdAt = order.CreatedAt,
            specialInstructions = order.SpecialInstructions,
            facilityNotes = order.FacilityNotes,
            hasShoeItems = false,
            isExpressDelivery = order.IsExpressDelivery,
            garmentCount = order.Items?.Sum(i => i.Quantity) ?? 0,
            items,
            shoeItems = new List<object>(),
            pickupPhotoUrls = (order.PickupPhotoUrls ?? new List<string>())
                .Select(u => blobService.GenerateSasUrl(u, 60)).ToList(),
            timeline,
            pickupSlotDisplay,
        };
    }
}

// Request DTOs for facility endpoints.
public record FacilityStatusUpdateRequest(string Status, string? Notes);
public record FacilityShoeStatusRequest(string ShoeItemId, string Status, string? Notes);
public record FacilityScanRequest(string OrderNumber);
public record FacilityDispatchRequest(Guid RiderId);
public record FacilityDropVerifyRequest(string Otp);
