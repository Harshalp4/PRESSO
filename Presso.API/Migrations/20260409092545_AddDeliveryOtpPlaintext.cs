using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddDeliveryOtpPlaintext : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeliveryOtp",
                table: "Orders",
                type: "character varying(8)",
                maxLength: 8,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryOtp",
                table: "Orders");
        }
    }
}
