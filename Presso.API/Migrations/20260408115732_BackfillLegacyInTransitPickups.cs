using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Presso.API.Migrations
{
    /// <inheritdoc />
    public partial class BackfillLegacyInTransitPickups : Migration
    {
        // Before the rider→facility drop-off handshake was introduced, a
        // pickup assignment flipped straight to Completed when the rider
        // confirmed the customer OTP. That left orders stranded on the
        // rider — they had been picked up but never actually delivered to
        // the facility, so they disappeared from the rider's dashboard
        // and landed in History, even though the rider was still carrying
        // the bag.
        //
        // This backfill finds every such legacy row (pickup, Completed,
        // order still at PickedUp) and flips the assignment status to
        // InTransitToFacility so it reappears under the new "To Drop" tab
        // on the rider dashboard.
        //
        // Enum values (keep in sync with Domain/Enums):
        //   AssignmentType.Pickup           = 0
        //   AssignmentStatus.Completed      = 3
        //   AssignmentStatus.InTransitToFacility = 8
        //   OrderStatus.PickedUp            = 4
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                UPDATE ""OrderAssignments"" a
                SET ""Status"" = 8,
                    ""CompletedAt"" = NULL,
                    ""UpdatedAt"" = NOW()
                FROM ""Orders"" o
                WHERE a.""OrderId"" = o.""Id""
                  AND a.""Type"" = 0
                  AND a.""Status"" = 3
                  AND o.""Status"" = 4;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Best-effort revert — we can't recover the original CompletedAt
            // timestamp, so we just flip the status back.
            migrationBuilder.Sql(@"
                UPDATE ""OrderAssignments"" a
                SET ""Status"" = 3,
                    ""CompletedAt"" = COALESCE(""CompletedAt"", ""UpdatedAt""),
                    ""UpdatedAt"" = NOW()
                FROM ""Orders"" o
                WHERE a.""OrderId"" = o.""Id""
                  AND a.""Type"" = 0
                  AND a.""Status"" = 8
                  AND o.""Status"" = 4;
            ");
        }
    }
}
