namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.HasKey(oi => oi.Id);
        builder.Property(oi => oi.ServiceName).HasMaxLength(100).IsRequired();
        builder.Property(oi => oi.GarmentTypeName).HasMaxLength(100);
        builder.Property(oi => oi.PricePerPiece).HasPrecision(10, 2);
        builder.Property(oi => oi.Subtotal).HasPrecision(10, 2);

        builder.HasOne(oi => oi.Order)
            .WithMany(o => o.Items)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(oi => oi.Service)
            .WithMany()
            .HasForeignKey(oi => oi.ServiceId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(oi => oi.GarmentType)
            .WithMany()
            .HasForeignKey(oi => oi.GarmentTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Property(oi => oi.TreatmentName).HasMaxLength(100);
        builder.Property(oi => oi.TreatmentMultiplier).HasPrecision(5, 2).HasDefaultValue(1.0m);

        builder.HasOne(oi => oi.ServiceTreatment)
            .WithMany()
            .HasForeignKey(oi => oi.ServiceTreatmentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
