namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class Referral
{
    public Guid Id { get; set; }
    public Guid ReferrerUserId { get; set; }
    public Guid ReferredUserId { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public ReferralStatus Status { get; set; } = ReferralStatus.Pending;
    public int CoinsEarned { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User ReferrerUser { get; set; } = null!;
    public User ReferredUser { get; set; } = null!;
}
