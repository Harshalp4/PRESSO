namespace Presso.API.Domain.Enums;

public enum AssignmentStatus
{
    Assigned = 0,
    Accepted = 1,
    InProgress = 2,
    Completed = 3,
    Cancelled = 4,
    Offered = 5,
    Expired = 6,
    Declined = 7,
    // Rider has confirmed pickup with the customer and is carrying the
    // garments to the facility. The assignment stays on the rider's
    // dashboard under the "To Drop" tab until they reach the facility.
    InTransitToFacility = 8,
    // Facility staff has verified the drop-off OTP. Hand-off complete —
    // order leaves the rider's active list and enters facility intake.
    ReceivedAtFacility = 9
}
