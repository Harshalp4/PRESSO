namespace Presso.API.Domain.Entities;

public class StoreLocation
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? GoogleMapsUrl { get; set; }
    public TimeOnly OpenTime { get; set; }
    public TimeOnly CloseTime { get; set; }
    public bool IsOpenSunday { get; set; }
    public double ServiceRadiusKm { get; set; } = 5.0;
    public bool IsActive { get; set; } = true;
    public bool IsHeadquarters { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
