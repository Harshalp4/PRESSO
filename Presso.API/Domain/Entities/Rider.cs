namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class Rider
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string? VehicleNumber { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsAvailable { get; set; }
    public double? CurrentLat { get; set; }
    public double? CurrentLng { get; set; }
    public decimal TodayEarnings { get; set; }
    public DateTime? LastLocationUpdate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // === Admin approval workflow ===
    // Status is the admin's single source of truth for whether a rider
    // is allowed to take jobs. IsActive is a separate operational flag
    // (e.g. rider is temporarily off duty) and does not change during
    // approval/rejection.
    public RiderStatus Status { get; set; } = RiderStatus.Pending;

    // Set when the rider first transitions into Approved. Kept for audit.
    public DateTime? ApprovedAt { get; set; }

    // Set when the rider transitions into Suspended. Cleared on reinstate.
    public DateTime? SuspendedAt { get; set; }

    // Free-text reason shown to admins explaining a Reject/Suspend decision.
    public string? RejectionReason { get; set; }

    // Internal-only notes the admin can attach to a rider profile.
    public string? AdminNotes { get; set; }

    public User User { get; set; } = null!;
    public ICollection<OrderAssignment> Assignments { get; set; } = new List<OrderAssignment>();
}
