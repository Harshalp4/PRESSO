namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class GarmentTypeConfiguration : IEntityTypeConfiguration<GarmentType>
{
    private static readonly DateTime Epoch = new(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    // Shorthand counter for generating deterministic GUIDs
    private static Guid G(int n) => Guid.Parse($"20000000-0000-0000-0000-{n:D12}");

    public void Configure(EntityTypeBuilder<GarmentType> builder)
    {
        builder.HasKey(g => g.Id);
        builder.Property(g => g.Name).HasMaxLength(100).IsRequired();
        builder.Property(g => g.PriceOverride).HasPrecision(10, 2);

        builder.HasOne(g => g.Service)
            .WithMany(s => s.GarmentTypes)
            .HasForeignKey(g => g.ServiceId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Property(g => g.Emoji).HasMaxLength(10);

        builder.HasData(
            // ── Wash + Iron (from ₹29) ──────────────────────────────────────
            Gt(G(101), ServiceConfiguration.WashIronId, "Shirt", null, 1, "\U0001F455"),          // 👕
            Gt(G(102), ServiceConfiguration.WashIronId, "T-Shirt", null, 2, "\U0001F455"),         // 👕
            Gt(G(103), ServiceConfiguration.WashIronId, "Pant / Jeans", null, 3, "\U0001F456"),    // 👖
            Gt(G(104), ServiceConfiguration.WashIronId, "Kurta", null, 4, "\U0001F97B"),           // 🥻
            Gt(G(105), ServiceConfiguration.WashIronId, "Saree", 49, 5, "\U0001F97B"),             // 🥻

            // ── Wash + Fold (from ₹19) ──────────────────────────────────────
            Gt(G(201), ServiceConfiguration.WashFoldId, "Shirt", null, 1, "\U0001F455"),           // 👕
            Gt(G(202), ServiceConfiguration.WashFoldId, "T-Shirt", null, 2, "\U0001F455"),         // 👕
            Gt(G(203), ServiceConfiguration.WashFoldId, "Pant / Jeans", null, 3, "\U0001F456"),    // 👖
            Gt(G(204), ServiceConfiguration.WashFoldId, "Towel", null, 4, "\U0001F9F4"),           // 🧴

            // ── Dry Clean (from ₹149) ───────────────────────────────────────
            Gt(G(301), ServiceConfiguration.DryCleanId, "Suit (2pc)", 349, 1, "\U0001F935"),       // 🤵
            Gt(G(302), ServiceConfiguration.DryCleanId, "Blazer", 249, 2, "\U0001F9E5"),           // 🧥
            Gt(G(303), ServiceConfiguration.DryCleanId, "Jacket", 299, 3, "\U0001F9E5"),           // 🧥
            Gt(G(304), ServiceConfiguration.DryCleanId, "Saree (Silk)", 199, 4, "\U0001F97B"),     // 🥻
            Gt(G(305), ServiceConfiguration.DryCleanId, "Lehenga", 499, 5, "\U0001F457"),          // 👗

            // ── Iron Only (from ₹12) ────────────────────────────────────────
            Gt(G(401), ServiceConfiguration.IronOnlyId, "Shirt", null, 1, "\U0001F455"),           // 👕
            Gt(G(402), ServiceConfiguration.IronOnlyId, "Pant / Jeans", null, 2, "\U0001F456"),    // 👖
            Gt(G(403), ServiceConfiguration.IronOnlyId, "Kurta", null, 3, "\U0001F97B"),           // 🥻
            Gt(G(404), ServiceConfiguration.IronOnlyId, "Saree", 20, 4, "\U0001F97B"),             // 🥻

            // ── Premium Hand Wash (from ₹99) ────────────────────────────────
            Gt(G(501), ServiceConfiguration.PremiumHandWashId, "Silk Garment", null, 1, "\U0001F9F5"), // 🧵
            Gt(G(502), ServiceConfiguration.PremiumHandWashId, "Woolen", 129, 2, "\U0001F9F6"),        // 🧶
            Gt(G(503), ServiceConfiguration.PremiumHandWashId, "Delicate Fabric", null, 3, "\U0001F9F5"), // 🧵

            // ── Bedsheet + Pillow Covers (from ₹79) ─────────────────────────
            Gt(G(601), ServiceConfiguration.BedsheetPillowId, "Single Bedsheet Set", null, 1, "\U0001F6CF\uFE0F"),  // 🛏️
            Gt(G(602), ServiceConfiguration.BedsheetPillowId, "Double Bedsheet Set", 99, 2, "\U0001F6CF\uFE0F"),     // 🛏️
            Gt(G(603), ServiceConfiguration.BedsheetPillowId, "King Bedsheet Set", 119, 3, "\U0001F6CF\uFE0F"),      // 🛏️
            Gt(G(604), ServiceConfiguration.BedsheetPillowId, "Pillow Cover (pair)", 39, 4, "\U0001F6CC"),            // 🛌

            // ── Curtains + Drapes (from ₹149) ───────────────────────────────
            Gt(G(701), ServiceConfiguration.CurtainsId, "Small Panel (< 5ft)", null, 1, "\U0001FA9F"),   // 🪟
            Gt(G(702), ServiceConfiguration.CurtainsId, "Medium Panel (5\u20137ft)", 179, 2, "\U0001FA9F"), // 🪟
            Gt(G(703), ServiceConfiguration.CurtainsId, "Large Panel (> 7ft)", 229, 3, "\U0001FA9F"),     // 🪟

            // ── Saree + Ethnic Wear (from ₹99) ──────────────────────────────
            Gt(G(801), ServiceConfiguration.SareeEthnicId, "Cotton Saree", null, 1, "\U0001F97B"),         // 🥻
            Gt(G(802), ServiceConfiguration.SareeEthnicId, "Silk Saree", 199, 2, "\U0001F97B"),            // 🥻
            Gt(G(803), ServiceConfiguration.SareeEthnicId, "Lehenga / Sherwani", 349, 3, "\U0001F457"),    // 👗
            Gt(G(804), ServiceConfiguration.SareeEthnicId, "Ethnic Kurta Set", 149, 4, "\U0001F97B"),      // 🥻

            // ── Woolen + Winter Wear (from ₹149) ────────────────────────────
            Gt(G(901), ServiceConfiguration.WoolenWinterId, "Sweater", null, 1, "\U0001F9E3"),             // 🧣
            Gt(G(902), ServiceConfiguration.WoolenWinterId, "Jacket / Coat", 249, 2, "\U0001F9E5"),        // 🧥
            Gt(G(903), ServiceConfiguration.WoolenWinterId, "Blanket", 299, 3, "\U0001F9E3"),              // 🧣

            // ── Bags + Leather Goods (from ₹299) ────────────────────────────
            Gt(G(1001), ServiceConfiguration.BagsLeatherId, "Handbag", null, 1, "\U0001F45C"),             // 👜
            Gt(G(1002), ServiceConfiguration.BagsLeatherId, "Backpack", 249, 2, "\U0001F392"),             // 🎒
            Gt(G(1003), ServiceConfiguration.BagsLeatherId, "Wallet / Belt", 149, 3, "\U0001F45B"),        // 👛

            // ── Shoe Cleaning (from ₹199) ───────────────────────────────────
            Gt(G(1101), ServiceConfiguration.ShoeCleanId, "Sneakers", null, 1, "\U0001F45F"),              // 👟
            Gt(G(1102), ServiceConfiguration.ShoeCleanId, "Leather Shoes", 249, 2, "\U0001F45E"),          // 👞
            Gt(G(1103), ServiceConfiguration.ShoeCleanId, "Sandals", 149, 3, "\U0001FA74"),                // 🩴
            Gt(G(1104), ServiceConfiguration.ShoeCleanId, "Heels", 199, 4, "\U0001F460"),                  // 👠
            Gt(G(1105), ServiceConfiguration.ShoeCleanId, "Boots / Ankle Boots", 299, 5, "\U0001F97E"),    // 🥾
            Gt(G(1106), ServiceConfiguration.ShoeCleanId, "Ethnic / Kolhapuri", 179, 6, "\U0001F97F")      // 🥿
        );
    }

    private static GarmentType Gt(Guid id, Guid serviceId, string name, decimal? priceOverride, int order, string? emoji = null) => new()
    {
        Id = id, ServiceId = serviceId, Name = name, Emoji = emoji,
        PriceOverride = priceOverride, SortOrder = order,
        CreatedAt = Epoch, UpdatedAt = Epoch
    };
}
