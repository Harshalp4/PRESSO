namespace Presso.API.Domain.Entities;

public class OrderItem
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid ServiceId { get; set; }
    public Guid? GarmentTypeId { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public string? GarmentTypeName { get; set; }
    public Guid? ServiceTreatmentId { get; set; }
    public string? TreatmentName { get; set; }
    public decimal TreatmentMultiplier { get; set; } = 1.0m;
    public int Quantity { get; set; }
    public decimal PricePerPiece { get; set; }
    public decimal Subtotal { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Order Order { get; set; } = null!;
    public Service Service { get; set; } = null!;
    public GarmentType? GarmentType { get; set; }
    public ServiceTreatment? ServiceTreatment { get; set; }
}
