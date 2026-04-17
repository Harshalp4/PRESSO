namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class ServiceTreatmentConfiguration : IEntityTypeConfiguration<ServiceTreatment>
{
    private static readonly DateTime Epoch = new(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    private static Guid T(int n) => Guid.Parse($"30000000-0000-0000-0000-{n:D12}");

    public void Configure(EntityTypeBuilder<ServiceTreatment> builder)
    {
        builder.HasKey(t => t.Id);
        builder.Property(t => t.Name).HasMaxLength(100).IsRequired();
        builder.Property(t => t.Description).HasMaxLength(500);
        builder.Property(t => t.PriceMultiplier).HasPrecision(5, 2);

        builder.HasOne(t => t.Service)
            .WithMany(s => s.Treatments)
            .HasForeignKey(t => t.ServiceId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasData(
            // ── Bags + Leather treatments ────────────────────────────────────
            Tr(T(1), ServiceConfiguration.BagsLeatherId, "Clean Only", "Surface clean + conditioning", 1.0m, 1),
            Tr(T(2), ServiceConfiguration.BagsLeatherId, "Deep Clean", "Deep clean + color restoration", 1.5m, 2),
            Tr(T(3), ServiceConfiguration.BagsLeatherId, "Full Restore", "Full restoration + waterproofing", 2.0m, 3),

            // ── Shoe Cleaning treatments ─────────────────────────────────────
            Tr(T(4), ServiceConfiguration.ShoeCleanId, "Basic Clean", "Surface clean + deodorize", 1.0m, 1),
            Tr(T(5), ServiceConfiguration.ShoeCleanId, "Deep Clean", "Deep clean + stain removal + deodorize", 1.5m, 2),
            Tr(T(6), ServiceConfiguration.ShoeCleanId, "Premium Restore", "Full restore + sole whitening + protection", 2.0m, 3)
        );
    }

    private static ServiceTreatment Tr(Guid id, Guid serviceId, string name, string desc, decimal mult, int order) => new()
    {
        Id = id, ServiceId = serviceId, Name = name, Description = desc,
        PriceMultiplier = mult, SortOrder = order, IsActive = true,
        CreatedAt = Epoch, UpdatedAt = Epoch
    };
}
