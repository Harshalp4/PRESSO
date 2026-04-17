namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.User;

public class FcmTokenRequestValidator : AbstractValidator<FcmTokenRequest>
{
    public FcmTokenRequestValidator()
    {
        RuleFor(x => x.Token).NotEmpty().MaximumLength(512)
            .WithMessage("FCM token is required");
    }
}
