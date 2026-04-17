using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class AddEmojiToServicesAndGarments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Emoji",
                table: "Services",
                type: "character varying(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Emoji",
                table: "GarmentTypes",
                type: "character varying(10)",
                maxLength: 10,
                nullable: true);

            // Seed emoji values for services
            migrationBuilder.Sql(@"
                UPDATE ""Services"" SET ""Emoji"" = '👕' WHERE ""Id"" = '10000000-0000-0000-0000-000000000001';
                UPDATE ""Services"" SET ""Emoji"" = '👔' WHERE ""Id"" = '10000000-0000-0000-0000-000000000002';
                UPDATE ""Services"" SET ""Emoji"" = '✨' WHERE ""Id"" = '10000000-0000-0000-0000-000000000003';
                UPDATE ""Services"" SET ""Emoji"" = '♨️' WHERE ""Id"" = '10000000-0000-0000-0000-000000000004';
                UPDATE ""Services"" SET ""Emoji"" = '🧶' WHERE ""Id"" = '10000000-0000-0000-0000-000000000005';
                UPDATE ""Services"" SET ""Emoji"" = '🛌' WHERE ""Id"" = '10000000-0000-0000-0000-000000000006';
                UPDATE ""Services"" SET ""Emoji"" = '🪟' WHERE ""Id"" = '10000000-0000-0000-0000-000000000007';
                UPDATE ""Services"" SET ""Emoji"" = '🥻' WHERE ""Id"" = '10000000-0000-0000-0000-000000000008';
                UPDATE ""Services"" SET ""Emoji"" = '🧣' WHERE ""Id"" = '10000000-0000-0000-0000-000000000009';
                UPDATE ""Services"" SET ""Emoji"" = '👜' WHERE ""Id"" = '10000000-0000-0000-0000-00000000000a';
                UPDATE ""Services"" SET ""Emoji"" = '👟' WHERE ""Id"" = '10000000-0000-0000-0000-00000000000b';
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Emoji",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "Emoji",
                table: "GarmentTypes");
        }
    }
}
