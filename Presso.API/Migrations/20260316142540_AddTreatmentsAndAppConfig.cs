using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddTreatmentsAndAppConfig : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ServiceTreatmentId",
                table: "OrderItems",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TreatmentMultiplier",
                table: "OrderItems",
                type: "numeric(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                defaultValue: 1.0m);

            migrationBuilder.AddColumn<string>(
                name: "TreatmentName",
                table: "OrderItems",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "AppConfigs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Value = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ValueType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "string"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppConfigs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ServiceTreatments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ServiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    PriceMultiplier = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceTreatments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceTreatments_Services_ServiceId",
                        column: x => x.ServiceId,
                        principalTable: "Services",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "AppConfigs",
                columns: new[] { "Id", "Description", "Key", "UpdatedAt", "Value", "ValueType" },
                values: new object[,]
                {
                    { new Guid("0add4e96-45fd-2d80-284f-d12f0806e39e"), "Evening AI tip", "ai_tip_evening", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Tomorrow is a new day! Get your clothes ready for pickup and wake up to fresh outfits.", "string" },
                    { new Guid("0bd89859-298d-d8cf-12bd-a6e4bc9d6461"), "Specialty (shoes/bags) delivery hours", "delivery_hours_specialty", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "72", "int" },
                    { new Guid("0cb65619-72d7-fd58-d2ab-e899c53f268b"), "Percent of order earned as coins", "coins_earned_percent", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "5", "int" },
                    { new Guid("21b39839-b554-1609-c576-b0b8c4ec891f"), "Express delivery flat fee ₹", "express_charge", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "30", "decimal" },
                    { new Guid("24b81d69-d74a-7550-3a18-c1c7120d5e1f"), "Active service areas", "service_areas", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "[\"Mahape\",\"Vashi\",\"Nerul\",\"Belapur\",\"Kharghar\",\"Panvel\"]", "json" },
                    { new Guid("2a62f054-66d0-479d-677a-41706a3d31ff"), "Student discount percentage", "student_discount_percent", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "20", "int" },
                    { new Guid("412aa49c-816c-a430-9e8a-9afad61dca2e"), "Coins awarded per referral (both sides)", "referral_bonus_coins", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "50", "int" },
                    { new Guid("432f5030-e44a-3381-ed39-0e1b8906193f"), "Coins needed for Gold tier", "loyalty_gold_threshold", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "500", "int" },
                    { new Guid("435ef86f-cc40-1172-786b-425d921f8611"), "Afternoon AI tip", "ai_tip_afternoon", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Don't let laundry pile up. Quick tip: Sort darks and lights before pickup for best results.", "string" },
                    { new Guid("4663a7b0-253c-1bcc-c7c4-3a7aa1f6ae54"), "Morning AI tip", "ai_tip_morning", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Start your day fresh! Schedule a pickup for your laundry and enjoy clean clothes by evening.", "string" },
                    { new Guid("4fb026df-6b74-8785-9f05-dad45e7848de"), "Express delivery hours", "delivery_hours_express", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "24", "int" },
                    { new Guid("6ad2d067-73b6-27be-9de3-28ecba0ce476"), "Rupees per coin (10 coins = ₹1)", "coin_value_rupees", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "0.1", "decimal" },
                    { new Guid("981f3ec9-cae7-dc71-e33f-64cca00bcbc6"), "Coins needed for Platinum tier", "loyalty_platinum_threshold", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "1500", "int" },
                    { new Guid("a0598e27-3a8b-c112-d1b1-e4ccc1958a04"), "Minimum garments per order", "min_order_items", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "3", "int" },
                    { new Guid("a60892bf-a210-baaf-8503-9d332340da2f"), "Night AI tip", "ai_tip_night", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Pro tip: Check your wardrobe tonight. Schedule a Presso pickup for items that need cleaning.", "string" },
                    { new Guid("cb828d04-e578-664e-5c25-d13cc019fb88"), "Standard delivery hours", "delivery_hours_standard", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "48", "int" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_ServiceTreatmentId",
                table: "OrderItems",
                column: "ServiceTreatmentId");

            migrationBuilder.CreateIndex(
                name: "IX_AppConfigs_Key",
                table: "AppConfigs",
                column: "Key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceTreatments_ServiceId",
                table: "ServiceTreatments",
                column: "ServiceId");

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_ServiceTreatments_ServiceTreatmentId",
                table: "OrderItems",
                column: "ServiceTreatmentId",
                principalTable: "ServiceTreatments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_ServiceTreatments_ServiceTreatmentId",
                table: "OrderItems");

            migrationBuilder.DropTable(
                name: "AppConfigs");

            migrationBuilder.DropTable(
                name: "ServiceTreatments");

            migrationBuilder.DropIndex(
                name: "IX_OrderItems_ServiceTreatmentId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "ServiceTreatmentId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "TreatmentMultiplier",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "TreatmentName",
                table: "OrderItems");
        }
    }
}
