namespace Presso.API.Application.DTOs.Admin;

public record CreateUserDiscountRequest(
    string Type,
    decimal Value,
    string Reason,
    DateTime? ExpiresAt,
    int? UsageLimit);

public record UserDiscountDto(
    Guid Id,
    Guid UserId,
    string? UserName,
    string? UserPhone,
    string Type,
    decimal Value,
    string Reason,
    bool IsActive,
    DateTime? ExpiresAt,
    int? UsageLimit,
    int UsageCount,
    Guid CreatedByAdminId,
    DateTime CreatedAt);
