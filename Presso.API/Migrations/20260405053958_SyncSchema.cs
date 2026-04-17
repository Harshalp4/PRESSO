using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class SyncSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("a1111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("a2222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("a3333333-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("b1111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("b2222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("b3333333-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("c1111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("c2222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("c3333333-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"));

            migrationBuilder.CreateTable(
                name: "ServiceZones",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Pincode = table.Column<string>(type: "text", nullable: false),
                    City = table.Column<string>(type: "text", nullable: false),
                    Area = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    AssignedStoreId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceZones", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceZones_StoreLocations_AssignedStoreId",
                        column: x => x.AssignedStoreId,
                        principalTable: "StoreLocations",
                        principalColumn: "Id");
                });

            migrationBuilder.InsertData(
                table: "Services",
                columns: new[] { "Id", "Category", "CreatedAt", "Description", "IconUrl", "IsActive", "Name", "PricePerPiece", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("10000000-0000-0000-0000-000000000001"), "clothes", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Machine wash + professional steam press", null, true, "Wash + Iron", 29m, 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000002"), "clothes", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Machine wash + neatly folded, no ironing", null, true, "Wash + Fold", 19m, 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000003"), "clothes", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Premium solvent-based, delicate fabrics", null, true, "Dry Clean", 149m, 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000004"), "clothes", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Professional steam press, no washing", null, true, "Iron Only", 12m, 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000005"), "clothes", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Hand wash for silk, wool, designer wear", null, true, "Premium Hand Wash", 99m, 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000006"), "home_linen", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Wash + iron, king/queen/single sizes", null, true, "Bedsheet + Pillow Covers", 79m, 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000007"), "home_linen", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Wash + iron, sized by panel count", null, true, "Curtains + Drapes", 149m, 7, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000008"), "specialty", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Hand wash / dry clean + careful pressing", null, true, "Saree + Ethnic Wear", 99m, 8, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-000000000009"), "specialty", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Sweaters, blankets, jackets — gentle care", null, true, "Woolen + Winter Wear", 149m, 9, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-00000000000a"), "specialty", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Handbags, backpacks, leather accessories", null, true, "Bags + Leather Goods", 299m, 10, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("10000000-0000-0000-0000-00000000000b"), "specialty", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Deep clean + deodorise, 48–72 hrs", null, true, "Shoe Cleaning", 199m, 11, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.InsertData(
                table: "GarmentTypes",
                columns: new[] { "Id", "CreatedAt", "Name", "PriceOverride", "ServiceId", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("20000000-0000-0000-0000-000000000101"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Shirt", null, new Guid("10000000-0000-0000-0000-000000000001"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000102"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "T-Shirt", null, new Guid("10000000-0000-0000-0000-000000000001"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000103"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Pant / Jeans", null, new Guid("10000000-0000-0000-0000-000000000001"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000104"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Kurta", null, new Guid("10000000-0000-0000-0000-000000000001"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000105"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Saree", 49m, new Guid("10000000-0000-0000-0000-000000000001"), 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000201"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Shirt", null, new Guid("10000000-0000-0000-0000-000000000002"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000202"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "T-Shirt", null, new Guid("10000000-0000-0000-0000-000000000002"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000203"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Pant / Jeans", null, new Guid("10000000-0000-0000-0000-000000000002"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000204"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Towel", null, new Guid("10000000-0000-0000-0000-000000000002"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000301"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Suit (2pc)", 349m, new Guid("10000000-0000-0000-0000-000000000003"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000302"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Blazer", 249m, new Guid("10000000-0000-0000-0000-000000000003"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000303"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Jacket", 299m, new Guid("10000000-0000-0000-0000-000000000003"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000304"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Saree (Silk)", 199m, new Guid("10000000-0000-0000-0000-000000000003"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000305"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Lehenga", 499m, new Guid("10000000-0000-0000-0000-000000000003"), 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000401"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Shirt", null, new Guid("10000000-0000-0000-0000-000000000004"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000402"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Pant / Jeans", null, new Guid("10000000-0000-0000-0000-000000000004"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000403"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Kurta", null, new Guid("10000000-0000-0000-0000-000000000004"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000404"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Saree", 20m, new Guid("10000000-0000-0000-0000-000000000004"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000501"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Silk Garment", null, new Guid("10000000-0000-0000-0000-000000000005"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000502"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Woolen", 129m, new Guid("10000000-0000-0000-0000-000000000005"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000503"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Delicate Fabric", null, new Guid("10000000-0000-0000-0000-000000000005"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000601"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Single Bedsheet Set", null, new Guid("10000000-0000-0000-0000-000000000006"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000602"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Double Bedsheet Set", 99m, new Guid("10000000-0000-0000-0000-000000000006"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000603"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "King Bedsheet Set", 119m, new Guid("10000000-0000-0000-0000-000000000006"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000604"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Pillow Cover (pair)", 39m, new Guid("10000000-0000-0000-0000-000000000006"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000701"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Small Panel (< 5ft)", null, new Guid("10000000-0000-0000-0000-000000000007"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000702"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Medium Panel (5–7ft)", 179m, new Guid("10000000-0000-0000-0000-000000000007"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000703"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Large Panel (> 7ft)", 229m, new Guid("10000000-0000-0000-0000-000000000007"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000801"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Cotton Saree", null, new Guid("10000000-0000-0000-0000-000000000008"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000802"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Silk Saree", 199m, new Guid("10000000-0000-0000-0000-000000000008"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000803"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Lehenga / Sherwani", 349m, new Guid("10000000-0000-0000-0000-000000000008"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000804"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Ethnic Kurta Set", 149m, new Guid("10000000-0000-0000-0000-000000000008"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000901"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Sweater", null, new Guid("10000000-0000-0000-0000-000000000009"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000902"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Jacket / Coat", 249m, new Guid("10000000-0000-0000-0000-000000000009"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000000903"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Blanket", 299m, new Guid("10000000-0000-0000-0000-000000000009"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001001"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Handbag", null, new Guid("10000000-0000-0000-0000-00000000000a"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001002"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Backpack", 249m, new Guid("10000000-0000-0000-0000-00000000000a"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001003"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Wallet / Belt", 149m, new Guid("10000000-0000-0000-0000-00000000000a"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001101"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Sneakers", null, new Guid("10000000-0000-0000-0000-00000000000b"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001102"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Leather Shoes", 249m, new Guid("10000000-0000-0000-0000-00000000000b"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001103"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Sandals", 149m, new Guid("10000000-0000-0000-0000-00000000000b"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001104"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Heels", 199m, new Guid("10000000-0000-0000-0000-00000000000b"), 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001105"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Boots / Ankle Boots", 299m, new Guid("10000000-0000-0000-0000-00000000000b"), 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("20000000-0000-0000-0000-000000001106"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Ethnic / Kolhapuri", 179m, new Guid("10000000-0000-0000-0000-00000000000b"), 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.InsertData(
                table: "ServiceTreatments",
                columns: new[] { "Id", "CreatedAt", "Description", "IsActive", "Name", "PriceMultiplier", "ServiceId", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("30000000-0000-0000-0000-000000000001"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Surface clean + conditioning", true, "Clean Only", 1.0m, new Guid("10000000-0000-0000-0000-00000000000a"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("30000000-0000-0000-0000-000000000002"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Deep clean + color restoration", true, "Deep Clean", 1.5m, new Guid("10000000-0000-0000-0000-00000000000a"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("30000000-0000-0000-0000-000000000003"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Full restoration + waterproofing", true, "Full Restore", 2.0m, new Guid("10000000-0000-0000-0000-00000000000a"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("30000000-0000-0000-0000-000000000004"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Surface clean + deodorize", true, "Basic Clean", 1.0m, new Guid("10000000-0000-0000-0000-00000000000b"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("30000000-0000-0000-0000-000000000005"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Deep clean + stain removal + deodorize", true, "Deep Clean", 1.5m, new Guid("10000000-0000-0000-0000-00000000000b"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("30000000-0000-0000-0000-000000000006"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Full restore + sole whitening + protection", true, "Premium Restore", 2.0m, new Guid("10000000-0000-0000-0000-00000000000b"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ServiceZones_AssignedStoreId",
                table: "ServiceZones",
                column: "AssignedStoreId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ServiceZones");

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000101"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000102"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000103"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000104"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000105"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000201"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000202"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000203"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000204"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000301"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000302"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000303"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000304"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000305"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000401"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000402"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000403"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000404"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000501"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000502"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000503"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000601"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000602"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000603"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000604"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000701"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000702"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000703"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000801"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000802"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000803"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000804"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000901"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000902"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000000903"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001001"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001002"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001003"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001101"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001102"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001103"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001104"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001105"));

            migrationBuilder.DeleteData(
                table: "GarmentTypes",
                keyColumn: "Id",
                keyValue: new Guid("20000000-0000-0000-0000-000000001106"));

            migrationBuilder.DeleteData(
                table: "ServiceTreatments",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000001"));

            migrationBuilder.DeleteData(
                table: "ServiceTreatments",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000002"));

            migrationBuilder.DeleteData(
                table: "ServiceTreatments",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000003"));

            migrationBuilder.DeleteData(
                table: "ServiceTreatments",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000004"));

            migrationBuilder.DeleteData(
                table: "ServiceTreatments",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000005"));

            migrationBuilder.DeleteData(
                table: "ServiceTreatments",
                keyColumn: "Id",
                keyValue: new Guid("30000000-0000-0000-0000-000000000006"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000001"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000002"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000003"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000004"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000005"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000006"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000007"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000008"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-000000000009"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-00000000000a"));

            migrationBuilder.DeleteData(
                table: "Services",
                keyColumn: "Id",
                keyValue: new Guid("10000000-0000-0000-0000-00000000000b"));

            migrationBuilder.InsertData(
                table: "Services",
                columns: new[] { "Id", "Category", "CreatedAt", "Description", "IconUrl", "IsActive", "Name", "PricePerPiece", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), "Laundry", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Regular wash and fold service", null, true, "Wash & Fold", 15m, 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("22222222-2222-2222-2222-222222222222"), "Ironing", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Professional ironing service", null, true, "Iron Only", 10m, 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("33333333-3333-3333-3333-333333333333"), "DryClean", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Premium dry cleaning service", null, true, "Dry Clean", 80m, 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.InsertData(
                table: "GarmentTypes",
                columns: new[] { "Id", "CreatedAt", "Name", "PriceOverride", "ServiceId", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("a1111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Shirt", null, new Guid("11111111-1111-1111-1111-111111111111"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("a2222222-2222-2222-2222-222222222222"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trouser", null, new Guid("11111111-1111-1111-1111-111111111111"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("a3333333-3333-3333-3333-333333333333"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Bedsheet", 30m, new Guid("11111111-1111-1111-1111-111111111111"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("b1111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Shirt", null, new Guid("22222222-2222-2222-2222-222222222222"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("b2222222-2222-2222-2222-222222222222"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trouser", null, new Guid("22222222-2222-2222-2222-222222222222"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("b3333333-3333-3333-3333-333333333333"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Saree", 20m, new Guid("22222222-2222-2222-2222-222222222222"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("c1111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Suit (2pc)", 250m, new Guid("33333333-3333-3333-3333-333333333333"), 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("c2222222-2222-2222-2222-222222222222"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Jacket", 200m, new Guid("33333333-3333-3333-3333-333333333333"), 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("c3333333-3333-3333-3333-333333333333"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Blanket", 300m, new Guid("33333333-3333-3333-3333-333333333333"), 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });
        }
    }
}
