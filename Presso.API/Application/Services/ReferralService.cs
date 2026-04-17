namespace Presso.API.Application.Services;

using Microsoft.EntityFrameworkCore;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Referral;
using Presso.API.Application.Interfaces;
using Presso.API.Domain.Entities;
using Presso.API.Domain.Enums;

public class ReferralService : IReferralService
{
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<Referral> _referralRepo;
    private readonly IRepository<CoinsLedger> _coinsRepo;
    private readonly Infrastructure.Data.AppDbContext _dbContext;
    private readonly ILogger<ReferralService> _logger;

    public ReferralService(
        IRepository<User> userRepo,
        IRepository<Referral> referralRepo,
        IRepository<CoinsLedger> coinsRepo,
        Infrastructure.Data.AppDbContext dbContext,
        ILogger<ReferralService> logger)
    {
        _userRepo = userRepo;
        _referralRepo = referralRepo;
        _coinsRepo = coinsRepo;
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<Result<ReferralStatsDto>> GetReferralStatsAsync(Guid userId)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        if (user == null) return Result<ReferralStatsDto>.NotFound("User not found");

        var referrals = await _referralRepo.FindAsync(r => r.ReferrerUserId == userId);
        var referralList = referrals.ToList();

        return Result<ReferralStatsDto>.Success(new ReferralStatsDto(
            user.ReferralCode,
            referralList.Count,
            referralList.Count(r => r.Status == ReferralStatus.Completed),
            referralList.Sum(r => r.CoinsEarned)));
    }

    public async Task<Result<bool>> ApplyReferralCodeAsync(Guid userId, string referralCode)
    {
        var referrer = await _userRepo.FirstOrDefaultAsync(u => u.ReferralCode == referralCode);
        if (referrer == null) return Result<bool>.Failure("Invalid referral code");
        if (referrer.Id == userId) return Result<bool>.Failure("Cannot use your own referral code");

        var existingReferral = await _referralRepo.AnyAsync(r => r.ReferredUserId == userId);
        if (existingReferral) return Result<bool>.Failure("Referral already applied");

        await _referralRepo.AddAsync(new Referral
        {
            Id = Guid.NewGuid(),
            ReferrerUserId = referrer.Id,
            ReferredUserId = userId,
            ReferralCode = referralCode,
            Status = ReferralStatus.Pending
        });
        await _referralRepo.SaveChangesAsync();
        return Result<bool>.Success(true);
    }

    public async Task<Result<List<ReferralHistoryDto>>> GetReferralHistoryAsync(Guid userId)
    {
        var referrals = await _referralRepo.Query()
            .Where(r => r.ReferrerUserId == userId)
            .Include(r => r.ReferredUser)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        var history = referrals.Select(r => new ReferralHistoryDto(
            r.Id, r.ReferredUser.Name, r.Status.ToString(),
            r.CoinsEarned, r.CreatedAt)).ToList();

        return Result<List<ReferralHistoryDto>>.Success(history);
    }

    public async Task RewardReferralAsync(Guid referredUserId)
    {
        var referral = await _referralRepo.FirstOrDefaultAsync(r =>
            r.ReferredUserId == referredUserId && r.Status == ReferralStatus.Pending);
        if (referral == null) return;

        var configEntry = await _dbContext.AppConfigs
            .FirstOrDefaultAsync(c => c.Key == "referral_bonus_coins");
        var rewardCoins = int.TryParse(configEntry?.Value, out var parsed) ? parsed : 50;
        referral.Status = ReferralStatus.Completed;
        referral.CoinsEarned = rewardCoins;
        _referralRepo.Update(referral);

        var referrer = await _userRepo.GetByIdAsync(referral.ReferrerUserId);
        var referred = await _userRepo.GetByIdAsync(referredUserId);

        if (referrer != null)
        {
            referrer.CoinBalance += rewardCoins;
            _userRepo.Update(referrer);
            await _coinsRepo.AddAsync(new CoinsLedger
            {
                Id = Guid.NewGuid(), UserId = referrer.Id, Amount = rewardCoins,
                Type = CoinsType.Referral, Description = "Referral reward"
            });
        }

        if (referred != null)
        {
            referred.CoinBalance += rewardCoins;
            _userRepo.Update(referred);
            await _coinsRepo.AddAsync(new CoinsLedger
            {
                Id = Guid.NewGuid(), UserId = referred.Id, Amount = rewardCoins,
                Type = CoinsType.Referral, Description = "Referral welcome bonus"
            });
        }

        await _referralRepo.SaveChangesAsync();
        _logger.LogInformation("Referral reward processed for referrer {ReferrerId} and referred {ReferredId}",
            referral.ReferrerUserId, referredUserId);
    }
}
