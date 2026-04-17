namespace Presso.API.Domain.Enums;

public enum OrderStatus
{
    Pending = 0,
    Confirmed = 1,
    RiderAssigned = 2,
    PickupInProgress = 3,
    PickedUp = 4,
    InProcess = 5,
    ReadyForDelivery = 6,
    OutForDelivery = 7,
    Delivered = 8,
    Cancelled = 9
}
