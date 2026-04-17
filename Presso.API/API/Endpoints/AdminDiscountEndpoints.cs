namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Admin;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;
using Presso.API.Infrastructure.Data;

public static class AdminDiscountEndpoints
{
    public static RouteGroupBuilder MapAdminDiscountEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/admin/users").WithTags("Admin Discounts").RequireAuthorization("AdminOnly");

        group.MapPost("/{userId:guid}/discounts", async (
            Guid userId,
            CreateUserDiscountRequest request,
            ClaimsPrincipal adminUser,
            AppDbContext db,
            INotificationService notificationService,
            ILogger<Program> logger) =>
        {
            var adminId = adminUser.GetUserId();
            var user = await db.Users.FindAsync(userId);
            if (user == null)
                return Results.NotFound(ApiResponse.Fail("User not found"));

            if (!Enum.TryParse<DiscountType>(request.Type, true, out var discountType))
                return Results.BadRequest(ApiResponse.Fail("Type must be 'Percentage' or 'FlatAmount'"));

            if (discountType == DiscountType.Percentage && (request.Value < 1 || request.Value > 50))
                return Results.BadRequest(ApiResponse.Fail("Percentage discount must be between 1 and 50"));

            if (discountType == DiscountType.FlatAmount && (request.Value < 1 || request.Value > 500))
                return Results.BadRequest(ApiResponse.Fail("Flat discount must be between ₹1 and ₹500"));

            if (string.IsNullOrWhiteSpace(request.Reason) || request.Reason.Length < 5)
                return Results.BadRequest(ApiResponse.Fail("Reason is required (min 5 characters)"));

            // Deactivate existing active discounts
            var existing = await db.Set<UserDiscount>()
                .Where(d => d.UserId == userId && d.IsActive)
                .ToListAsync();
            foreach (var d in existing)
            {
                d.IsActive = false;
                d.UpdatedAt = DateTime.UtcNow;
            }

            var discount = new UserDiscount
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = discountType,
                Value = request.Value,
                Reason = request.Reason,
                ExpiresAt = request.ExpiresAt,
                UsageLimit = request.UsageLimit,
                CreatedByAdminId = adminId
            };

            db.Set<UserDiscount>().Add(discount);
            await db.SaveChangesAsync();

            logger.LogInformation("Admin {AdminId} set {Type} discount of {Value} for user {UserId}",
                adminId, discountType, request.Value, userId);

            _ = notificationService.SendNotificationAsync(userId,
                "Special Discount", "A special discount has been applied to your account!",
                NotificationType.Promotion);

            return Results.Ok(ApiResponse<UserDiscountDto>.Ok(MapToDto(discount, user)));
        });

        group.MapGet("/{userId:guid}/discounts", async (Guid userId, AppDbContext db) =>
        {
            var user = await db.Users.FindAsync(userId);
            if (user == null)
                return Results.NotFound(ApiResponse.Fail("User not found"));

            var discounts = await db.Set<UserDiscount>()
                .Where(d => d.UserId == userId)
                .OrderByDescending(d => d.CreatedAt)
                .ToListAsync();

            return Results.Ok(ApiResponse<List<UserDiscountDto>>.Ok(
                discounts.Select(d => MapToDto(d, user)).ToList()));
        });

        group.MapDelete("/{userId:guid}/discounts/{discountId:guid}", async (
            Guid userId, Guid discountId, AppDbContext db) =>
        {
            var discount = await db.Set<UserDiscount>()
                .FirstOrDefaultAsync(d => d.Id == discountId && d.UserId == userId);
            if (discount == null)
                return Results.NotFound(ApiResponse.Fail("Discount not found"));

            discount.IsActive = false;
            discount.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
            return Results.NoContent();
        });

        // List all active discounts across all users
        var adminGroup = routes.MapGroup("/api/admin/discounts").WithTags("Admin Discounts").RequireAuthorization("AdminOnly");

        adminGroup.MapGet("/", async (bool? isActive, int page, int pageSize, AppDbContext db) =>
        {
            var query = db.Set<UserDiscount>().Include(d => d.User).AsQueryable();

            if (isActive.HasValue)
                query = query.Where(d => d.IsActive == isActive.Value);

            var totalCount = await query.CountAsync();
            var p = page > 0 ? page : 1;
            var ps = pageSize > 0 ? Math.Min(pageSize, 50) : 10;

            var discounts = await query
                .OrderByDescending(d => d.CreatedAt)
                .Skip((p - 1) * ps)
                .Take(ps)
                .ToListAsync();

            return Results.Ok(ApiResponse<PaginatedResponse<UserDiscountDto>>.Ok(
                new PaginatedResponse<UserDiscountDto>
                {
                    Items = discounts.Select(d => MapToDto(d, d.User)).ToList(),
                    TotalCount = totalCount,
                    Page = p,
                    PageSize = ps
                }));
        });

        return group;
    }

    private static UserDiscountDto MapToDto(UserDiscount d, User user) =>
        new(d.Id, d.UserId, user.Name, user.Phone, d.Type.ToString(), d.Value,
            d.Reason, d.IsActive, d.ExpiresAt, d.UsageLimit, d.UsageCount,
            d.CreatedByAdminId, d.CreatedAt);
}
