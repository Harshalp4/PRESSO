namespace Presso.API.API.Endpoints;

using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;
using Presso.API.Domain.Entities;
using Presso.API.Infrastructure.Data;

public static class ServiceZoneEndpoints
{
    public static RouteGroupBuilder MapServiceZoneEndpoints(this IEndpointRouteBuilder routes)
    {
        // Public endpoint: check if a pincode is serviceable
        var publicGroup = routes.MapGroup("/api/service-zones").WithTags("Service Zones");

        publicGroup.MapGet("/check/{pincode}", async (string pincode, AppDbContext db) =>
        {
            var trimmed = pincode?.Trim() ?? "";
            if (trimmed.Length != 6 || !trimmed.All(char.IsDigit))
            {
                return Results.BadRequest(ApiResponse<ServiceZoneCheckResponse>.Ok(
                    new ServiceZoneCheckResponse(false, null, "Invalid pincode format. Must be 6 digits.")));
            }

            var zone = await db.Set<ServiceZone>()
                .FirstOrDefaultAsync(z => z.Pincode == trimmed && z.IsActive);

            if (zone == null)
            {
                return Results.Ok(ApiResponse<ServiceZoneCheckResponse>.Ok(
                    new ServiceZoneCheckResponse(false, null,
                        $"Sorry, we don't serve pincode {trimmed} yet. We're expanding soon!")));
            }

            return Results.Ok(ApiResponse<ServiceZoneCheckResponse>.Ok(
                new ServiceZoneCheckResponse(true, zone.Name,
                    $"Great news! We serve {zone.Name}.")));
        });

        publicGroup.MapGet("/active", async (AppDbContext db) =>
        {
            var zones = await db.Set<ServiceZone>()
                .Where(z => z.IsActive)
                .OrderBy(z => z.SortOrder)
                .ThenBy(z => z.Name)
                .Select(z => new ServiceZoneDto(
                    z.Id, z.Name, z.Pincode, z.City, z.Area, z.Description,
                    z.IsActive, z.SortOrder, z.AssignedStoreId,
                    z.AssignedStore != null ? z.AssignedStore.Name : null,
                    z.CreatedAt, z.UpdatedAt))
                .ToListAsync();

            return Results.Ok(ApiResponse<List<ServiceZoneDto>>.Ok(zones));
        });

        return publicGroup;
    }

    public static RouteGroupBuilder MapAdminServiceZoneEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/admin/service-zones")
            .WithTags("Admin Service Zones")
            .RequireAuthorization("AdminOnly");

        // List all zones (including inactive)
        group.MapGet("/", async (bool? isActive, AppDbContext db) =>
        {
            var query = db.Set<ServiceZone>()
                .Include(z => z.AssignedStore)
                .AsQueryable();

            if (isActive.HasValue)
                query = query.Where(z => z.IsActive == isActive.Value);

            var zones = await query
                .OrderBy(z => z.SortOrder)
                .ThenBy(z => z.Name)
                .Select(z => new ServiceZoneDto(
                    z.Id, z.Name, z.Pincode, z.City, z.Area, z.Description,
                    z.IsActive, z.SortOrder, z.AssignedStoreId,
                    z.AssignedStore != null ? z.AssignedStore.Name : null,
                    z.CreatedAt, z.UpdatedAt))
                .ToListAsync();

            return Results.Ok(ApiResponse<List<ServiceZoneDto>>.Ok(zones));
        });

        // Get single zone
        group.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var zone = await db.Set<ServiceZone>()
                .Include(z => z.AssignedStore)
                .FirstOrDefaultAsync(z => z.Id == id);

            if (zone == null)
                return Results.NotFound(ApiResponse.Fail("Service zone not found"));

