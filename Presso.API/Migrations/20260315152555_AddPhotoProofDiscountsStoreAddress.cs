using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddPhotoProofDiscountsStoreAddress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "FcmTokenUpdatedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "StoreLocationId",
                table: "PickupSlots",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "AdminDiscount",
                table: "Orders",
                type: "numeric(10,2)",
                precision: 10,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "AssignedStoreId",
                table: "Orders",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeliveryPhotoUrls",
                table: "Orders",
                type: "jsonb",
                nullable: false,
                defaultValue: "[]");

            migrationBuilder.AddColumn<string>(
                name: "FacilityNotes",
                table: "Orders",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FacilityReceivedAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "OutForDeliveryAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PhotosUploadedAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PickupCompletedAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PickupPhotoCount",
                table: "Orders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "PickupPhotosBlobFolder",
                table: "Orders",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ProcessingStartedAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReadyAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RiderPickupNotes",
                table: "Orders",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserDiscountId",
                table: "Orders",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "StoreLocations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    AddressLine1 = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    AddressLine2 = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    State = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Pincode = table.Column<string>(type: "character varying(6)", maxLength: 6, nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    Phone = table.Column<string>(type: "character varying(15)", maxLength: 15, nullable: false),
                    Email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    GoogleMapsUrl = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    OpenTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    CloseTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    IsOpenSunday = table.Column<bool>(type: "boolean", nullable: false),
                    ServiceRadiusKm = table.Column<double>(type: "double precision", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsHeadquarters = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StoreLocations", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserDiscounts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Value = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    Reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UsageLimit = table.Column<int>(type: "integer", nullable: true),
                    UsageCount = table.Column<int>(type: "integer", nullable: false),
                    CreatedByAdminId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserDiscounts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserDiscounts_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000001-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000002-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000003-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000004-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000005-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000006-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000007-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000008-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000009-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000010-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000011-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000012-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000013-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000014-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000015-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000016-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000017-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000018-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000019-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000020-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000021-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000022-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000023-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000024-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000025-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000026-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000027-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000028-0000-0000-0000-000000000000"),
                column: "StoreLocationId",
                value: null);

            migrationBuilder.InsertData(
                table: "StoreLocations",
                columns: new[] { "Id", "AddressLine1", "AddressLine2", "City", "CloseTime", "CreatedAt", "Email", "GoogleMapsUrl", "IsActive", "IsHeadquarters", "IsOpenSunday", "Latitude", "Longitude", "Name", "OpenTime", "Phone", "Pincode", "ServiceRadiusKm", "State" },
                values: new object[] { new Guid("e1111111-1111-1111-1111-111111111111"), "MIDC Industrial Area", null, "Navi Mumbai", new TimeOnly(20, 0, 0), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, null, true, true, false, 19.113600000000002, 73.008200000000002, "Presso Mahape Unit", new TimeOnly(8, 0, 0), "+91 0000000000", "400709", 5.0, "Maharashtra" });

            migrationBuilder.CreateIndex(
                name: "IX_PickupSlots_StoreLocationId",
                table: "PickupSlots",
                column: "StoreLocationId");

            migrationBuilder.CreateIndex(
                name: "IX_Orders_AssignedStoreId",
                table: "Orders",
                column: "AssignedStoreId");

            migrationBuilder.CreateIndex(
                name: "IX_Orders_UserDiscountId",
                table: "Orders",
                column: "UserDiscountId");

            migrationBuilder.CreateIndex(
                name: "IX_UserDiscounts_UserId_IsActive",
                table: "UserDiscounts",
                columns: new[] { "UserId", "IsActive" });

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_StoreLocations_AssignedStoreId",
                table: "Orders",
                column: "AssignedStoreId",
                principalTable: "StoreLocations",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_UserDiscounts_UserDiscountId",
                table: "Orders",
                column: "UserDiscountId",
                principalTable: "UserDiscounts",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_PickupSlots_StoreLocations_StoreLocationId",
                table: "PickupSlots",
                column: "StoreLocationId",
                principalTable: "StoreLocations",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_StoreLocations_AssignedStoreId",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_Orders_UserDiscounts_UserDiscountId",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_PickupSlots_StoreLocations_StoreLocationId",
                table: "PickupSlots");

            migrationBuilder.DropTable(
                name: "StoreLocations");

            migrationBuilder.DropTable(
                name: "UserDiscounts");

            migrationBuilder.DropIndex(
                name: "IX_PickupSlots_StoreLocationId",
                table: "PickupSlots");

            migrationBuilder.DropIndex(
                name: "IX_Orders_AssignedStoreId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_UserDiscountId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "FcmTokenUpdatedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "StoreLocationId",
                table: "PickupSlots");

            migrationBuilder.DropColumn(
                name: "AdminDiscount",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "AssignedStoreId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveryPhotoUrls",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "FacilityNotes",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "FacilityReceivedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "OutForDeliveryAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PhotosUploadedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PickupCompletedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PickupPhotoCount",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PickupPhotosBlobFolder",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ProcessingStartedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ReadyAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "RiderPickupNotes",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "UserDiscountId",
                table: "Orders");
        }
    }
}
