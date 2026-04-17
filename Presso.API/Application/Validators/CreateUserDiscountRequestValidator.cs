namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Admin;

public class CreateUserDiscountRequestValidator : AbstractValidator<CreateUserDiscountRequest>
{
    public CreateUserDiscountRequestValidator()
    {
        RuleFor(x => x.Type).NotEmpty().Must(t => t == "Percentage" || t == "FlatAmount")
            .WithMessage("Type must be 'Percentage' or 'FlatAmount'");
        RuleFor(x => x.Value).GreaterThan(0);
        RuleFor(x => x.Value).LessThanOrEqualTo(50).When(x => x.Type == "Percentage")
            .WithMessage("Percentage discount must be between 1 and 50");
        RuleFor(x => x.Value).LessThanOrEqualTo(500).When(x => x.Type == "FlatAmount")
            .WithMessage("Flat discount must be between ₹1 and ₹500");
        RuleFor(x => x.Reason).NotEmpty().MinimumLength(5).MaximumLength(500);
        RuleFor(x => x.UsageLimit).GreaterThan(0).When(x => x.UsageLimit.HasValue);
    }
}
