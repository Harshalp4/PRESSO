namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Domain.Entities;
using Presso.API.Infrastructure.Data;

public static class ErrorLogEndpoints
{
    public static RouteGroupBuilder MapErrorLogEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/error-logs").WithTags("Error Logs");

        // POST /api/error-logs — mobile app sends errors here
        group.MapPost("/", async (ErrorLogRequest request, HttpContext http, AppDbContext db, ILogger<Program> logger) =>
        {
            // Try to get user from JWT if authenticated
            Guid? userId = null;
            string? phone = null;
            var userIdClaim = http.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (Guid.TryParse(userIdClaim, out var uid))
            {
                userId = uid;
                var user = await db.Users.FindAsync(uid);
                phone = user?.Phone;
            }

            // Use phone from request if not authenticated
            phone ??= request.Phone;

            var errorLog = new AppErrorLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Phone = phone,
                ErrorMessage = request.ErrorMessage,
                StackTrace = request.StackTrace,
                Screen = request.Screen,
                AppVersion = request.AppVersion,
                Platform = request.Platform,
                DeviceInfo = request.DeviceInfo,
                Severity = request.Severity ?? "error"
            };

            db.AppErrorLogs.Add(errorLog);
            await db.SaveChangesAsync();

            logger.LogWarning("App error logged: {ErrorId} | User: {Phone} | Screen: {Screen} | {Message}",
                errorLog.Id, phone ?? "anonymous", request.Screen, request.ErrorMessage);

            return Results.Ok(ApiResponse.Ok("Error logged"));
        });

        return group;
    }

    public static RouteGroupBuilder MapAdminErrorLogEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/admin/error-logs")
            .WithTags("Admin Error Logs")
            .RequireAuthorization("AdminOnly");

        // GET /api/admin/error-logs — view all errors with filters
        group.MapGet("/", async (
            string? phone,
            string? severity,
            string? screen,
            int page,
            int pageSize,
            AppDbContext db) =>
        {
            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 20;

            var query = db.AppErrorLogs
                .Include(e => e.User)
                .AsQueryable();

            if (!string.IsNullOrEmpty(phone))
                query = query.Where(e => e.Phone != null && e.Phone.Contains(phone));

            if (!string.IsNullOrEmpty(severity))
                query = query.Where(e => e.Severity == severity);

            if (!string.IsNullOrEmpty(screen))
                query = query.Where(e => e.Screen != null && e.Screen.Contains(screen));

            var total = await query.CountAsync();

            var logs = await query
                .OrderByDescending(e => e.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(e => new ErrorLogDto(
                    e.Id,
                    e.UserId,
                    e.Phone,
                    e.User != null ? e.User.Name : null,
                    e.ErrorMessage,
                    e.StackTrace,
                    e.Screen,
                    e.AppVersion,
                    e.Platform,
                    e.DeviceInfo,
                    e.Severity,
                    e.CreatedAt))
                .ToListAsync();

            return Results.Ok(ApiResponse<object>.Ok(new { total, page, pageSize, logs }));
        });

        // GET /api/admin/error-logs/stats — error summary
        group.MapGet("/stats", async (AppDbContext db) =>
        {
            var today = DateTime.UtcNow.Date;
            var week = today.AddDays(-7);

            var todayCount = await db.AppErrorLogs.CountAsync(e => e.CreatedAt >= today);
            var weekCount = await db.AppErrorLogs.CountAsync(e => e.CreatedAt >= week);
            var totalCount = await db.AppErrorLogs.CountAsync();

            var topScreens = await db.AppErrorLogs
                .Where(e => e.CreatedAt >= week && e.Screen != null)
                .GroupBy(e => e.Screen)
                .Select(g => new { Screen = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .Take(5)
                .ToListAsync();

            return Results.Ok(ApiResponse<object>.Ok(new
            {
                today = todayCount,
                thisWeek = weekCount,
                total = totalCount,
                topScreens
            }));
        });

        return group;
    }
}

public record ErrorLogRequest(
    string ErrorMessage,
    string? StackTrace,
    string? Screen,
    string? AppVersion,
    string? Platform,
    string? DeviceInfo,
    string? Phone,
    string? Severity);

public record ErrorLogDto(
    Guid Id,
    Guid? UserId,
    string? Phone,
    string? UserName,
    string ErrorMessage,
    string? StackTrace,
    string? Screen,
    string? AppVersion,
    string? Platform,
    string? DeviceInfo,
    string Severity,
    DateTime CreatedAt);