            return Results.Ok(ApiResponse<ServiceZoneDto>.Ok(
                new ServiceZoneDto(zone.Id, zone.Name, zone.Pincode, zone.City,
                    zone.Area, zone.Description, zone.IsActive, zone.SortOrder,
                    zone.AssignedStoreId,
                    zone.AssignedStore?.Name,
                    zone.CreatedAt, zone.UpdatedAt)));
        });

        // Create zone
        group.MapPost("/", async (CreateServiceZoneRequest request, AppDbContext db, ILogger<Program> logger) =>
        {
            if (string.IsNullOrWhiteSpace(request.Pincode) || request.Pincode.Trim().Length != 6)
                return Results.BadRequest(ApiResponse.Fail("Pincode must be exactly 6 digits"));

            if (string.IsNullOrWhiteSpace(request.Name))
                return Results.BadRequest(ApiResponse.Fail("Zone name is required"));

            if (string.IsNullOrWhiteSpace(request.City))
                return Results.BadRequest(ApiResponse.Fail("City is required"));

            // Check for duplicate pincode
            var exists = await db.Set<ServiceZone>()
                .AnyAsync(z => z.Pincode == request.Pincode.Trim());
            if (exists)
                return Results.BadRequest(ApiResponse.Fail($"A zone with pincode {request.Pincode} already exists"));

            // Validate store if provided
            if (request.AssignedStoreId.HasValue)
            {
                var store = await db.StoreLocations.FindAsync(request.AssignedStoreId.Value);
                if (store == null)
                    return Results.BadRequest(ApiResponse.Fail("Assigned store not found"));
            }

            var zone = new ServiceZone
            {
                Id = Guid.NewGuid(),
                Name = request.Name.Trim(),
                Pincode = request.Pincode.Trim(),
                City = request.City.Trim(),
                Area = request.Area?.Trim(),
                Description = request.Description?.Trim(),
                AssignedStoreId = request.AssignedStoreId
            };

            db.Set<ServiceZone>().Add(zone);
            await db.SaveChangesAsync();

            logger.LogInformation("Service zone created: {Name} ({Pincode})", zone.Name, zone.Pincode);

            return Results.Created($"/api/admin/service-zones/{zone.Id}",
                ApiResponse<ServiceZoneDto>.Ok(
                    new ServiceZoneDto(zone.Id, zone.Name, zone.Pincode, zone.City,
                        zone.Area, zone.Description, zone.IsActive, zone.SortOrder,
                        zone.AssignedStoreId, null, zone.CreatedAt, zone.UpdatedAt)));
        });

        // Update zone
        group.MapPatch("/{id:guid}", async (Guid id, UpdateServiceZoneRequest request, AppDbContext db, ILogger<Program> logger) =>
        {
            var zone = await db.Set<ServiceZone>().FindAsync(id);
            if (zone == null)
                return Results.NotFound(ApiResponse.Fail("Service zone not found"));

            if (request.Name != null) zone.Name = request.Name.Trim();
            if (request.Pincode != null)
            {
                if (request.Pincode.Trim().Length != 6)
                    return Results.BadRequest(ApiResponse.Fail("Pincode must be exactly 6 digits"));

                var duplicate = await db.Set<ServiceZone>()
                    .AnyAsync(z => z.Pincode == request.Pincode.Trim() && z.Id != id);
                if (duplicate)
                    return Results.BadRequest(ApiResponse.Fail($"A zone with pincode {request.Pincode} already exists"));

                zone.Pincode = request.Pincode.Trim();
            }
            if (request.City != null) zone.City = request.City.Trim();
            if (request.Area != null) zone.Area = request.Area.Trim();
            if (request.Description != null) zone.Description = request.Description.Trim();
            if (request.IsActive.HasValue) zone.IsActive = request.IsActive.Value;
            if (request.SortOrder.HasValue) zone.SortOrder = request.SortOrder.Value;
            if (request.AssignedStoreId.HasValue)
            {
                var store = await db.StoreLocations.FindAsync(request.AssignedStoreId.Value);
                if (store == null)
                    return Results.BadRequest(ApiResponse.Fail("Assigned store not found"));
                zone.AssignedStoreId = request.AssignedStoreId.Value;
            }

            zone.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();

            logger.LogInformation("Service zone updated: {Id} ({Name})", zone.Id, zone.Name);

            return Results.Ok(ApiResponse<ServiceZoneDto>.Ok(
                new ServiceZoneDto(zone.Id, zone.Name, zone.Pincode, zone.City,
                    zone.Area, zone.Description, zone.IsActive, zone.SortOrder,
                    zone.AssignedStoreId, null, zone.CreatedAt, zone.UpdatedAt)));
        });

        // Delete zone (soft delete - set inactive)
        group.MapDelete("/{id:guid}", async (Guid id, AppDbContext db, ILogger<Program> logger) =>
        {
            var zone = await db.Set<ServiceZone>().FindAsync(id);
            if (zone == null)
                return Results.NotFound(ApiResponse.Fail("Service zone not found"));

            zone.IsActive = false;
            zone.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();

            logger.LogInformation("Service zone deactivated: {Id} ({Name})", zone.Id, zone.Name);

            return Results.NoContent();
        });

        // Bulk toggle: activate/deactivate multiple zones
        group.MapPost("/bulk-toggle", async (BulkToggleRequest request, AppDbContext db, ILogger<Program> logger) =>
        {
            var zones = await db.Set<ServiceZone>()
                .Where(z => request.ZoneIds.Contains(z.Id))
                .ToListAsync();

            foreach (var zone in zones)
            {
                zone.IsActive = request.IsActive;
                zone.UpdatedAt = DateTime.UtcNow;
            }

            await db.SaveChangesAsync();

            logger.LogInformation("Bulk toggled {Count} zones to IsActive={IsActive}", zones.Count, request.IsActive);

            return Results.Ok(ApiResponse<int>.Ok(zones.Count));
        });

        return group;
    }
}

public record BulkToggleRequest(List<Guid> ZoneIds, bool IsActive);
