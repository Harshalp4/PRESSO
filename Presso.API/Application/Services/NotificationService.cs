namespace Presso.API.Application.Services;

using AutoMapper;
using FirebaseAdmin.Messaging;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Notification;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public class NotificationService : INotificationService
{
    private readonly IRepository<Domain.Entities.Notification> _notifRepo;
    private readonly IRepository<User> _userRepo;
    private readonly IMapper _mapper;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        IRepository<Domain.Entities.Notification> notifRepo,
        IRepository<User> userRepo,
        IMapper mapper,
        ILogger<NotificationService> logger)
    {
        _notifRepo = notifRepo;
        _userRepo = userRepo;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<Result<PaginatedResponse<NotificationDto>>> GetNotificationsAsync(Guid userId, int page, int pageSize)
    {
        var query = _notifRepo.Query().Where(n => n.UserId == userId);
        var totalCount = await query.CountAsync();
        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Result<PaginatedResponse<NotificationDto>>.Success(new PaginatedResponse<NotificationDto>
        {
            Items = notifications.Select(n => _mapper.Map<NotificationDto>(n)).ToList(),
            TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    public async Task<Result<bool>> MarkAsReadAsync(Guid userId, Guid notificationId)
    {
        var notif = await _notifRepo.FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);
        if (notif == null) return Result<bool>.NotFound("Notification not found");

        notif.IsRead = true;
        _notifRepo.Update(notif);
        await _notifRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> MarkAllAsReadAsync(Guid userId)
    {
        var unread = await _notifRepo.FindAsync(n => n.UserId == userId && !n.IsRead);
        foreach (var notif in unread)
        {
            notif.IsRead = true;
            _notifRepo.Update(notif);
        }
        await _notifRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task SendNotificationAsync(Guid userId, string title, string body, NotificationType type, Guid? orderId = null)
    {
        try
        {
            // Persist to DB
            await _notifRepo.AddAsync(new Domain.Entities.Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                OrderId = orderId,
                Title = title,
                Body = body,
                Type = type
            });
            await _notifRepo.SaveChangesAsync();

            // Send FCM
            var user = await _userRepo.GetByIdAsync(userId);
            if (user?.FcmToken != null)
            {
                var message = new Message
                {
                    Token = user.FcmToken,
                    Notification = new FirebaseAdmin.Messaging.Notification
                    {
                        Title = title,
                        Body = body
                    },
                    Data = new Dictionary<string, string>
                    {
                        ["type"] = type.ToString(),
                        ["orderId"] = orderId?.ToString() ?? ""
                    }
                };

                await FirebaseMessaging.DefaultInstance.SendAsync(message);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to user {UserId}", userId);
        }
    }
}
