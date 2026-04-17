namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class StoreLocationConfiguration : IEntityTypeConfiguration<StoreLocation>
{
    public void Configure(EntityTypeBuilder<StoreLocation> builder)
    {
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Name).HasMaxLength(100).IsRequired();
        builder.Property(s => s.AddressLine1).HasMaxLength(200).IsRequired();
        builder.Property(s => s.AddressLine2).HasMaxLength(200);
        builder.Property(s => s.City).HasMaxLength(100).IsRequired();
        builder.Property(s => s.State).HasMaxLength(100).IsRequired();
        builder.Property(s => s.Pincode).HasMaxLength(6).IsRequired();
        builder.Property(s => s.Phone).HasMaxLength(15).IsRequired();
        builder.Property(s => s.Email).HasMaxLength(256);
        builder.Property(s => s.GoogleMapsUrl).HasMaxLength(512);

        builder.HasData(new StoreLocation
        {
            Id = Guid.Parse("e1111111-1111-1111-1111-111111111111"),
            Name = "Presso Mahape Unit",
            AddressLine1 = "MIDC Industrial Area",
            City = "Navi Mumbai",
            State = "Maharashtra",
            Pincode = "400709",
            Latitude = 19.1136,
            Longitude = 73.0082,
            Phone = "+91 0000000000",
            OpenTime = new TimeOnly(8, 0),
            CloseTime = new TimeOnly(20, 0),
            IsOpenSunday = false,
            ServiceRadiusKm = 5.0,
            IsActive = true,
            IsHeadquarters = true,
            CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        });
    }
}
