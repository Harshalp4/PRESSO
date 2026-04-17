namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class UserDiscount
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public DiscountType Type { get; set; }
    public decimal Value { get; set; }
    public string Reason { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime? ExpiresAt { get; set; }
    public int? UsageLimit { get; set; }
    public int UsageCount { get; set; }
    public Guid CreatedByAdminId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
