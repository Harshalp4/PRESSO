namespace Presso.API.Application.DTOs.Auth;

public record LoginRequest(
    string FirebaseToken,
    string? FcmToken = null,
    string? Name = null,
    string? Email = null,
    string? ProfilePhotoUrl = null);
public record RefreshTokenRequest(string RefreshToken);
public record AdminLoginRequest(string Username, string Password);
public record AuthResponse(string AccessToken, string RefreshToken, UserProfileDto User);

public record UserProfileDto(
    Guid Id,
    string Phone,
    string? Name,
    string? Email,
    string Role,
    bool IsStudentVerified,
    string ReferralCode,
    int CoinBalance,
    string? ProfilePhotoUrl);
