namespace Presso.API.Application.DTOs.Admin;

// ===========================================================
// Admin catalog DTOs — richer than the public /api/services
// DTOs because admins need to see inactive items and counts.
// ===========================================================

public record AdminServiceDto(
    Guid Id,
    string Name,
    string? Description,
    string Category,
    decimal PricePerPiece,
    string? Emoji,
    string? IconUrl,
    bool IsActive,
    int SortOrder,
    int GarmentCount,
    int TreatmentCount);

public record CreateServiceRequest(
    string Name,
    string? Description,
    string? Category,
    decimal PricePerPiece,
    string? Emoji,
    int? SortOrder);

public record UpdateServiceRequest(
    string? Name,
    string? Description,
    string? Category,
    decimal? PricePerPiece,
    string? Emoji,
    bool? IsActive,
    int? SortOrder);

public record AdminGarmentDto(
    Guid Id,
    Guid ServiceId,
    string ServiceName,
    string Name,
    string? Emoji,
    decimal? PriceOverride,
    int SortOrder);

public record CreateGarmentRequest(
    Guid ServiceId,
    string Name,
    string? Emoji,
    decimal? PriceOverride,
    int? SortOrder);

public record UpdateGarmentRequest(
    string? Name,
    string? Emoji,
    decimal? PriceOverride,
    int? SortOrder);

public record AdminTreatmentDto(
    Guid Id,
    Guid ServiceId,
    string ServiceName,
    string Name,
    string? Description,
    decimal PriceMultiplier,
    bool IsActive,
    int SortOrder);

public record CreateTreatmentRequest(
    Guid ServiceId,
    string Name,
    string? Description,
    decimal PriceMultiplier,
    int? SortOrder);

public record UpdateTreatmentRequest(
    string? Name,
    string? Description,
    decimal? PriceMultiplier,
    bool? IsActive,
    int? SortOrder);
