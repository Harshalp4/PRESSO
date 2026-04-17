namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class RiderPayout
{
    public Guid Id { get; set; }
    public Guid RiderId { get; set; }
    public decimal Amount { get; set; }
    public int DeliveryCount { get; set; }
    public DateOnly PeriodStart { get; set; }
    public DateOnly PeriodEnd { get; set; }
    public PayoutStatus Status { get; set; } = PayoutStatus.Pending;
    public DateTime? PaidAt { get; set; }
    public string? Reference { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Rider Rider { get; set; } = null!;
}
