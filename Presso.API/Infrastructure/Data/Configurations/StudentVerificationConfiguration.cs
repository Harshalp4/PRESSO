namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class StudentVerificationConfiguration : IEntityTypeConfiguration<StudentVerification>
{
    public void Configure(EntityTypeBuilder<StudentVerification> builder)
    {
        builder.HasKey(s => s.Id);
        builder.HasIndex(s => s.UserId);
        builder.Property(s => s.IdPhotoUrl).HasMaxLength(512).IsRequired();
        builder.Property(s => s.ReviewNote).HasMaxLength(500);

        builder.HasOne(s => s.User)
            .WithMany()
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
