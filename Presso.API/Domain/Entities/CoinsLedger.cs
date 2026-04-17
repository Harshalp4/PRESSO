namespace Presso.API.Domain.Entities;

using Presso.API.Domain.Enums;

public class CoinsLedger
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? OrderId { get; set; }
    public int Amount { get; set; }
    public CoinsType Type { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public Order? Order { get; set; }
}
