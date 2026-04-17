namespace Presso.API.Application.Services;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using FirebaseAdmin.Auth;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Presso.API.Application.DTOs.Auth;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;
using Presso.API.Infrastructure.Data;

public class AuthService : IAuthService
{
    private readonly IRepository<User> _userRepo;
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;
    private readonly ILogger<AuthService> _logger;

    public AuthService(IRepository<User> userRepo, AppDbContext context, IConfiguration config, ILogger<AuthService> logger)
    {
        _userRepo = userRepo;
        _context = context;
        _config = config;
        _logger = logger;
    }

    public async Task<Result<AuthResponse>> LoginWithFirebaseAsync(LoginRequest request)
    {
        string firebaseUid;
        string? phone;

        var isDevAuth = _config.GetValue<bool>("DevAuth");
        if (isDevAuth)
        {
            // Dev mode: treat FirebaseToken as the phone number directly
            phone = request.FirebaseToken.StartsWith("+91")
                ? request.FirebaseToken
                : $"+91{request.FirebaseToken}";
            firebaseUid = $"dev_{phone}";
            _logger.LogInformation("Dev auth: bypassing Firebase for phone {Phone}", phone);
        }
        else
        {
            FirebaseToken firebaseToken;
            try
            {
                firebaseToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(request.FirebaseToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Firebase token verification failed");
                return Result<AuthResponse>.Unauthorized("Invalid Firebase token");
            }

            firebaseUid = firebaseToken.Uid;
            phone = firebaseToken.Claims.TryGetValue("phone_number", out var p) ? p?.ToString() : null;
        }

        if (string.IsNullOrEmpty(phone))
            return Result<AuthResponse>.Failure("Phone number not found in Firebase token");

        var user = await _userRepo.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);
        if (user == null)
        {
            // In dev mode, assign roles based on test phone numbers
            var role = UserRole.Customer;
            if (isDevAuth)
            {
                if (phone.EndsWith("8888888888")) role = UserRole.Rider;
                else if (phone.EndsWith("7777777777")) role = UserRole.FacilityStaff;
            }

            user = new User
            {
                Id = Guid.NewGuid(),
                FirebaseUid = firebaseUid,
                Phone = phone,
                Name = request.Name,
                Email = request.Email,
                ProfilePhotoUrl = request.ProfilePhotoUrl,
                ReferralCode = GenerateReferralCode(),
                Role = role
            };
            await _userRepo.AddAsync(user);
            await _userRepo.SaveChangesAsync();
            _logger.LogInformation("New user created: {UserId} with phone {Phone}", user.Id, phone);
        }

        // In dev mode, fix role for existing test accounts on every login
        if (isDevAuth)
        {
            var expectedRole = UserRole.Customer;
            if (phone.EndsWith("8888888888")) expectedRole = UserRole.Rider;
            else if (phone.EndsWith("7777777777")) expectedRole = UserRole.FacilityStaff;

            if (user.Role != expectedRole && expectedRole != UserRole.Customer)
            {
                user.Role = expectedRole;
                _userRepo.Update(user);
                await _userRepo.SaveChangesAsync();
                _logger.LogInformation("Dev auth: updated role for {UserId} to {Role}", user.Id, expectedRole);
            }

            // Auto-create Rider entity for Rider-role users if missing
            if (user.Role == UserRole.Rider)
            {
                var existingRider = await _context.Set<Rider>().FirstOrDefaultAsync(r => r.UserId == user.Id);
                if (existingRider == null)
                {
                    _context.Set<Rider>().Add(new Rider
                    {
                        Id = Guid.NewGuid(),
                        UserId = user.Id,
                        IsActive = true,
                        IsAvailable = true
                    });
                    await _context.SaveChangesAsync();
                    _logger.LogInformation("Dev auth: auto-created Rider entity for user {UserId}", user.Id);
                }
            }
        }

        if (!user.IsActive)
            return Result<AuthResponse>.Forbidden("Account is deactivated");

        var needsUpdate = false;
        if (request.FcmToken != null)
        {
            user.FcmToken = request.FcmToken;
            user.FcmTokenUpdatedAt = DateTime.UtcNow;
            needsUpdate = true;
        }
        // Update profile fields on subsequent logins if provided and currently empty
        if (request.Name != null && user.Name == null) { user.Name = request.Name; needsUpdate = true; }
        if (request.Email != null && user.Email == null) { user.Email = request.Email; needsUpdate = true; }
        if (request.ProfilePhotoUrl != null && user.ProfilePhotoUrl == null) { user.ProfilePhotoUrl = request.ProfilePhotoUrl; needsUpdate = true; }

        if (needsUpdate)
        {
            _userRepo.Update(user);
            await _userRepo.SaveChangesAsync();
        }

        var accessToken = GenerateJwt(user);
        var refreshToken = await CreateRefreshTokenAsync(user.Id);
        var profile = new UserProfileDto(user.Id, user.Phone, user.Name, user.Email,
            user.Role.ToString(), user.IsStudentVerified, user.ReferralCode,
            user.CoinBalance, user.ProfilePhotoUrl);

        return Result<AuthResponse>.Success(new AuthResponse(accessToken, refreshToken, profile));
    }

