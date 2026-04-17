namespace Presso.API.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Presso.API.Domain.Entities;

public class AppConfigConfiguration : IEntityTypeConfiguration<AppConfig>
{
    public void Configure(EntityTypeBuilder<AppConfig> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Key).HasMaxLength(100).IsRequired();
        builder.HasIndex(c => c.Key).IsUnique();
        builder.Property(c => c.Value).HasMaxLength(4000).IsRequired();
        builder.Property(c => c.Description).HasMaxLength(500);
        builder.Property(c => c.ValueType).HasMaxLength(20).HasDefaultValue("string");

        var ts = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        builder.HasData(
            Cfg("coin_value_rupees", "0.1", "decimal", "Rupees per coin (10 coins = ₹1)", ts),
            Cfg("student_discount_percent", "20", "int", "Student discount percentage", ts),
            Cfg("express_charge", "30", "decimal", "Express delivery flat fee ₹", ts),
            Cfg("delivery_hours_standard", "48", "int", "Standard delivery hours", ts),
            Cfg("delivery_hours_specialty", "72", "int", "Specialty (shoes/bags) delivery hours", ts),
            Cfg("delivery_hours_express", "24", "int", "Express delivery hours", ts),
            Cfg("referral_bonus_coins", "50", "int", "Coins awarded per referral (both sides)", ts),
            Cfg("coins_earned_percent", "5", "int", "Percent of order earned as coins", ts),
            Cfg("min_order_items", "3", "int", "Minimum garments per order", ts),
            Cfg("loyalty_gold_threshold", "500", "int", "Coins needed for Gold tier", ts),
            Cfg("loyalty_platinum_threshold", "1500", "int", "Coins needed for Platinum tier", ts),
            Cfg("service_areas", "[\"Mahape\",\"Vashi\",\"Nerul\",\"Belapur\",\"Kharghar\",\"Panvel\"]", "json", "Active service areas", ts),
            Cfg("ai_tip_morning", "Start your day fresh! Schedule a pickup for your laundry and enjoy clean clothes by evening.", "string", "Morning AI tip", ts),
            Cfg("ai_tip_afternoon", "Don't let laundry pile up. Quick tip: Sort darks and lights before pickup for best results.", "string", "Afternoon AI tip", ts),
            Cfg("ai_tip_evening", "Tomorrow is a new day! Get your clothes ready for pickup and wake up to fresh outfits.", "string", "Evening AI tip", ts),
            Cfg("ai_tip_night", "Pro tip: Check your wardrobe tonight. Schedule a Presso pickup for items that need cleaning.", "string", "Night AI tip", ts)
        );
    }

    private static AppConfig Cfg(string key, string value, string type, string desc, DateTime ts)
    {
        // Use deterministic GUIDs based on key name for stable seeding
        var id = new Guid(System.Security.Cryptography.MD5.HashData(
            System.Text.Encoding.UTF8.GetBytes($"appconfig_{key}")));
        return new AppConfig { Id = id, Key = key, Value = value, ValueType = type, Description = desc, UpdatedAt = ts };
    }
}
