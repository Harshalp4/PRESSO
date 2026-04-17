namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class Order
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public Guid AddressId { get; set; }
    public Guid? PickupSlotId { get; set; }
    // The actual day the customer booked the pickup template for. Slots
    // are date-less templates, so this column carries the date.
    public DateOnly? PickupDate { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public decimal SubTotal { get; set; }
    public decimal CoinDiscount { get; set; }
    public decimal StudentDiscount { get; set; }
    public decimal ExpressCharge { get; set; }
    public decimal TotalAmount { get; set; }
    public string? PickupOtpHash { get; set; }
    public string? DeliveryOtpHash { get; set; }
    // Plaintext delivery OTP. Only populated while the order is
    // OutForDelivery so the customer app can show it to the rider at the
    // door. Cleared on successful confirm-delivery. Never stored for
    // pickup OTPs — those are rider-issued at the customer's door.
    public string? DeliveryOtp { get; set; }
    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Pending;
    public string? RazorpayOrderId { get; set; }
    public string? RazorpayPaymentId { get; set; }
    public List<string> PickupPhotoUrls { get; set; } = new();
    public List<string> DeliveryPhotoUrls { get; set; } = new();
    public string? PickupPhotosBlobFolder { get; set; }
    public DateTime? PhotosUploadedAt { get; set; }
    public int PickupPhotoCount { get; set; }
    public bool IsExpressDelivery { get; set; }
    public string? SpecialInstructions { get; set; }
    public string? FacilityNotes { get; set; }
    // Sub-stage within OrderStatus.InProcess used by the operations app facility
    // dashboard. Allowed values: "AtFacility", "Washing", "Ironing", "Ready".
    // Null means the facility hasn't checked the order in yet.
    public string? FacilityStage { get; set; }
    public string? RiderPickupNotes { get; set; }
    public int CoinsEarned { get; set; }
    public int CoinsRedeemed { get; set; }
    public decimal AdminDiscount { get; set; }
    public Guid? UserDiscountId { get; set; }
    public Guid? AssignedStoreId { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? PickupCompletedAt { get; set; }
    public DateTime? FacilityReceivedAt { get; set; }
    public DateTime? ProcessingStartedAt { get; set; }
    public DateTime? ReadyAt { get; set; }
    public DateTime? OutForDeliveryAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public Address Address { get; set; } = null!;
    public PickupSlot? PickupSlot { get; set; }
    public UserDiscount? UserDiscount { get; set; }
    public StoreLocation? AssignedStore { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<OrderAssignment> Assignments { get; set; } = new List<OrderAssignment>();
}
