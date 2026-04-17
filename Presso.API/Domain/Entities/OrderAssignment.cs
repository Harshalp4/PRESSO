namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class OrderAssignment
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid RiderId { get; set; }
    public AssignmentType Type { get; set; }
    public AssignmentStatus Status { get; set; } = AssignmentStatus.Assigned;
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
    public DateTime? AcceptedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? OfferExpiresAt { get; set; }

    // Drop-off handshake (rider → facility). When the rider taps
    // "Drop at Facility", the backend generates a 4-digit OTP that
    // expires in ~5 minutes. Facility staff enters it on their app to
    // confirm receipt. On success, DroppedAtFacilityAt is set and
    // Status flips to ReceivedAtFacility.
    public string? DropOtp { get; set; }
    public DateTime? DropOtpExpiresAt { get; set; }
    public DateTime? DroppedAtFacilityAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Order Order { get; set; } = null!;
    public Rider Rider { get; set; } = null!;
}
