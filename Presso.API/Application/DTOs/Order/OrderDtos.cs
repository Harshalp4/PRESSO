namespace Presso.API.Application.DTOs.Order;

public record CreateOrderRequest(
    Guid AddressId,
    Guid? PickupSlotId,
    DateOnly? PickupDate,
    List<OrderItemRequest> Items,
    bool IsExpressDelivery,
    string? SpecialInstructions,
    int CoinsToRedeem);

public record OrderItemRequest(Guid ServiceId, Guid? GarmentTypeId, int Quantity, Guid? ServiceTreatmentId = null);

public record OrderDto(
    Guid Id, string OrderNumber, string Status, string PaymentStatus,
    decimal TotalAmount, bool IsExpressDelivery,
    DateTime CreatedAt, string? PickupSlotDisplay,
    // Facility sub-stage ("AtFacility"/"Washing"/"Ironing"/"Ready") so the
    // customer history list can show a mini tracker per order without a
    // second detail fetch. Null when the order hasn't reached the facility.
    string? FacilityStage = null);

public record OrderDetailDto(
    Guid Id, string OrderNumber, string Status, string PaymentStatus,
    decimal SubTotal, decimal CoinDiscount, decimal StudentDiscount,
    decimal AdminDiscount, decimal ExpressCharge, decimal TotalAmount,
    bool IsExpressDelivery, string? SpecialInstructions,
    int CoinsEarned, int CoinsRedeemed,
    List<string> PickupPhotoUrls,
    string? RazorpayOrderId,
    DateTime? PickedUpAt, DateTime? DeliveredAt,
    DateTime CreatedAt,
    Application.DTOs.User.AddressDto Address,
    SlotDto? PickupSlot,
    DateOnly? PickupDate,
    List<OrderItemDto> Items,
    List<AssignmentDto> Assignments,
    Store.FacilityInfoDto? FacilityInfo,
    // Facility sub-stage ("AtFacility" / "Washing" / "Ironing" / "Ready") and
    // the full set of stage timestamps. Exposed so the customer tracker can
    // show progression through processing / ready / out-for-delivery without
    // having to reconstruct them from the raw OrderStatus enum.
    string? FacilityStage = null,
    DateTime? FacilityReceivedAt = null,
    DateTime? ProcessingStartedAt = null,
    DateTime? ReadyAt = null,
    DateTime? OutForDeliveryAt = null,
    // 4-digit plaintext delivery OTP. Populated only while the order is
    // OutForDelivery so the customer can show it to the rider at the door.
    // Null in every other state.
    string? DeliveryOtp = null);

public record OrderItemDto(
    Guid Id, string ServiceName, string? GarmentTypeName,
    string? TreatmentName, decimal TreatmentMultiplier,
    int Quantity, decimal PricePerPiece, decimal Subtotal);

// Date is contextual: in availability listings it's the queried date, in
// order details it's the booked pickup date. Templates themselves are
// date-less — see AdminSlotDto for the raw template view.
public record SlotDto(Guid Id, DateOnly? Date, TimeOnly StartTime, TimeOnly EndTime, int Available);

public record AssignmentDto(Guid RiderId, string? RiderName, string Type, string Status, DateTime AssignedAt);

public record UpdateOrderStatusRequest(string Status);

public record ConfirmOtpRequest(string Otp);

public record RepeatOrderRequest(Guid OriginalOrderId, Guid AddressId, Guid? PickupSlotId, DateOnly? PickupDate);
