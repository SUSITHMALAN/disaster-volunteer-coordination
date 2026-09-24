using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DVC.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIncidentResources : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "IncidentResources",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    IncidentId = table.Column<Guid>(type: "uuid", nullable: false),
                    ResourceName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Unit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    AvailableQuantity = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    NeededQuantity = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    UsedQuantity = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IncidentResources", x => x.Id);
                    table.CheckConstraint("CK_IncidentResources_AvailableQuantity_NonNegative", "\"AvailableQuantity\" >= 0");
                    table.CheckConstraint("CK_IncidentResources_NeededQuantity_NonNegative", "\"NeededQuantity\" >= 0");
                    table.CheckConstraint("CK_IncidentResources_UsedQuantity_NonNegative", "\"UsedQuantity\" >= 0");
                    table.CheckConstraint("CK_IncidentResources_UsedQuantity_WithinAllocation", "\"UsedQuantity\" <= \"AvailableQuantity\"");
                    table.ForeignKey(
                        name: "FK_IncidentResources_Incidents_IncidentId",
                        column: x => x.IncidentId,
                        principalTable: "Incidents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_IncidentResources_IncidentId",
                table: "IncidentResources",
                column: "IncidentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "IncidentResources");
        }
    }
}
