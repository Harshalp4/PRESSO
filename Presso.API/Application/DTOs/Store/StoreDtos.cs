namespace Presso.API.Application.DTOs.Store;

public record StoreLocationDto(
    Guid Id,
    string Name,
    string AddressLine1,
    string? AddressLine2,
    string City,
    string State,
    string Pincode,
    double Latitude,
    double Longitude,
    string Phone,
    string? Email,
    string? GoogleMapsUrl,
    TimeOnly OpenTime,
    TimeOnly CloseTime,
    bool IsOpenSunday,
    double ServiceRadiusKm,
    bool IsActive,
    bool IsHeadquarters);

public record CreateStoreRequest(
    string Name,
    string AddressLine1,
    string? AddressLine2,
    string City,
    string State,
    string Pincode,
    double Latitude,
    double Longitude,
    string Phone,
    string? Email,
    string? GoogleMapsUrl,
    TimeOnly OpenTime,
    TimeOnly CloseTime,
    bool IsOpenSunday,
    double ServiceRadiusKm,
    bool IsHeadquarters);

public record NearestStoreResponse(
    StoreLocationDto Store,
    double DistanceKm,
    bool OutsideServiceArea);

public record FacilityInfoDto(
    string? StoreName,
    string? StoreAddress,
    string? StorePhone,
    string? GoogleMapsUrl);
