using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddServiceZones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ServiceZones",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Pincode = table.Column<string>(type: "character varying(6)", maxLength: 6, nullable: false),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Area = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
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
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ServiceZones_Pincode",
                table: "ServiceZones",
                column: "Pincode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceZones_IsActive",
                table: "ServiceZones",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceZones_AssignedStoreId",
                table: "ServiceZones",
                column: "AssignedStoreId");

            // Seed initial Navi Mumbai service zones
            migrationBuilder.InsertData(
                table: "ServiceZones",
                columns: new[] { "Id", "Name", "Pincode", "City", "Area", "Description", "IsActive", "SortOrder", "CreatedAt", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("a1b2c3d4-0001-4000-8000-000000000001"), "Nerul", "400706", "Navi Mumbai", "Nerul East & West", "Primary service zone - Nerul area", true, 1, new DateTime(2026, 4, 3, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 3, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("a1b2c3d4-0002-4000-8000-000000000002"), "Vashi", "400703", "Navi Mumbai", "Vashi Sector 1-30", "Primary service zone - Vashi area", true, 2, new DateTime(2026, 4, 3, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 3, 0, 0, 0, 0, DateTimeKind.Utc) }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ServiceZones");
        }
    }
}
