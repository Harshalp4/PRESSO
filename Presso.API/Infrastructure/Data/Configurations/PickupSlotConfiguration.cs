namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class PickupSlotConfiguration : IEntityTypeConfiguration<PickupSlot>
{
    public void Configure(EntityTypeBuilder<PickupSlot> builder)
    {
        builder.HasKey(s => s.Id);
        // A template is uniquely identified by its time window.
        builder.HasIndex(s => new { s.StartTime, s.EndTime }).IsUnique();

        builder.HasOne(s => s.StoreLocation)
            .WithMany()
            .HasForeignKey(s => s.StoreLocationId)
            .OnDelete(DeleteBehavior.SetNull);

        var seedTimestamp = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        builder.HasData(
            new PickupSlot
            {
                Id = Guid.Parse("d0000001-0000-0000-0000-000000000000"),
                StartTime = new TimeOnly(8, 0),
                EndTime = new TimeOnly(10, 0),
                MaxOrders = 10,
                IsActive = true,
                SortOrder = 1,
                CreatedAt = seedTimestamp,
                UpdatedAt = seedTimestamp,
            },
            new PickupSlot
            {
                Id = Guid.Parse("d0000002-0000-0000-0000-000000000000"),
                StartTime = new TimeOnly(10, 0),
                EndTime = new TimeOnly(12, 0),
                MaxOrders = 10,
                IsActive = true,
                SortOrder = 2,
                CreatedAt = seedTimestamp,
                UpdatedAt = seedTimestamp,
            },
            new PickupSlot
            {
                Id = Guid.Parse("d0000003-0000-0000-0000-000000000000"),
                StartTime = new TimeOnly(14, 0),
                EndTime = new TimeOnly(16, 0),
                MaxOrders = 10,
                IsActive = true,
                SortOrder = 3,
                CreatedAt = seedTimestamp,
                UpdatedAt = seedTimestamp,
            },
            new PickupSlot
            {
                Id = Guid.Parse("d0000004-0000-0000-0000-000000000000"),
                StartTime = new TimeOnly(16, 0),
                EndTime = new TimeOnly(18, 0),
                MaxOrders = 10,
                IsActive = true,
                SortOrder = 4,
                CreatedAt = seedTimestamp,
                UpdatedAt = seedTimestamp,
            }
        );
    }
}
