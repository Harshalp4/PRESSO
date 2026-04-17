namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class RiderConfiguration : IEntityTypeConfiguration<Rider>
{
    public void Configure(EntityTypeBuilder<Rider> builder)
    {
        builder.HasKey(r => r.Id);
        builder.HasIndex(r => r.UserId).IsUnique();
        builder.Property(r => r.VehicleNumber).HasMaxLength(20);
        builder.Property(r => r.TodayEarnings).HasPrecision(10, 2);

        builder.Property(r => r.Status).HasConversion<int>();
        builder.Property(r => r.RejectionReason).HasMaxLength(500);
        builder.Property(r => r.AdminNotes).HasMaxLength(2000);
        builder.HasIndex(r => r.Status);

        builder.HasOne(r => r.User)
            .WithOne(u => u.Rider)
            .HasForeignKey<Rider>(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
