namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class OrderAssignmentConfiguration : IEntityTypeConfiguration<OrderAssignment>
{
    public void Configure(EntityTypeBuilder<OrderAssignment> builder)
    {
        builder.HasKey(oa => oa.Id);
        builder.HasIndex(oa => new { oa.OrderId, oa.Type });
        builder.HasIndex(oa => new { oa.RiderId, oa.Status });

        // Postgres xmin system column as concurrency token — first Accept wins.
        builder.Property<uint>("xmin")
            .HasColumnName("xmin")
            .HasColumnType("xid")
            .ValueGeneratedOnAddOrUpdate()
            .IsConcurrencyToken();

        builder.HasOne(oa => oa.Order)
            .WithMany(o => o.Assignments)
            .HasForeignKey(oa => oa.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(oa => oa.Rider)
            .WithMany(r => r.Assignments)
            .HasForeignKey(oa => oa.RiderId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
