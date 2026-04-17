namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Auth;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.User;

public interface IUserService
{
    Task<Result<UserProfileDto>> GetProfileAsync(Guid userId);
    Task<Result<UserProfileDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);
    Task<Result<bool>> SubmitStudentVerificationAsync(Guid userId, StudentVerifyRequest request);
    Task<Result<SavingsDto>> GetSavingsAsync(Guid userId);
    Task<Result<List<AddressDto>>> GetAddressesAsync(Guid userId);
    Task<Result<AddressDto>> CreateAddressAsync(Guid userId, CreateAddressRequest request);
    Task<Result<AddressDto>> UpdateAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request);
    Task<Result<bool>> DeleteAddressAsync(Guid userId, Guid addressId);
    Task<Result<bool>> SetDefaultAddressAsync(Guid userId, Guid addressId);
    Task<Result<bool>> UpdateFcmTokenAsync(Guid userId, string token);
}
