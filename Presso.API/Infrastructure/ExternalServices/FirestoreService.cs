namespace Presso.API.Infrastructure.ExternalServices;

using Google.Cloud.Firestore;
using Presso.API.Application.Interfaces;

public class FirestoreService : IFirestoreService
{
    private readonly FirestoreDb? _db;
    private readonly ILogger<FirestoreService> _logger;

    public FirestoreService(IConfiguration config, ILogger<FirestoreService> logger)
    {
        _logger = logger;
        try
        {
            var projectId = config["Firebase:ProjectId"];
            if (!string.IsNullOrEmpty(projectId))
                _db = FirestoreDb.Create(projectId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Firestore initialization failed - real-time features disabled");
        }
    }

    public async Task UpdateOrderStatusAsync(Guid orderId, string status, DateTime updatedAt)
    {
        if (_db == null) return;
        try
        {
            var docRef = _db.Collection("orders").Document(orderId.ToString());
            await docRef.SetAsync(new Dictionary<string, object>
            {
                ["status"] = status,
                ["updatedAt"] = updatedAt.ToString("o")
            }, SetOptions.MergeAll);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update order {OrderId} in Firestore", orderId);
        }
    }

    public async Task WritePickupPhotosAsync(Guid orderId, List<string> photoUrls)
    {
        if (_db == null) return;
        try
        {
            var docRef = _db.Collection("orders").Document(orderId.ToString());
            await docRef.SetAsync(new Dictionary<string, object>
            {
                ["pickupPhotos"] = photoUrls,
                ["photoCount"] = photoUrls.Count,
                ["photosUpdatedAt"] = DateTime.UtcNow.ToString("o")
            }, SetOptions.MergeAll);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to write pickup photos for order {OrderId} to Firestore", orderId);
        }
    }

    public async Task UpdateRiderLocationAsync(Guid riderId, double lat, double lng)
    {
        if (_db == null) return;
        try
        {
            var docRef = _db.Collection("riders").Document(riderId.ToString());
            await docRef.SetAsync(new Dictionary<string, object>
            {
                ["lat"] = lat,
                ["lng"] = lng,
                ["updatedAt"] = DateTime.UtcNow.ToString("o")
            }, SetOptions.MergeAll);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update rider {RiderId} location in Firestore", riderId);
        }
    }
}
