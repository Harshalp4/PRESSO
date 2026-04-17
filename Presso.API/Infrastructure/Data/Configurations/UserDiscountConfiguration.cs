namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class UserDiscountConfiguration : IEntityTypeConfiguration<UserDiscount>
{
    public void Configure(EntityTypeBuilder<UserDiscount> builder)
    {
        builder.HasKey(d => d.Id);
        builder.HasIndex(d => new { d.UserId, d.IsActive });
        builder.Property(d => d.Value).HasPrecision(10, 2);
        builder.Property(d => d.Reason).HasMaxLength(500).IsRequired();

        builder.HasOne(d => d.User)
            .WithMany()
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
