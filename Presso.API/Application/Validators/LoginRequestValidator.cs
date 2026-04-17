namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Auth;

public class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.FirebaseToken).NotEmpty().WithMessage("Firebase token is required");
        RuleFor(x => x.Name).MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.Email).EmailAddress().When(x => x.Email != null);
        RuleFor(x => x.ProfilePhotoUrl).MaximumLength(512).When(x => x.ProfilePhotoUrl != null);
    }
}
