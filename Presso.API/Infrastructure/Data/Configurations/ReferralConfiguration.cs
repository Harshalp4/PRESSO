namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class ReferralConfiguration : IEntityTypeConfiguration<Referral>
{
    public void Configure(EntityTypeBuilder<Referral> builder)
    {
        builder.HasKey(r => r.Id);
        builder.HasIndex(r => new { r.ReferrerUserId, r.ReferredUserId }).IsUnique();
        builder.Property(r => r.ReferralCode).HasMaxLength(8).IsRequired();

        builder.HasOne(r => r.ReferrerUser)
            .WithMany()
            .HasForeignKey(r => r.ReferrerUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.ReferredUser)
            .WithMany()
            .HasForeignKey(r => r.ReferredUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
