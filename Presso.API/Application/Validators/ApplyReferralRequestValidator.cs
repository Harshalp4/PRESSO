namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Referral;

public class ApplyReferralRequestValidator : AbstractValidator<ApplyReferralRequest>
{
    public ApplyReferralRequestValidator()
    {
        RuleFor(x => x.ReferralCode).NotEmpty().Length(8).WithMessage("Referral code must be 8 characters");
    }
}
