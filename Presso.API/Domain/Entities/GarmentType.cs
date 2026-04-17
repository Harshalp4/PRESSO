namespace Presso.API.Domain.Entities;

public class GarmentType
{
    public Guid Id { get; set; }
    public Guid ServiceId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Emoji { get; set; }
    public decimal? PriceOverride { get; set; }
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Service Service { get; set; } = null!;
}
