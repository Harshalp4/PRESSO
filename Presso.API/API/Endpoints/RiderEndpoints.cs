namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Rider;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public static class RiderEndpoints
{
    /// Helper: resolve or auto-create the Rider entity for the authenticated user.
    private static async Task<Rider> GetOrCreateRiderAsync(Guid userId, IRepository<Rider> riderRepo)
    {
        var rider = await riderRepo.Query().FirstOrDefaultAsync(r => r.UserId == userId);
        if (rider == null)
        {
            rider = new Rider
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                IsActive = true,
                IsAvailable = false
            };
            await riderRepo.AddAsync(rider);
            await riderRepo.SaveChangesAsync();
        }
        return rider;
    }

    public static RouteGroupBuilder MapRiderEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/riders").WithTags("Riders").RequireAuthorization();

        group.MapGet("/", async (IRiderService riderService) =>
        {
            var result = await riderService.GetAllRidersAsync();
            return result.ToResult();
        }).RequireAuthorization("AdminOnly");

        group.MapPost("/", async (CreateRiderRequest request, IRiderService riderService) =>
        {
            var result = await riderService.CreateRiderAsync(request);
            return result.ToResult();
        }).RequireAuthorization("AdminOnly");

        // === "me" endpoints — resolve rider ID from JWT, auto-create if needed ===

        group.MapGet("/me/jobs", async (
            ClaimsPrincipal user,
            IRiderService riderService,
            IRepository<Rider> riderRepo,
            string? search,
            string? date) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);
            DateOnly? parsedDate = null;
            if (!string.IsNullOrWhiteSpace(date)
                && DateOnly.TryParse(date, out var d))
            {
                parsedDate = d;
            }
            var result = await riderService.GetRiderJobsAsync(rider.Id, search, parsedDate);
            return result.ToResult();
        });

        group.MapGet("/me/job/{assignmentId:guid}", async (
            Guid assignmentId,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IAzureBlobService blobService) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .Where(a => a.Id == assignmentId && a.RiderId == rider.Id)
                .Include(a => a.Order).ThenInclude(o => o.User)
                .Include(a => a.Order).ThenInclude(o => o.Address)
                .Include(a => a.Order).ThenInclude(o => o.PickupSlot)
                .Include(a => a.Order).ThenInclude(o => o.Items)
                .FirstOrDefaultAsync();

            if (assignment == null)
            {
                return Result<object>.NotFound("Assignment not found").ToResult();
            }

            var order = assignment.Order;
            var garmentCount = order.Items?.Sum(i => i.Quantity) ?? 0;
            string? pickupSlotDisplay = null;
            if (order.PickupSlot != null)
            {
                var slot = order.PickupSlot;
                pickupSlotDisplay = order.PickupDate.HasValue
                    ? $"{order.PickupDate.Value:dd MMM}, {slot.StartTime:hh\\:mm}-{slot.EndTime:hh\\:mm}"
                    : $"{slot.StartTime:hh\\:mm}-{slot.EndTime:hh\\:mm}";
            }

            static string MaskPhone(string p)
            {
                if (string.IsNullOrEmpty(p) || p.Length < 4) return p;
                return new string('X', p.Length - 4) + p[^4..];
            }

            var dto = new RiderAssignmentDto(
                assignment.Id,
                assignment.Type.ToString(),
                assignment.Status.ToString(),
                assignment.AssignedAt,
                null,
                assignment.CompletedAt,
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
                    (order.PickupPhotoUrls ?? new List<string>())
                        .Select(u => blobService.GenerateSasUrl(u, 60)).ToList(),
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
                    order.Address.Lng));

            return Result<object>.Success(new { assignment = dto }).ToResult();
        });

        group.MapGet("/me/earnings", async (ClaimsPrincipal user, IRiderService riderService, IRepository<Rider> riderRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);
            var result = await riderService.GetEarningsAsync(rider.Id);
            return result.ToResult();
        });

        // Rider job history — completed/cancelled assignments for the signed-in rider.
        // Used by the operations app History tab (Screens 9 & 10 of the wireframes).
        // Optional query params: ?limit=50 &offset=0 &type=Pickup|Delivery
        group.MapGet("/me/jobs/history", async (
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IAzureBlobService blobService,
            int? limit,
            int? offset,
            string? type) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var take = Math.Clamp(limit ?? 50, 1, 200);
            var skip = Math.Max(offset ?? 0, 0);

            // Pickups now "complete" as ReceivedAtFacility (two-sided drop-off
            // handshake) while deliveries still complete as Completed. History
            // should surface both terminal states.
            var query = assignmentRepo.Query()
                .Where(a => a.RiderId == rider.Id
                    && (a.Status == AssignmentStatus.Completed
                        || a.Status == AssignmentStatus.ReceivedAtFacility));

            if (!string.IsNullOrWhiteSpace(type))
            {
                if (Enum.TryParse<AssignmentType>(type, true, out var parsedType))
                {
                    query = query.Where(a => a.Type == parsedType);
                }
            }

            var assignments = await query
                .Include(a => a.Order).ThenInclude(o => o.User)
                .Include(a => a.Order).ThenInclude(o => o.Address)
                .Include(a => a.Order).ThenInclude(o => o.PickupSlot)
                .Include(a => a.Order).ThenInclude(o => o.Items)
                .OrderByDescending(a => a.CompletedAt ?? a.UpdatedAt)
                .Skip(skip)
                .Take(take)
                .ToListAsync();

            static string MaskPhone(string p)
            {
                if (string.IsNullOrEmpty(p) || p.Length < 4) return p;
                return new string('X', p.Length - 4) + p[^4..];
            }

            var pickupJobs = new List<RiderAssignmentDto>();
            var deliveryJobs = new List<RiderAssignmentDto>();

            foreach (var a in assignments)
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

                var dto = new RiderAssignmentDto(
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
                        (order.PickupPhotoUrls ?? new List<string>())
                            .Select(u => blobService.GenerateSasUrl(u, 60)).ToList(),
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
                        order.Address.Lng));

                if (a.Type == AssignmentType.Pickup) pickupJobs.Add(dto);
                else deliveryJobs.Add(dto);
            }

            var totalCompleted = await assignmentRepo.Query()
                .CountAsync(a => a.RiderId == rider.Id
                    && (a.Status == AssignmentStatus.Completed
                        || a.Status == AssignmentStatus.ReceivedAtFacility));

            // History never contains InTransit or AtFacility assignments, so
            // ToDropJobs / AtFacilityJobs are always empty here — shape is
            // kept consistent for the client.
            var response = new RiderJobsResponseDto(
                pickupJobs,
                new List<RiderAssignmentDto>(),
                new List<RiderAssignmentDto>(),
                deliveryJobs,
                pickupJobs.Count + deliveryJobs.Count,
                totalCompleted);

            return Result<RiderJobsResponseDto>.Success(response).ToResult();
        });

        group.MapPatch("/me/availability", async (ClaimsPrincipal user, AvailabilityRequest request, IRiderService riderService, IRepository<Rider> riderRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);
            var result = await riderService.UpdateAvailabilityAsync(rider.Id, request.IsAvailable);
            return result.ToResult();
        });

        group.MapPatch("/me/location", async (ClaimsPrincipal user, LocationUpdateRequest request, IRiderService riderService, IRepository<Rider> riderRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);
            var result = await riderService.UpdateLocationAsync(rider.Id, request);
            return result.ToResult();
        }).WithValidation<LocationUpdateRequest>();

        // === Rider job action endpoints ===

        // GET /me/current-offer — returns the rider's active Offered assignment (if any)
        // with secondsRemaining so the app can resume the countdown on a cold start.
        group.MapGet("/me/current-offer", async (
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IRiderService riderService) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var now = DateTime.UtcNow;
            var offer = await assignmentRepo.Query()
                .Where(a => a.RiderId == rider.Id
                    && a.Status == AssignmentStatus.Offered
                    && a.OfferExpiresAt != null
                    && a.OfferExpiresAt > now)
                .Include(a => a.Order).ThenInclude(o => o.User)
                .Include(a => a.Order).ThenInclude(o => o.Address)
                .Include(a => a.Order).ThenInclude(o => o.PickupSlot)
                .Include(a => a.Order).ThenInclude(o => o.Items)
                .OrderBy(a => a.OfferExpiresAt)
                .FirstOrDefaultAsync();

            if (offer == null)
                return Result<object>.Success(new { assignment = (RiderAssignmentDto?)null }).ToResult();

            var dto = riderService.ToAssignmentDto(offer);
            return Result<object>.Success(new { assignment = dto }).ToResult();
        });

        // POST /me/job/{id}/accept — wireframe screen 2b.
        // Optimistic concurrency + expiry guard. First rider wins; second gets 409.
        group.MapPost("/me/job/{assignmentId:guid}/accept", async (
            Guid assignmentId,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IRepository<Order> orderRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<object>.NotFound("Assignment not found").ToResult();

            // Gate 1: only Offered assignments can be accepted.
            if (assignment.Status != AssignmentStatus.Offered)
            {
                return Results.Conflict(new
                {
                    success = false,
                    code = "offer_not_available",
                    message = "This offer is no longer available."
                });
            }

            // Gate 2: expiry window must not have passed.
            if (assignment.OfferExpiresAt is DateTime exp && exp < DateTime.UtcNow)
            {
                assignment.Status = AssignmentStatus.Expired;
                assignment.UpdatedAt = DateTime.UtcNow;
                assignmentRepo.Update(assignment);
                await assignmentRepo.SaveChangesAsync();
                return Results.Conflict(new
                {
                    success = false,
                    code = "offer_expired",
                    message = "This offer has expired."
                });
            }

            var acceptedAt = DateTime.UtcNow;
            assignment.Status = AssignmentStatus.Accepted;
            assignment.AcceptedAt = acceptedAt;
            assignment.UpdatedAt = acceptedAt;
            assignmentRepo.Update(assignment);

            // For a Delivery assignment, accepting it means the rider has
            // committed to transporting the cleaned clothes — flip the
            // order to OutForDelivery now. This hands ownership from the
            // facility (who no longer needs it on their dashboard) to the
            // rider, and gives the customer tracker a real "on the way"
            // state the moment the delivery begins. Pickup assignments
            // stay on their existing status here; they transition in
            // /arrived and /confirm-pickup.
            if (assignment.Type == AssignmentType.Delivery)
            {
                var order = await orderRepo.GetByIdAsync(assignment.OrderId);
                if (order != null)
                {
                    order.Status = OrderStatus.OutForDelivery;
                    order.OutForDeliveryAt ??= acceptedAt;
                    // Clear the facility sub-stage so effectiveStatus
                    // rolls cleanly from "Ready" to "OutForDelivery".
                    order.FacilityStage = null;
                    // Generate a fresh 4-digit delivery OTP. The customer
                    // sees the plaintext in their app while OFD; the rider
                    // types it into confirm-delivery. We store plaintext
                    // alongside the hash (short-lived) so the owner can
                    // display it. It's cleared on confirm-delivery.
                    var deliveryOtp = RandomNumberGenerator
                        .GetInt32(1000, 10000).ToString("D4");
                    order.DeliveryOtp = deliveryOtp;
                    order.DeliveryOtpHash = HashDeliveryOtp(deliveryOtp);
                    order.UpdatedAt = acceptedAt;
                    orderRepo.Update(order);
                }
            }

            try
            {
                await assignmentRepo.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                // xmin changed — another rider won the race (or a sweep expired it).
                return Results.Conflict(new
                {
                    success = false,
                    code = "offer_lost",
                    message = "Another rider accepted this job first."
                });
            }

            return Result<object>.Success(new { assignmentId = assignment.Id }).ToResult();
        });

        // POST /me/job/{id}/decline — rider rejects the offer; opens the order to re-dispatch.
        group.MapPost("/me/job/{assignmentId:guid}/decline", async (
            Guid assignmentId,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<bool>.NotFound("Assignment not found").ToResult();

            if (assignment.Status != AssignmentStatus.Offered)
                return Result<bool>.Failure("Only offered assignments can be declined.").ToResult();

            assignment.Status = AssignmentStatus.Declined;
            assignment.UpdatedAt = DateTime.UtcNow;
            assignmentRepo.Update(assignment);
            await assignmentRepo.SaveChangesAsync();

            return Result<bool>.Success(true).ToResult();
        });

        // Mark rider as arrived at pickup/delivery location
        group.MapPatch("/me/job/{assignmentId:guid}/arrived", async (
            Guid assignmentId,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IRepository<Order> orderRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<bool>.NotFound("Assignment not found").ToResult();

            assignment.Status = AssignmentStatus.InProgress;
            assignment.UpdatedAt = DateTime.UtcNow;
            assignmentRepo.Update(assignment);

            var order = await orderRepo.GetByIdAsync(assignment.OrderId);
            if (order != null && assignment.Type == AssignmentType.Pickup)
            {
                // Pickup: rider has arrived at the customer's doorstep.
                // Delivery: the order already transitioned to OutForDelivery
                //   when the rider accepted the delivery assignment, so
                //   /arrived is purely an assignment state change and must
                //   NOT touch order.Status here — otherwise a rider hitting
                //   Arrived before collecting clothes from the facility
                //   would prematurely drop the order off the facility
                //   dashboard.
                order.Status = OrderStatus.PickupInProgress;
                order.UpdatedAt = DateTime.UtcNow;
                orderRepo.Update(order);
            }

            await assignmentRepo.SaveChangesAsync();
            return Result<bool>.Success(true).ToResult();
        });

        // Upload pickup photos — persists via blob service and appends to the
        // order's PickupPhotoUrls so the history detail screen can render them.
        group.MapPost("/me/job/{assignmentId:guid}/photos", async (
            Guid assignmentId,
            HttpRequest request,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IRepository<Order> orderRepo,
            IAzureBlobService blobService) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<List<string>>.NotFound("Assignment not found").ToResult();

            var order = await orderRepo.GetByIdAsync(assignment.OrderId);
            if (order == null) return Result<List<string>>.NotFound("Order not found").ToResult();

            if (!request.HasFormContentType)
                return Result<List<string>>.Failure("Content-Type must be multipart/form-data").ToResult();

            var form = await request.ReadFormAsync();
            var files = form.Files.GetFiles("photos");
            if (files.Count == 0)
                return Result<List<string>>.Failure("No photos provided").ToResult();

            var folder = $"pickup-photos/{order.Id}/";
            var newUrls = new List<string>();
            foreach (var file in files)
            {
                if (file.Length > 5 * 1024 * 1024)
                    return Result<List<string>>.Failure($"File '{file.FileName}' exceeds 5MB limit").ToResult();

                using var stream = file.OpenReadStream();
                var url = await blobService.UploadPhotoAsync(
                    stream,
                    file.FileName,
                    file.ContentType ?? "image/jpeg",
                    folder);
                newUrls.Add(url);
            }

            order.PickupPhotoUrls.AddRange(newUrls);
            order.PickupPhotoCount = order.PickupPhotoUrls.Count;
            order.PhotosUploadedAt = DateTime.UtcNow;
            order.PickupPhotosBlobFolder = folder;
            order.UpdatedAt = DateTime.UtcNow;
            orderRepo.Update(order);
            await orderRepo.SaveChangesAsync();

            return Result<List<string>>.Success(newUrls).ToResult();
        }).DisableAntiforgery();

        // Confirm pickup (dev: accept any OTP, complete the pickup assignment)
        group.MapPatch("/me/job/{assignmentId:guid}/confirm-pickup", async (
            Guid assignmentId,
            ConfirmPickupRequest request,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IRepository<Order> orderRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<bool>.NotFound("Assignment not found").ToResult();

            // confirm-pickup is ONLY valid on an active Pickup assignment.
            // Calling it on a Delivery assignment (or on a Pickup that
            // already dropped off) previously rolled orders back from
            // OutForDelivery → PickedUp and clobbered the rider's
            // delivery-assignment state. Hard reject both.
            if (assignment.Type != AssignmentType.Pickup)
                return Result<bool>.Failure(
                    "Only pickup assignments can be confirmed via confirm-pickup.").ToResult();

            if (assignment.Status != AssignmentStatus.Accepted
                && assignment.Status != AssignmentStatus.InProgress
                && assignment.Status != AssignmentStatus.Assigned)
            {
                return Result<bool>.Failure(
                    $"Pickup cannot be confirmed from status {assignment.Status}.").ToResult();
            }

            // Customer OTP confirmed — rider now has the garments and is
            // driving to the facility. The assignment does NOT complete
            // here; it moves to InTransitToFacility and stays on the
            // rider's dashboard under the "To Drop" tab until facility
            // staff verifies the drop-off OTP.
            assignment.Status = AssignmentStatus.InTransitToFacility;
            assignment.UpdatedAt = DateTime.UtcNow;
            assignmentRepo.Update(assignment);

            var order = await orderRepo.GetByIdAsync(assignment.OrderId);
            if (order != null)
            {
                // Only allow the PickedUp transition from pre-facility
                // states. Prevents a late/stale confirm-pickup from
                // rewinding an order that has already entered the
                // facility pipeline or moved to delivery.
                var canPickup =
                    order.Status == OrderStatus.Pending
                    || order.Status == OrderStatus.Confirmed
                    || order.Status == OrderStatus.RiderAssigned
                    || order.Status == OrderStatus.PickupInProgress;
                if (canPickup)
                {
                    order.Status = OrderStatus.PickedUp;
                    order.PickedUpAt = DateTime.UtcNow;
                    order.PickupCompletedAt = DateTime.UtcNow;
                    if (!string.IsNullOrEmpty(request.Notes)) order.RiderPickupNotes = request.Notes;
                    order.UpdatedAt = DateTime.UtcNow;
                    orderRepo.Update(order);
                }
            }

            await assignmentRepo.SaveChangesAsync();
            return Result<bool>.Success(true).ToResult();
        });

        // POST /me/job/{id}/start-drop — rider initiates the facility
        // drop-off handshake. Backend generates a 4-digit OTP with a
        // 5-minute TTL, stores it on the assignment, and returns it to
        // the rider. The rider shows the code to facility staff, who
        // enters it in the facility app (see POST /api/facility/drop/verify).
        // Only valid when the assignment is InTransitToFacility.
        group.MapPost("/me/job/{assignmentId:guid}/start-drop", async (
            Guid assignmentId,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null)
                return Result<StartDropResponse>.NotFound("Assignment not found").ToResult();

            if (assignment.Type != AssignmentType.Pickup)
                return Result<StartDropResponse>.Failure(
                    "Only pickup assignments can be dropped at a facility.").ToResult();

            if (assignment.Status != AssignmentStatus.InTransitToFacility)
                return Result<StartDropResponse>.Failure(
                    $"Assignment must be InTransitToFacility (currently {assignment.Status}).").ToResult();

            // Reuse an existing unexpired OTP if the rider re-taps the
            // button within the 5-minute window. Otherwise generate a
            // fresh one. This avoids confusing the facility staff with
            // multiple codes for the same order.
            var now = DateTime.UtcNow;
            if (string.IsNullOrEmpty(assignment.DropOtp)
                || assignment.DropOtpExpiresAt is null
                || assignment.DropOtpExpiresAt <= now)
            {
                assignment.DropOtp = Random.Shared.Next(1000, 10000).ToString("D4");
                assignment.DropOtpExpiresAt = now.AddMinutes(5);
                assignment.UpdatedAt = now;
                assignmentRepo.Update(assignment);
                await assignmentRepo.SaveChangesAsync();
            }

            return Result<StartDropResponse>.Success(new StartDropResponse(
                assignment.DropOtp!,
                assignment.DropOtpExpiresAt!.Value,
                (int)Math.Max(0, (assignment.DropOtpExpiresAt.Value - now).TotalSeconds)
            )).ToResult();
        });

        // Confirm delivery (dev: accept any OTP, complete the delivery assignment)
        group.MapPatch("/me/job/{assignmentId:guid}/confirm-delivery", async (
            Guid assignmentId,
            ConfirmDeliveryRequest request,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo,
            IRepository<Order> orderRepo,
            IRepository<User> userRepo,
            IRepository<CoinsLedger> coinsRepo,
            IConfiguration config) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<bool>.NotFound("Assignment not found").ToResult();

            // Symmetric guard to confirm-pickup: only valid on an active
            // Delivery assignment. Prevents a rider-side mis-tap from
            // marking a pickup as Delivered.
            if (assignment.Type != AssignmentType.Delivery)
                return Result<bool>.Failure(
                    "Only delivery assignments can be confirmed via confirm-delivery.").ToResult();

            if (assignment.Status != AssignmentStatus.Accepted
                && assignment.Status != AssignmentStatus.InProgress
                && assignment.Status != AssignmentStatus.Assigned)
            {
                return Result<bool>.Failure(
                    $"Delivery cannot be confirmed from status {assignment.Status}.").ToResult();
            }

            var order = await orderRepo.GetByIdAsync(assignment.OrderId);

            // Validate the 4-digit OTP the customer showed the rider. If the
            // order has no stored hash (legacy rows) we fall back to dev
            // behavior and accept anything, matching the previous endpoint.
            if (order != null && !string.IsNullOrEmpty(order.DeliveryOtpHash))
            {
                if (string.IsNullOrWhiteSpace(request.Otp)
                    || HashDeliveryOtp(request.Otp.Trim()) != order.DeliveryOtpHash)
                {
                    return Result<bool>.Failure("Invalid OTP").ToResult();
                }
            }

            assignment.Status = AssignmentStatus.Completed;
            assignment.CompletedAt = DateTime.UtcNow;
            assignment.UpdatedAt = DateTime.UtcNow;
            assignmentRepo.Update(assignment);

            if (order != null)
            {
                order.Status = OrderStatus.Delivered;
                order.DeliveredAt = DateTime.UtcNow;
                // Clear the short-lived plaintext OTP now that delivery is
                // confirmed — don't leave it sitting in the DB.
                order.DeliveryOtp = null;
                order.UpdatedAt = DateTime.UtcNow;

                // Award loyalty coins. The customer-facing
                // OrderService.UpdateOrderStatusAsync path does this when an
                // admin flips an order to Delivered, but the rider flow goes
                // straight through this endpoint and used to skip it, which
                // is why customer coin balances stayed at 0 after real
                // deliveries.
                if (order.CoinsEarned == 0)
                {
                    var earnSettings = config.GetSection("OrderSettings");
                    var coinEarnPct = earnSettings.GetValue<decimal>("CoinEarnPercent", 1) / 100m;
                    var earnCoinsPerRupee = earnSettings.GetValue<int>("CoinsPerRupee", 10);
                    var coinsEarned = (int)(order.TotalAmount * coinEarnPct * earnCoinsPerRupee);
                    if (coinsEarned > 0)
                    {
                        order.CoinsEarned = coinsEarned;
                        var customer = await userRepo.GetByIdAsync(order.UserId);
                        if (customer != null)
                        {
                            customer.CoinBalance += coinsEarned;
                            userRepo.Update(customer);
                            await coinsRepo.AddAsync(new CoinsLedger
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

                orderRepo.Update(order);
            }

            await assignmentRepo.SaveChangesAsync();
            return Result<bool>.Success(true).ToResult();
        });

        // Upload shoe photos (dev stub)
        group.MapPost("/me/job/{assignmentId:guid}/shoe-photos", async (
            Guid assignmentId,
            ClaimsPrincipal user,
            IRepository<Rider> riderRepo,
            IRepository<OrderAssignment> assignmentRepo) =>
        {
            var userId = user.GetUserId();
            var rider = await GetOrCreateRiderAsync(userId, riderRepo);

            var assignment = await assignmentRepo.Query()
                .FirstOrDefaultAsync(a => a.Id == assignmentId && a.RiderId == rider.Id);
            if (assignment == null) return Result<List<string>>.NotFound("Assignment not found").ToResult();

            return Result<List<string>>.Success(new List<string>()).ToResult();
        }).DisableAntiforgery();

        // === ID-based endpoints (admin use) ===

        group.MapPatch("/{id:guid}/availability", async (Guid id, bool isAvailable, IRiderService riderService) =>
        {
            var result = await riderService.UpdateAvailabilityAsync(id, isAvailable);
            return result.ToResult();
        });

        group.MapPatch("/{id:guid}/location", async (Guid id, LocationUpdateRequest request, IRiderService riderService) =>
        {
            var result = await riderService.UpdateLocationAsync(id, request);
            return result.ToResult();
        }).WithValidation<LocationUpdateRequest>();

        group.MapGet("/{id:guid}/jobs", async (Guid id, IRiderService riderService) =>
        {
            var result = await riderService.GetRiderJobsAsync(id);
            return result.ToResult();
        });

        group.MapGet("/{id:guid}/earnings", async (Guid id, IRiderService riderService) =>
        {
            var result = await riderService.GetEarningsAsync(id);
            return result.ToResult();
        });

        return group;
    }

    // Mirror of OrderService.HashOtp so RiderEndpoints can rotate the
    // delivery OTP without taking a dependency on OrderService.
    private static string HashDeliveryOtp(string otp)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(otp));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}

// Request DTO for availability toggle (app sends JSON body)
public record AvailabilityRequest(bool IsAvailable);

// Request DTOs for rider job confirmations
public record ConfirmPickupRequest(string Otp, int Count, string? Notes);
public record ConfirmDeliveryRequest(string Otp, string? Notes);

// Response when the rider initiates a drop-off handshake. The 4-digit
// OTP is shown on the rider's phone; facility staff enters it in the
// facility app to verify receipt.
public record StartDropResponse(string Otp, DateTime ExpiresAt, int SecondsRemaining);
