namespace Presso.API.Domain.Entities;

// Pickup slots are now date-less templates (e.g. "8-10 AM, max 10").
// The same template applies to every day. Per-day capacity is enforced by
// counting orders that booked this template on a given pickup date.
public class PickupSlot
{
    public Guid Id { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public int MaxOrders { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
    public Guid? StoreLocationId { get; set; }
    public StoreLocation? StoreLocation { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
