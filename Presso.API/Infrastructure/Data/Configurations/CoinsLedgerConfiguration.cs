namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class CoinsLedgerConfiguration : IEntityTypeConfiguration<CoinsLedger>
{
    public void Configure(EntityTypeBuilder<CoinsLedger> builder)
    {
        builder.HasKey(c => c.Id);
        builder.HasIndex(c => c.UserId);
        builder.Property(c => c.Description).HasMaxLength(200).IsRequired();

        builder.HasOne(c => c.User)
            .WithMany(u => u.CoinsLedgers)
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.Order)
            .WithMany()
            .HasForeignKey(c => c.OrderId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
