using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddOfferFlow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_OrderAssignments_RiderId",
                table: "OrderAssignments");

            migrationBuilder.AddColumn<string>(
                name: "FacilityStage",
                table: "Orders",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "OfferExpiresAt",
                table: "OrderAssignments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_OrderAssignments_RiderId_Status",
                table: "OrderAssignments",
                columns: new[] { "RiderId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_OrderAssignments_RiderId_Status",
                table: "OrderAssignments");

            migrationBuilder.DropColumn(
                name: "OfferExpiresAt",
                table: "OrderAssignments");

            migrationBuilder.DropColumn(
                name: "FacilityStage",
                table: "Orders");

            migrationBuilder.CreateIndex(
                name: "IX_OrderAssignments_RiderId",
                table: "OrderAssignments",
                column: "RiderId");
        }
    }
}
