namespace Presso.API.Domain.Entities;

public class Service
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Category { get; set; } = string.Empty;
    public decimal PricePerPiece { get; set; }
    public string? IconUrl { get; set; }
    public string? Emoji { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<GarmentType> GarmentTypes { get; set; } = new List<GarmentType>();
    public ICollection<ServiceTreatment> Treatments { get; set; } = new List<ServiceTreatment>();
}
