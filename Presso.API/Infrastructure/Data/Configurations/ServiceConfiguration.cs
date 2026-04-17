namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class ServiceConfiguration : IEntityTypeConfiguration<Service>
{
    // ── Well-known Service IDs ──────────────────────────────────────────────
    public static readonly Guid WashIronId       = Guid.Parse("10000000-0000-0000-0000-000000000001");
    public static readonly Guid WashFoldId       = Guid.Parse("10000000-0000-0000-0000-000000000002");
    public static readonly Guid DryCleanId       = Guid.Parse("10000000-0000-0000-0000-000000000003");
    public static readonly Guid IronOnlyId       = Guid.Parse("10000000-0000-0000-0000-000000000004");
    public static readonly Guid PremiumHandWashId = Guid.Parse("10000000-0000-0000-0000-000000000005");
    public static readonly Guid BedsheetPillowId = Guid.Parse("10000000-0000-0000-0000-000000000006");
    public static readonly Guid CurtainsId       = Guid.Parse("10000000-0000-0000-0000-000000000007");
    public static readonly Guid SareeEthnicId    = Guid.Parse("10000000-0000-0000-0000-000000000008");
    public static readonly Guid WoolenWinterId   = Guid.Parse("10000000-0000-0000-0000-000000000009");
    public static readonly Guid BagsLeatherId    = Guid.Parse("10000000-0000-0000-0000-00000000000a");
    public static readonly Guid ShoeCleanId      = Guid.Parse("10000000-0000-0000-0000-00000000000b");

    private static readonly DateTime Epoch = new(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    public void Configure(EntityTypeBuilder<Service> builder)
    {
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Name).HasMaxLength(100).IsRequired();
        builder.Property(s => s.Description).HasMaxLength(500);
        builder.Property(s => s.Category).HasMaxLength(50).IsRequired();
        builder.Property(s => s.PricePerPiece).HasPrecision(10, 2);
        builder.Property(s => s.IconUrl).HasMaxLength(512);
        builder.Property(s => s.Emoji).HasMaxLength(10);

        builder.HasData(
            // ── Clothes ─────────────────────────────────────────────────────
            S(WashIronId, "Wash + Iron", "Machine wash + professional steam press", "clothes", 29, 1, "\U0001F455"),   // 👕
            S(WashFoldId, "Wash + Fold", "Machine wash + neatly folded, no ironing", "clothes", 19, 2, "\U0001F454"),   // 👔
            S(DryCleanId, "Dry Clean", "Premium solvent-based, delicate fabrics", "clothes", 149, 3, "\u2728"),          // ✨
            S(IronOnlyId, "Iron Only", "Professional steam press, no washing", "clothes", 12, 4, "\u2668\uFE0F"),        // ♨️
            S(PremiumHandWashId, "Premium Hand Wash", "Hand wash for silk, wool, designer wear", "clothes", 99, 5, "\U0001F9F6"), // 🧶

            // ── Home Linen ──────────────────────────────────────────────────
            S(BedsheetPillowId, "Bedsheet + Pillow Covers", "Wash + iron, king/queen/single sizes", "home_linen", 79, 6, "\U0001F6CC"),  // 🛌
            S(CurtainsId, "Curtains + Drapes", "Wash + iron, sized by panel count", "home_linen", 149, 7, "\U0001FA9F"),                   // 🪟

            // ── Specialty ───────────────────────────────────────────────────
            S(SareeEthnicId, "Saree + Ethnic Wear", "Hand wash / dry clean + careful pressing", "specialty", 99, 8, "\U0001F97B"),   // 🥻
            S(WoolenWinterId, "Woolen + Winter Wear", "Sweaters, blankets, jackets — gentle care", "specialty", 149, 9, "\U0001F9E3"), // 🧣
            S(BagsLeatherId, "Bags + Leather Goods", "Handbags, backpacks, leather accessories", "specialty", 299, 10, "\U0001F45C"),  // 👜
            S(ShoeCleanId, "Shoe Cleaning", "Deep clean + deodorise, 48–72 hrs", "specialty", 199, 11, "\U0001F45F")                    // 👟
        );
    }

    private static Service S(Guid id, string name, string desc, string cat, decimal price, int order, string? emoji = null) => new()
    {
        Id = id, Name = name, Description = desc, Category = cat,
        PricePerPiece = price, SortOrder = order, IsActive = true,
        Emoji = emoji, CreatedAt = Epoch, UpdatedAt = Epoch
    };
}
