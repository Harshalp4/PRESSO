namespace Presso.API.Domain.Entities;

public class ServiceZone
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string? Area { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
    public Guid? AssignedStoreId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public StoreLocation? AssignedStore { get; set; }
}
