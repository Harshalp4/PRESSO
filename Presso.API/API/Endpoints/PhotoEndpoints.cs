namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Photo;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Enums;
using Presso.API.Infrastructure.Data;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

public static class PhotoEndpoints
{
    public static RouteGroupBuilder MapPhotoEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/orders").WithTags("Photos").RequireAuthorization();

        group.MapPost("/{orderId:guid}/pickup-photos", async (
            Guid orderId,
            HttpRequest request,
            ClaimsPrincipal user,
            AppDbContext db,
            IAzureBlobService blobService,
            IFirestoreService firestoreService) =>
        {
            var userId = user.GetUserId();
            var role = user.FindFirst(ClaimTypes.Role)?.Value;

            var order = await db.Orders
                .Include(o => o.Assignments)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null)
                return Results.NotFound(ApiResponse.Fail("Order not found"));

            // Riders can only upload for their assigned orders
            if (role == "Rider")
            {
                var rider = await db.Riders.FirstOrDefaultAsync(r => r.UserId == userId);
                if (rider == null || !order.Assignments.Any(a => a.RiderId == rider.Id))
                    return Results.Json(ApiResponse.Fail("Not assigned to this order"), statusCode: 403);
            }
            else if (role != "Admin")
            {
                return Results.Json(ApiResponse.Fail("Only riders and admins can upload photos"), statusCode: 403);
            }

            if (order.Status != OrderStatus.RiderAssigned && order.Status != OrderStatus.PickupInProgress)
                return Results.BadRequest(ApiResponse.Fail("Photos can only be uploaded during pickup"));

            if (!request.HasFormContentType)
                return Results.BadRequest(ApiResponse.Fail("Content-Type must be multipart/form-data"));

            var form = await request.ReadFormAsync();
            var files = form.Files.GetFiles("photos");

            if (files.Count == 0)
                return Results.BadRequest(ApiResponse.Fail("No photos provided"));

            if (files.Count > 10)
                return Results.BadRequest(ApiResponse.Fail("Maximum 10 photos per upload"));

            if (order.PickupPhotoUrls.Count + files.Count > 30)
                return Results.BadRequest(ApiResponse.Fail("Maximum 30 photos per order"));

            var folder = $"pickup-photos/{orderId}/";
            var newUrls = new List<string>();

            foreach (var file in files)
            {
                if (file.Length > 5 * 1024 * 1024)
                    return Results.BadRequest(ApiResponse.Fail($"File '{file.FileName}' exceeds 5MB limit"));

                var contentType = file.ContentType?.ToLowerInvariant();
                if (contentType is not ("image/jpeg" or "image/png" or "image/webp"))
                    return Results.BadRequest(ApiResponse.Fail($"File '{file.FileName}' has invalid type. Allowed: jpeg, png, webp"));

                using var inputStream = file.OpenReadStream();
                using var image = await Image.LoadAsync(inputStream);

                // Resize if width > 1200px
                if (image.Width > 1200)
                {
                    var ratio = 1200.0 / image.Width;
                    var newHeight = (int)(image.Height * ratio);
                    image.Mutate(x => x.Resize(1200, newHeight));
                }

                using var outputStream = new MemoryStream();
                await image.SaveAsJpegAsync(outputStream);
                outputStream.Position = 0;

                var url = await blobService.UploadPhotoAsync(outputStream, file.FileName, "image/jpeg", folder);
                newUrls.Add(url);
            }

            order.PickupPhotoUrls.AddRange(newUrls);
            order.PickupPhotoCount = order.PickupPhotoUrls.Count;
            order.PhotosUploadedAt = DateTime.UtcNow;
            order.PickupPhotosBlobFolder = folder;
            await db.SaveChangesAsync();

            _ = firestoreService.WritePickupPhotosAsync(orderId, order.PickupPhotoUrls);

            return Results.Ok(ApiResponse<PhotoUploadResponse>.Ok(
                new PhotoUploadResponse(newUrls.Count, newUrls, "Photos uploaded successfully")));
        }).DisableAntiforgery();

        group.MapGet("/{orderId:guid}/pickup-photos", async (
            Guid orderId,
            ClaimsPrincipal user,
            AppDbContext db,
            IAzureBlobService blobService) =>
        {
            var userId = user.GetUserId();
            var role = user.FindFirst(ClaimTypes.Role)?.Value;

            var order = await db.Orders
                .Include(o => o.Assignments)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null)
                return Results.NotFound(ApiResponse.Fail("Order not found"));

            // Access control
            if (role == "Customer" && order.UserId != userId)
                return Results.Json(ApiResponse.Fail("Access denied"), statusCode: 403);

            if (role == "Rider")
            {
                var rider = await db.Riders.FirstOrDefaultAsync(r => r.UserId == userId);
                if (rider == null || !order.Assignments.Any(a => a.RiderId == rider.Id))
                    return Results.Json(ApiResponse.Fail("Not assigned to this order"), statusCode: 403);
            }

            // Generate SAS URLs
            var sasUrls = order.PickupPhotoUrls.Select(u => blobService.GenerateSasUrl(u, 60)).ToList();

            return Results.Ok(ApiResponse<PhotoListResponse>.Ok(
                new PhotoListResponse(sasUrls, order.PhotosUploadedAt, order.PickupPhotoCount)));
        });

        group.MapDelete("/{orderId:guid}/pickup-photos/{photoIndex:int}", async (
            Guid orderId,
            int photoIndex,
            ClaimsPrincipal user,
            AppDbContext db,
            IAzureBlobService blobService,
            IFirestoreService firestoreService) =>
        {
            var userId = user.GetUserId();
            var role = user.FindFirst(ClaimTypes.Role)?.Value;

            var order = await db.Orders
                .Include(o => o.Assignments)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null)
                return Results.NotFound(ApiResponse.Fail("Order not found"));

            if (role == "Rider")
            {
                var rider = await db.Riders.FirstOrDefaultAsync(r => r.UserId == userId);
                if (rider == null || !order.Assignments.Any(a => a.RiderId == rider.Id))
                    return Results.Json(ApiResponse.Fail("Not assigned to this order"), statusCode: 403);
            }
            else if (role != "Admin")
            {
                return Results.Json(ApiResponse.Fail("Only riders and admins can delete photos"), statusCode: 403);
            }

            if (order.Status != OrderStatus.RiderAssigned)
                return Results.BadRequest(ApiResponse.Fail("Photos can only be deleted before pickup is confirmed"));

            if (photoIndex < 0 || photoIndex >= order.PickupPhotoUrls.Count)
                return Results.BadRequest(ApiResponse.Fail("Invalid photo index"));

            var urlToDelete = order.PickupPhotoUrls[photoIndex];
            await blobService.DeletePhotoAsync(urlToDelete);

            order.PickupPhotoUrls.RemoveAt(photoIndex);
            order.PickupPhotoCount = order.PickupPhotoUrls.Count;
            await db.SaveChangesAsync();

            _ = firestoreService.WritePickupPhotosAsync(orderId, order.PickupPhotoUrls);

            var sasUrls = order.PickupPhotoUrls.Select(u => blobService.GenerateSasUrl(u, 60)).ToList();
            return Results.Ok(ApiResponse<PhotoDeleteResponse>.Ok(
                new PhotoDeleteResponse(order.PickupPhotoCount, sasUrls)));
        });

        return group;
    }
}
