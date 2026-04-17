namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Auth;
using Presso.API.Application.DTOs.Common;

public interface IAuthService
{
    Task<Result<AuthResponse>> LoginWithFirebaseAsync(LoginRequest request);
    Task<Result<AuthResponse>> RefreshTokenAsync(string refreshToken);
    Task<Result<AuthResponse>> LoginAsAdminAsync(AdminLoginRequest request);
}
