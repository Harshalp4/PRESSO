namespace Presso.API.API.Endpoints;

using System.Security.Claims;
using Presso.API.API.Filters;
using Presso.API.Application.DTOs.Common;
using Presso.API.Application.DTOs.Referral;
using Presso.API.Application.Interfaces;

public static class ReferralEndpoints
{
    public static RouteGroupBuilder MapReferralEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/referrals").WithTags("Referrals").RequireAuthorization();

        group.MapGet("/my-code", async (ClaimsPrincipal user, IReferralService referralService) =>
        {
            var result = await referralService.GetReferralStatsAsync(user.GetUserId());
            return result.ToResult();
        });

        group.MapPost("/apply", async (ClaimsPrincipal user, ApplyReferralRequest request, IReferralService referralService) =>
        {
            var result = await referralService.ApplyReferralCodeAsync(user.GetUserId(), request.ReferralCode);
            return result.ToResult();
        }).WithValidation<ApplyReferralRequest>();

        group.MapGet("/history", async (ClaimsPrincipal user, IReferralService referralService) =>
        {
            var result = await referralService.GetReferralHistoryAsync(user.GetUserId());
            return result.ToResult();
        });

        return group;
    }
}
