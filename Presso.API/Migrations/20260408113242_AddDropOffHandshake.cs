using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddDropOffHandshake : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DropOtp",
                table: "OrderAssignments",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DropOtpExpiresAt",
                table: "OrderAssignments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DroppedAtFacilityAt",
                table: "OrderAssignments",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DropOtp",
                table: "OrderAssignments");

            migrationBuilder.DropColumn(
                name: "DropOtpExpiresAt",
                table: "OrderAssignments");

            migrationBuilder.DropColumn(
                name: "DroppedAtFacilityAt",
                table: "OrderAssignments");
        }
    }
}
