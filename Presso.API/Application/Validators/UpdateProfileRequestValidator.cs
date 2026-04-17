namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.User;

public class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileRequestValidator()
    {
        RuleFor(x => x.Name).MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.Email).EmailAddress().When(x => x.Email != null);
    }
}
