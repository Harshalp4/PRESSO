namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasKey(u => u.Id);
        builder.HasIndex(u => u.FirebaseUid).IsUnique();
        builder.HasIndex(u => u.Phone).IsUnique();
        builder.HasIndex(u => u.ReferralCode).IsUnique();

        builder.Property(u => u.FirebaseUid).HasMaxLength(128).IsRequired();
        builder.Property(u => u.Phone).HasMaxLength(15).IsRequired();
        builder.Property(u => u.Name).HasMaxLength(100);
        builder.Property(u => u.Email).HasMaxLength(256);
        builder.Property(u => u.ReferralCode).HasMaxLength(8).IsRequired();
        builder.Property(u => u.FcmToken).HasMaxLength(512);
        builder.Property(u => u.ProfilePhotoUrl).HasMaxLength(512);
    }
}
