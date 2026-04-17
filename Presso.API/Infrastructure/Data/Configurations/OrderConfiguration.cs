namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.HasKey(o => o.Id);
        builder.HasIndex(o => o.OrderNumber).IsUnique();
        builder.HasIndex(o => o.UserId);
        builder.HasIndex(o => o.RazorpayOrderId);

        builder.Property(o => o.OrderNumber).HasMaxLength(20).IsRequired();
        builder.Property(o => o.SubTotal).HasPrecision(10, 2);
        builder.Property(o => o.CoinDiscount).HasPrecision(10, 2);
        builder.Property(o => o.StudentDiscount).HasPrecision(10, 2);
        builder.Property(o => o.ExpressCharge).HasPrecision(10, 2);
        builder.Property(o => o.TotalAmount).HasPrecision(10, 2);
        builder.Property(o => o.PickupOtpHash).HasMaxLength(128);
        builder.Property(o => o.DeliveryOtpHash).HasMaxLength(128);
        builder.Property(o => o.DeliveryOtp).HasMaxLength(8);
        builder.Property(o => o.RazorpayOrderId).HasMaxLength(100);
        builder.Property(o => o.RazorpayPaymentId).HasMaxLength(100);
        builder.Property(o => o.SpecialInstructions).HasMaxLength(500);
        builder.Property(o => o.PickupPhotoUrls).HasColumnType("jsonb");
        builder.Property(o => o.DeliveryPhotoUrls).HasColumnType("jsonb");
        builder.Property(o => o.PickupPhotosBlobFolder).HasMaxLength(200);
        builder.Property(o => o.AdminDiscount).HasPrecision(10, 2);
        builder.Property(o => o.FacilityNotes).HasMaxLength(1000);
        builder.Property(o => o.RiderPickupNotes).HasMaxLength(1000);

        builder.HasOne(o => o.User)
            .WithMany(u => u.Orders)
            .HasForeignKey(o => o.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.Address)
            .WithMany()
            .HasForeignKey(o => o.AddressId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.PickupSlot)
            .WithMany()
            .HasForeignKey(o => o.PickupSlotId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(o => o.UserDiscount)
            .WithMany()
            .HasForeignKey(o => o.UserDiscountId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(o => o.AssignedStore)
            .WithMany()
            .HasForeignKey(o => o.AssignedStoreId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
