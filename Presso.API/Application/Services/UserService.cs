namespace Presso.API.Application.Services;

using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Auth;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.User;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public class UserService : IUserService
{
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<Address> _addressRepo;
    private readonly IRepository<Order> _orderRepo;
    private readonly IRepository<StudentVerification> _verificationRepo;
    private readonly IMapper _mapper;

    public UserService(
        IRepository<User> userRepo,
        IRepository<Address> addressRepo,
        IRepository<Order> orderRepo,
        IRepository<StudentVerification> verificationRepo,
        IMapper mapper)
    {
        _userRepo = userRepo;
        _addressRepo = addressRepo;
        _orderRepo = orderRepo;
        _verificationRepo = verificationRepo;
        _mapper = mapper;
    }

    public async Task<Result<UserProfileDto>> GetProfileAsync(Guid userId)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        if (user == null) return Result<UserProfileDto>.NotFound("User not found");
        return Result<UserProfileDto>.Success(_mapper.Map<UserProfileDto>(user));
    }

    public async Task<Result<UserProfileDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        if (user == null) return Result<UserProfileDto>.NotFound("User not found");

        if (request.Name != null) user.Name = request.Name;
        if (request.Email != null) user.Email = request.Email;
        if (request.ProfilePhotoUrl != null) user.ProfilePhotoUrl = request.ProfilePhotoUrl;

        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();
        return Result<UserProfileDto>.Success(_mapper.Map<UserProfileDto>(user));
    }

    public async Task<Result<bool>> SubmitStudentVerificationAsync(Guid userId, StudentVerifyRequest request)
    {
        var existing = await _verificationRepo.FirstOrDefaultAsync(v => v.UserId == userId && v.Status == Domain.Enums.VerificationStatus.Pending);
        if (existing != null) return Result<bool>.Failure("A verification request is already pending");

        await _verificationRepo.AddAsync(new StudentVerification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            IdPhotoUrl = request.IdPhotoUrl
        });
        await _verificationRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<SavingsDto>> GetSavingsAsync(Guid userId)
    {
        var orders = await _orderRepo.Query().Where(o => o.UserId == userId).ToListAsync();
        var coinSavings = orders.Sum(o => o.CoinDiscount);
        var studentSavings = orders.Sum(o => o.StudentDiscount);
        var adminSavings = orders.Sum(o => o.AdminDiscount);
        // Count every non-cancelled order so the home strip reflects the
        // customer's total lifetime order count, matching what they see in
        // My Orders. (Cancelled orders shouldn't count toward the tally.)
        var orderCount = orders.Count(o => o.Status != OrderStatus.Cancelled);
        return Result<SavingsDto>.Success(new SavingsDto(
            coinSavings + studentSavings + adminSavings,
            coinSavings,
            studentSavings,
            adminSavings,
            orderCount));
    }

    public async Task<Result<bool>> UpdateFcmTokenAsync(Guid userId, string token)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        if (user == null) return Result<bool>.NotFound("User not found");

        user.FcmToken = token;
        user.FcmTokenUpdatedAt = DateTime.UtcNow;
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<List<AddressDto>>> GetAddressesAsync(Guid userId)
    {
        var addresses = await _addressRepo.Query()
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt)
            .ToListAsync();
        return Result<List<AddressDto>>.Success(addresses.Select(a => _mapper.Map<AddressDto>(a)).ToList());
    }

    public async Task<Result<AddressDto>> CreateAddressAsync(Guid userId, CreateAddressRequest request)
    {
        if (request.IsDefault)
        {
            var existing = await _addressRepo.FindAsync(a => a.UserId == userId && a.IsDefault);
            foreach (var addr in existing)
            {
                addr.IsDefault = false;
                _addressRepo.Update(addr);
            }
        }

        var address = _mapper.Map<Address>(request);
        address.Id = Guid.NewGuid();
        address.UserId = userId;

        await _addressRepo.AddAsync(address);
        await _addressRepo.SaveChangesAsync();
        return Result<AddressDto>.Success(_mapper.Map<AddressDto>(address));
    }

    public async Task<Result<AddressDto>> UpdateAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        if (address == null) return Result<AddressDto>.NotFound("Address not found");

        if (request.Label != null) address.Label = request.Label;
        if (request.AddressLine1 != null) address.AddressLine1 = request.AddressLine1;
        if (request.AddressLine2 != null) address.AddressLine2 = request.AddressLine2;
        if (request.City != null) address.City = request.City;
        if (request.Pincode != null) address.Pincode = request.Pincode;
        if (request.Lat.HasValue) address.Lat = request.Lat.Value;
        if (request.Lng.HasValue) address.Lng = request.Lng.Value;

        _addressRepo.Update(address);
        await _addressRepo.SaveChangesAsync();
        return Result<AddressDto>.Success(_mapper.Map<AddressDto>(address));
    }

    public async Task<Result<bool>> DeleteAddressAsync(Guid userId, Guid addressId)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        if (address == null) return Result<bool>.NotFound("Address not found");

        address.IsDeleted = true;
        _addressRepo.Update(address);
        await _addressRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> SetDefaultAddressAsync(Guid userId, Guid addressId)
    {
        var addresses = await _addressRepo.FindAsync(a => a.UserId == userId);
        foreach (var addr in addresses)
        {
            addr.IsDefault = addr.Id == addressId;
            _addressRepo.Update(addr);
        }
        await _addressRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }
}
