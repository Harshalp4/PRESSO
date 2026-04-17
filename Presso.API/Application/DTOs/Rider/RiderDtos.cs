namespace Presso.API.Application.DTOs.Rider;

public record RiderDto(
    Guid Id, Guid UserId, string? Name, string? Phone,
    string? VehicleNumber, bool IsActive, bool IsAvailable,
    double? CurrentLat, double? CurrentLng);

public record CreateRiderRequest(Guid UserId, string? VehicleNumber);

public record LocationUpdateRequest(double Lat, double Lng);

public record EarningsDto(decimal TodayEarnings, decimal WeekEarnings, decimal MonthEarnings, int TotalDeliveries);

public record RiderJobDto(
    Guid AssignmentId, Guid OrderId, string OrderNumber,
    string Type, string Status, string CustomerName, string CustomerPhone,
    string AddressLine1, string City, double Lat, double Lng);

// Rich shape consumed by the operations app (/api/riders/me/jobs).
//
// PickupJobs     = assignments the rider still needs to go and collect
//                  (Offered/Assigned/Accepted/InProgress — NOT yet in transit).
// ToDropJobs     = pickups the rider has already collected and is carrying
//                  back to the facility (InTransitToFacility).
// AtFacilityJobs = pickups the rider has already dropped off and the order
//                  is currently being processed at the facility (assignment
//                  Completed/ReceivedAtFacility, order not yet Delivered).
//                  Read-only visibility tab so the rider can track their
//                  in-flight pickups.
// DeliveryJobs   = active delivery assignments.
//
// The split is authoritative on the server so the dashboard tabs are a
// direct render of API lists — no client-side status filtering.
public record RiderJobsResponseDto(
    List<RiderAssignmentDto> PickupJobs,
    List<RiderAssignmentDto> ToDropJobs,
    List<RiderAssignmentDto> AtFacilityJobs,
    List<RiderAssignmentDto> DeliveryJobs,
    int CompletedToday,
    int PendingCount);

public record RiderAssignmentDto(
    Guid Id,
    string Type,
    string Status,
    DateTime? AssignedAt,
    DateTime? RiderArrivedAt,
    DateTime? CompletedAt,
    RiderAssignmentOrderDto Order,
    RiderAssignmentCustomerDto Customer,
    RiderAssignmentAddressDto Address,
    DateTime? OfferExpiresAt = null,
    int? SecondsRemaining = null,
    decimal? PayoutAmount = null);

public record RiderAssignmentOrderDto(
    Guid Id,
    string OrderNumber,
    string Status,
    int GarmentCount,
    string? ServiceSummary,
    string? SpecialInstructions,
    bool HasShoeItems,
    bool IsExpressDelivery,
    string? PickupSlotDisplay,
    List<string>? PickupPhotoUrls = null,
    // Facility sub-stage ("AtFacility"/"Washing"/"Ironing"/"Ready") so the
    // rider history tracker can show the real facility progress rather than
    // collapsing everything after PickedUp into "InProcess".
    string? FacilityStage = null,
    DateTime? FacilityReceivedAt = null,
    DateTime? ProcessingStartedAt = null,
    DateTime? ReadyAt = null,
    DateTime? OutForDeliveryAt = null,
    DateTime? DeliveredAt = null);

public record RiderAssignmentCustomerDto(
    string Name,
    string MaskedPhone);

public record RiderAssignmentAddressDto(
    string? Label,
    string AddressLine1,
    string? AddressLine2,
    string? City,
    string? Pincode,
    double? Latitude,
    double? Longitude);
