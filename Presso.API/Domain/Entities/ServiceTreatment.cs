namespace Presso.API.Domain.Entities;

public class ServiceTreatment
{
    public Guid Id { get; set; }
    public Guid ServiceId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal PriceMultiplier { get; set; } = 1.0m;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Service Service { get; set; } = null!;
}
