using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class RefactorPickupSlotsToTemplates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Add the new Orders.PickupDate column up front so the next
            //    step can backfill into it before we lose the source data.
            migrationBuilder.AddColumn<DateOnly>(
                name: "PickupDate",
                table: "Orders",
                type: "date",
                nullable: true);

            // 2. Backfill PickupDate from the legacy per-date slot rows so
            //    existing orders don't lose the day they booked for.
            migrationBuilder.Sql(@"
                UPDATE ""Orders"" o
                SET ""PickupDate"" = ps.""Date""
                FROM ""PickupSlots"" ps
                WHERE o.""PickupSlotId"" = ps.""Id"";
            ");

            // 3. Detach orders from the legacy slot rows. The old date-bound
            //    rows are about to be deleted; the FK is OnDelete(SetNull) so
            //    this would happen anyway, but doing it explicitly keeps the
            //    intent obvious in the migration script.
            migrationBuilder.Sql(@"UPDATE ""Orders"" SET ""PickupSlotId"" = NULL;");

            migrationBuilder.DropIndex(
                name: "IX_PickupSlots_Date_StartTime_EndTime",
                table: "PickupSlots");

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000005-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000006-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000007-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000008-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000009-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000010-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000011-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000012-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000013-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000014-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000015-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000016-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000017-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000018-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000019-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000020-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000021-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000022-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000023-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000024-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000025-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000026-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000027-0000-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000028-0000-0000-0000-000000000000"));

            migrationBuilder.DropColumn(
                name: "Date",
                table: "PickupSlots");

            migrationBuilder.RenameColumn(
                name: "CurrentOrders",
                table: "PickupSlots",
                newName: "SortOrder");

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000001-0000-0000-0000-000000000000"),
                column: "SortOrder",
                value: 1);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000002-0000-0000-0000-000000000000"),
                column: "SortOrder",
                value: 2);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000003-0000-0000-0000-000000000000"),
                column: "SortOrder",
                value: 3);

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000004-0000-0000-0000-000000000000"),
                column: "SortOrder",
                value: 4);

            migrationBuilder.CreateIndex(
                name: "IX_PickupSlots_StartTime_EndTime",
                table: "PickupSlots",
                columns: new[] { "StartTime", "EndTime" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PickupSlots_StartTime_EndTime",
                table: "PickupSlots");

            migrationBuilder.DropColumn(
                name: "PickupDate",
                table: "Orders");

            migrationBuilder.RenameColumn(
                name: "SortOrder",
                table: "PickupSlots",
                newName: "CurrentOrders");

            migrationBuilder.AddColumn<DateOnly>(
                name: "Date",
                table: "PickupSlots",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1));

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000001-0000-0000-0000-000000000000"),
                columns: new[] { "CurrentOrders", "Date" },
                values: new object[] { 0, new DateOnly(2026, 3, 15) });

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000002-0000-0000-0000-000000000000"),
                columns: new[] { "CurrentOrders", "Date" },
                values: new object[] { 0, new DateOnly(2026, 3, 15) });

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000003-0000-0000-0000-000000000000"),
                columns: new[] { "CurrentOrders", "Date" },
                values: new object[] { 0, new DateOnly(2026, 3, 15) });

            migrationBuilder.UpdateData(
                table: "PickupSlots",
                keyColumn: "Id",
                keyValue: new Guid("d0000004-0000-0000-0000-000000000000"),
                columns: new[] { "CurrentOrders", "Date" },
                values: new object[] { 0, new DateOnly(2026, 3, 15) });

            migrationBuilder.InsertData(
                table: "PickupSlots",
                columns: new[] { "Id", "CreatedAt", "CurrentOrders", "Date", "EndTime", "IsActive", "MaxOrders", "StartTime", "StoreLocationId", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("d0000005-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 16), new TimeOnly(10, 0, 0), true, 10, new TimeOnly(8, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000006-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 16), new TimeOnly(12, 0, 0), true, 10, new TimeOnly(10, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000007-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 16), new TimeOnly(16, 0, 0), true, 10, new TimeOnly(14, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000008-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 16), new TimeOnly(18, 0, 0), true, 10, new TimeOnly(16, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000009-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 17), new TimeOnly(10, 0, 0), true, 10, new TimeOnly(8, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000010-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 17), new TimeOnly(12, 0, 0), true, 10, new TimeOnly(10, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000011-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 17), new TimeOnly(16, 0, 0), true, 10, new TimeOnly(14, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000012-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 17), new TimeOnly(18, 0, 0), true, 10, new TimeOnly(16, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000013-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 18), new TimeOnly(10, 0, 0), true, 10, new TimeOnly(8, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000014-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 18), new TimeOnly(12, 0, 0), true, 10, new TimeOnly(10, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000015-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 18), new TimeOnly(16, 0, 0), true, 10, new TimeOnly(14, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000016-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 18), new TimeOnly(18, 0, 0), true, 10, new TimeOnly(16, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000017-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 19), new TimeOnly(10, 0, 0), true, 10, new TimeOnly(8, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000018-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 19), new TimeOnly(12, 0, 0), true, 10, new TimeOnly(10, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000019-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 19), new TimeOnly(16, 0, 0), true, 10, new TimeOnly(14, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000020-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 19), new TimeOnly(18, 0, 0), true, 10, new TimeOnly(16, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000021-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 20), new TimeOnly(10, 0, 0), true, 10, new TimeOnly(8, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000022-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 20), new TimeOnly(12, 0, 0), true, 10, new TimeOnly(10, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000023-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 20), new TimeOnly(16, 0, 0), true, 10, new TimeOnly(14, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000024-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 20), new TimeOnly(18, 0, 0), true, 10, new TimeOnly(16, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000025-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 21), new TimeOnly(10, 0, 0), true, 10, new TimeOnly(8, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000026-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 21), new TimeOnly(12, 0, 0), true, 10, new TimeOnly(10, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000027-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 21), new TimeOnly(16, 0, 0), true, 10, new TimeOnly(14, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("d0000028-0000-0000-0000-000000000000"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 0, new DateOnly(2026, 3, 21), new TimeOnly(18, 0, 0), true, 10, new TimeOnly(16, 0, 0), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_PickupSlots_Date_StartTime_EndTime",
                table: "PickupSlots",
                columns: new[] { "Date", "StartTime", "EndTime" },
                unique: true);
        }
    }
}
