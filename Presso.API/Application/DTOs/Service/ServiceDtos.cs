namespace Presso.API.Application.DTOs.Service;

public record ServiceDto(
    Guid Id, string Name, string? Description, string Category,
    decimal PricePerPiece, string? IconUrl, string? Emoji, int SortOrder,
    List<GarmentTypeDto> GarmentTypes,
    List<ServiceTreatmentDto> Treatments);

public record GarmentTypeDto(Guid Id, string Name, string? Emoji, decimal? PriceOverride, int SortOrder);

public record ServiceTreatmentDto(Guid Id, string Name, string? Description, decimal PriceMultiplier, int SortOrder);
