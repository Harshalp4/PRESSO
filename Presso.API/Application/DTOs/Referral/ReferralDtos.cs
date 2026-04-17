namespace Presso.API.Application.DTOs.Referral;

public record ReferralStatsDto(string ReferralCode, int TotalReferrals, int CompletedReferrals, int TotalCoinsEarned);

public record ApplyReferralRequest(string ReferralCode);

public record ReferralHistoryDto(
    Guid Id, string? ReferredUserName, string Status,
    int CoinsEarned, DateTime CreatedAt);
