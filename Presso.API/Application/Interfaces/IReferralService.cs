namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Referral;

public interface IReferralService
{
    Task<Result<ReferralStatsDto>> GetReferralStatsAsync(Guid userId);
    Task<Result<bool>> ApplyReferralCodeAsync(Guid userId, string referralCode);
    Task<Result<List<ReferralHistoryDto>>> GetReferralHistoryAsync(Guid userId);
    Task RewardReferralAsync(Guid referredUserId);
}
