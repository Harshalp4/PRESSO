namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class RiderPayoutConfiguration : IEntityTypeConfiguration<RiderPayout>
{
    public void Configure(EntityTypeBuilder<RiderPayout> builder)
    {
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Amount).HasPrecision(10, 2);
        builder.Property(p => p.Reference).HasMaxLength(200);
        builder.Property(p => p.Notes).HasMaxLength(500);
        builder.HasIndex(p => new { p.RiderId, p.PeriodStart });
        builder.HasIndex(p => p.Status);

        builder.HasOne(p => p.Rider)
            .WithMany()
            .HasForeignKey(p => p.RiderId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