    public async Task<Result<AuthResponse>> LoginAsAdminAsync(AdminLoginRequest request)
    {
        // Admin panel uses a simple username/password check against config.
        // Credentials live in appsettings.json → "AdminAuth". No schema change.
        var expectedUser = _config["AdminAuth:Username"];
        var expectedPass = _config["AdminAuth:Password"];

        if (string.IsNullOrEmpty(expectedUser) || string.IsNullOrEmpty(expectedPass))
            return Result<AuthResponse>.Failure("Admin auth is not configured");

        if (!string.Equals(request.Username, expectedUser, StringComparison.Ordinal)
            || !string.Equals(request.Password, expectedPass, StringComparison.Ordinal))
            return Result<AuthResponse>.Unauthorized("Invalid username or password");

        // Resolve (or lazily create) the built-in admin User row so the JWT
        // carries a real UserId. Keyed by FirebaseUid = "admin_builtin".
        const string adminFirebaseUid = "admin_builtin";
        var user = await _userRepo.FirstOrDefaultAsync(u => u.FirebaseUid == adminFirebaseUid);
        if (user == null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FirebaseUid = adminFirebaseUid,
                Phone = "+ADMIN",
                Name = "Admin",
                Role = UserRole.Admin,
                ReferralCode = GenerateReferralCode(),
                IsActive = true
            };
            await _userRepo.AddAsync(user);
            await _userRepo.SaveChangesAsync();
            _logger.LogInformation("Built-in admin user created: {UserId}", user.Id);
        }
        else if (user.Role != UserRole.Admin)
        {
            // Self-heal in case role drifted
            user.Role = UserRole.Admin;
            _userRepo.Update(user);
            await _userRepo.SaveChangesAsync();
        }

        if (!user.IsActive)
            return Result<AuthResponse>.Forbidden("Admin account is deactivated");

        var accessToken = GenerateJwt(user);
        var refreshToken = await CreateRefreshTokenAsync(user.Id);
        var profile = new UserProfileDto(user.Id, user.Phone, user.Name, user.Email,
            user.Role.ToString(), user.IsStudentVerified, user.ReferralCode,
            user.CoinBalance, user.ProfilePhotoUrl);

        return Result<AuthResponse>.Success(new AuthResponse(accessToken, refreshToken, profile));
    }

    public async Task<Result<AuthResponse>> RefreshTokenAsync(string refreshToken)
    {
        var tokenHash = HashToken(refreshToken);
        var storedToken = await _context.RefreshTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.TokenHash == tokenHash && !t.IsRevoked);

        if (storedToken == null)
            return Result<AuthResponse>.Unauthorized("Invalid refresh token");

        if (storedToken.ExpiresAt < DateTime.UtcNow)
        {
            storedToken.IsRevoked = true;
            await _context.SaveChangesAsync();
            return Result<AuthResponse>.Unauthorized("Refresh token expired");
        }

        var user = storedToken.User;
        if (!user.IsActive)
            return Result<AuthResponse>.Forbidden("Account is deactivated");

        // Revoke old token and issue new pair
        storedToken.IsRevoked = true;

        var newAccessToken = GenerateJwt(user);
        var newRefreshToken = await CreateRefreshTokenAsync(user.Id);
        var profile = new UserProfileDto(user.Id, user.Phone, user.Name, user.Email,
            user.Role.ToString(), user.IsStudentVerified, user.ReferralCode,
            user.CoinBalance, user.ProfilePhotoUrl);

        return Result<AuthResponse>.Success(new AuthResponse(newAccessToken, newRefreshToken, profile));
    }

    private async Task<string> CreateRefreshTokenAsync(Guid userId)
    {
        var refreshExpiryDays = _config.GetValue<int>("JwtSettings:RefreshExpiryInDays", 30);
        var rawToken = GenerateRefreshToken();

        var token = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Token = rawToken,
            TokenHash = HashToken(rawToken),
            ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiryDays)
        };

        _context.RefreshTokens.Add(token);
        await _context.SaveChangesAsync();
        return rawToken;
    }

    private static string HashToken(string token)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    private string GenerateJwt(User user)
    {
        var jwtSettings = _config.GetSection("JwtSettings");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.MobilePhone, user.Phone),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim("firebase_uid", user.FirebaseUid)
        };

        var token = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(double.Parse(jwtSettings["ExpiryInMinutes"]!)),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string GenerateRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes);
    }

    private static string GenerateReferralCode()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        var bytes = RandomNumberGenerator.GetBytes(8);
        return new string(bytes.Select(b => chars[b % chars.Length]).ToArray());
    }
}
