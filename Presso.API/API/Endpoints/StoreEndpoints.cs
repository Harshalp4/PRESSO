namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Store;
using Presso.API.Domain.Entities;
using Presso.API.Infrastructure.Data;

public static class StoreEndpoints
{
    public static RouteGroupBuilder MapStoreEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/stores").WithTags("Stores");

        group.MapGet("/", async (AppDbContext db, IMemoryCache cache) =>
        {
            const string cacheKey = "stores_active";
            if (cache.TryGetValue(cacheKey, out List<StoreLocationDto>? cached) && cached != null)
                return Results.Ok(ApiResponse<List<StoreLocationDto>>.Ok(cached));

            var stores = await db.Set<StoreLocation>()
                .Where(s => s.IsActive)
                .OrderBy(s => s.Name)
                .ToListAsync();

            var dtos = stores.Select(MapToDto).ToList();
            cache.Set(cacheKey, dtos, TimeSpan.FromHours(6));
            return Results.Ok(ApiResponse<List<StoreLocationDto>>.Ok(dtos));
        });

        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var store = await db.Set<StoreLocation>().FindAsync(id);
            if (store == null) return Results.NotFound(ApiResponse.Fail("Store not found"));
            return Results.Ok(ApiResponse<StoreLocationDto>.Ok(MapToDto(store)));
        });

        group.MapGet("/nearest", async (double lat, double lng, AppDbContext db) =>
        {
            var stores = await db.Set<StoreLocation>()
                .Where(s => s.IsActive)
                .ToListAsync();

            if (stores.Count == 0)
                return Results.NotFound(ApiResponse.Fail("No stores available"));

            var nearest = stores
                .Select(s => new { Store = s, Distance = HaversineKm(lat, lng, s.Latitude, s.Longitude) })
                .OrderBy(x => x.Distance)
                .First();

            return Results.Ok(ApiResponse<NearestStoreResponse>.Ok(
                new NearestStoreResponse(
                    MapToDto(nearest.Store),
                    Math.Round(nearest.Distance, 2),
                    nearest.Distance > nearest.Store.ServiceRadiusKm)));
        });

        return group;
    }

    public static RouteGroupBuilder MapAdminStoreEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/admin/stores").WithTags("Stores").RequireAuthorization("AdminOnly");

        group.MapPost("/", async (CreateStoreRequest request, AppDbContext db, IMemoryCache cache) =>
        {
            var store = new StoreLocation
            {
                Id = Guid.NewGuid(),
                Name = request.Name,
                AddressLine1 = request.AddressLine1,
                AddressLine2 = request.AddressLine2,
                City = request.City,
                State = request.State,
                Pincode = request.Pincode,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Phone = request.Phone,
                Email = request.Email,
                GoogleMapsUrl = request.GoogleMapsUrl,
                OpenTime = request.OpenTime,
                CloseTime = request.CloseTime,
                IsOpenSunday = request.IsOpenSunday,
                ServiceRadiusKm = request.ServiceRadiusKm,
                IsHeadquarters = request.IsHeadquarters
            };

            db.Set<StoreLocation>().Add(store);
            await db.SaveChangesAsync();
            cache.Remove("stores_active");

            return Results.Ok(ApiResponse<StoreLocationDto>.Ok(MapToDto(store)));
        });

        group.MapPut("/{id:guid}", async (Guid id, CreateStoreRequest request, AppDbContext db, IMemoryCache cache) =>
        {
            var store = await db.Set<StoreLocation>().FindAsync(id);
            if (store == null) return Results.NotFound(ApiResponse.Fail("Store not found"));

            store.Name = request.Name;
            store.AddressLine1 = request.AddressLine1;
            store.AddressLine2 = request.AddressLine2;
            store.City = request.City;
            store.State = request.State;
            store.Pincode = request.Pincode;
            store.Latitude = request.Latitude;
            store.Longitude = request.Longitude;
            store.Phone = request.Phone;
            store.Email = request.Email;
            store.GoogleMapsUrl = request.GoogleMapsUrl;
            store.OpenTime = request.OpenTime;
            store.CloseTime = request.CloseTime;
            store.IsOpenSunday = request.IsOpenSunday;
            store.ServiceRadiusKm = request.ServiceRadiusKm;
            store.IsHeadquarters = request.IsHeadquarters;

            await db.SaveChangesAsync();
            cache.Remove("stores_active");

            return Results.Ok(ApiResponse<StoreLocationDto>.Ok(MapToDto(store)));
        });

        group.MapPatch("/{id:guid}/toggle-active", async (Guid id, AppDbContext db, IMemoryCache cache) =>
        {
            var store = await db.Set<StoreLocation>().FindAsync(id);
            if (store == null) return Results.NotFound(ApiResponse.Fail("Store not found"));

            store.IsActive = !store.IsActive;
            await db.SaveChangesAsync();
            cache.Remove("stores_active");

            return Results.Ok(ApiResponse<StoreLocationDto>.Ok(MapToDto(store)));
        });

        return group;
    }

    private static StoreLocationDto MapToDto(StoreLocation s) =>
        new(s.Id, s.Name, s.AddressLine1, s.AddressLine2, s.City, s.State,
            s.Pincode, s.Latitude, s.Longitude, s.Phone, s.Email, s.GoogleMapsUrl,
            s.OpenTime, s.CloseTime, s.IsOpenSunday, s.ServiceRadiusKm, s.IsActive, s.IsHeadquarters);

    private static double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371;
        var dLat = DegreesToRadians(lat2 - lat1);
        var dLon = DegreesToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private static double DegreesToRadians(double degrees) => degrees * Math.PI / 180;
}
