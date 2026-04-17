namespace Presso.API.Application.Interfaces;

public interface IFirestoreService
{
    Task UpdateOrderStatusAsync(Guid orderId, string status, DateTime updatedAt);
    Task UpdateRiderLocationAsync(Guid riderId, double lat, double lng);
    Task WritePickupPhotosAsync(Guid orderId, List<string> photoUrls);
}
