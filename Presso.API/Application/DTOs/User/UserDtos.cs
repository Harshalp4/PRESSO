namespace Presso.API.Application.DTOs.User;

public record UpdateProfileRequest(string? Name, string? Email, string? ProfilePhotoUrl);

public record AddressDto(
    Guid Id, string Label, string AddressLine1, string? AddressLine2,
    string City, string Pincode, double Lat, double Lng, bool IsDefault);

public record CreateAddressRequest(
    string Label, string AddressLine1, string? AddressLine2,
    string City, string Pincode, double Lat, double Lng, bool IsDefault);

public record UpdateAddressRequest(
    string? Label, string? AddressLine1, string? AddressLine2,
    string? City, string? Pincode, double? Lat, double? Lng);

public record SavingsDto(
    decimal TotalSaved,
    decimal CoinSavings,
    decimal StudentSavings,
    decimal AdminSavings,
    // Count of delivered orders — surfaced on the home savings strip
    // ("You've saved ₹X with Presso · N orders") so the customer can see
    // their lifetime order count alongside their savings.
    int OrderCount);

public record StudentVerifyRequest(string IdPhotoUrl);
