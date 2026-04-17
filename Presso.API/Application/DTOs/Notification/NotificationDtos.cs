namespace Presso.API.Application.DTOs.Notification;

public record NotificationDto(
    Guid Id, string Title, string Body, string Type,
    bool IsRead, Guid? OrderId, DateTime CreatedAt);
