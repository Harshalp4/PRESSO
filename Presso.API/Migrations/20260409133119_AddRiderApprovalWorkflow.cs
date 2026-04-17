using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddRiderApprovalWorkflow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AdminNotes",
                table: "Riders",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ApprovedAt",
                table: "Riders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RejectionReason",
                table: "Riders",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Riders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "SuspendedAt",
                table: "Riders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Riders_Status",
                table: "Riders",
                column: "Status");

            // Backfill existing riders as Approved. They're already in the
            // system and taking jobs — flipping them to the default Pending
            // would lock them out mid-flight. ApprovedAt is stamped with
            // their row-creation time so audit trails stay coherent.
            migrationBuilder.Sql(@"
                UPDATE ""Riders""
                SET ""Status"" = 1,
                    ""ApprovedAt"" = ""CreatedAt""
                WHERE ""Status"" = 0;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Riders_Status",
                table: "Riders");

            migrationBuilder.DropColumn(
                name: "AdminNotes",
                table: "Riders");

            migrationBuilder.DropColumn(
                name: "ApprovedAt",
                table: "Riders");

            migrationBuilder.DropColumn(
                name: "RejectionReason",
                table: "Riders");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Riders");

            migrationBuilder.DropColumn(
                name: "SuspendedAt",
                table: "Riders");
        }
    }
}
