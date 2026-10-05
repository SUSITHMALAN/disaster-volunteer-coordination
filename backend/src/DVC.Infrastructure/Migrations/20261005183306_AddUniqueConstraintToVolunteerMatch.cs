using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DVC.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUniqueConstraintToVolunteerMatch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VolunteerMatches_IncidentId",
                table: "VolunteerMatches");

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerMatches_IncidentId_VolunteerId",
                table: "VolunteerMatches",
                columns: new[] { "IncidentId", "VolunteerId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VolunteerMatches_IncidentId_VolunteerId",
                table: "VolunteerMatches");

            migrationBuilder.CreateIndex(
                name: "IX_VolunteerMatches_IncidentId",
                table: "VolunteerMatches",
                column: "IncidentId");
        }
    }
}
