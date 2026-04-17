namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Notification;
using Presso.API.Domain.Enums;

public interface INotificationService
{
    Task<Result<PaginatedResponse<NotificationDto>>> GetNotificationsAsync(Guid userId, int page, int pageSize);
    Task<Result<bool>> MarkAsReadAsync(Guid userId, Guid notificationId);
    Task<Result<bool>> MarkAllAsReadAsync(Guid userId);
    Task SendNotificationAsync(Guid userId, string title, string body, NotificationType type, Guid? orderId = null);
}
