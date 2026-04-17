namespace Presso.API.Application.DTOs.Admin;

public record ServiceZoneDto(
    Guid Id,
    string Name,
    string Pincode,
    string City,
    string? Area,
    string? Description,
    bool IsActive,
    int SortOrder,
    Guid? AssignedStoreId,
    string? AssignedStoreName,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

public record CreateServiceZoneRequest(
    string Name,
    string Pincode,
    string City,
    string? Area,
    string? Description,
    Guid? AssignedStoreId
);

public record UpdateServiceZoneRequest(
    string? Name,
    string? Pincode,
    string? City,
    string? Area,
    string? Description,
    bool? IsActive,
    int? SortOrder,
    Guid? AssignedStoreId
);

public record ServiceZoneCheckResponse(
    bool IsServiceable,
    string? ZoneName,
    string? Message
);
