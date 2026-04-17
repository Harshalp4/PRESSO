namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Admin;

public class AssignRiderRequestValidator : AbstractValidator<AssignRiderRequest>
{
    public AssignRiderRequestValidator()
    {
        RuleFor(x => x.OrderId).NotEmpty();
        RuleFor(x => x.RiderId).NotEmpty();
        RuleFor(x => x.Type).NotEmpty().Must(t => t is "Pickup" or "Delivery")
            .WithMessage("Type must be 'Pickup' or 'Delivery'");
    }
}
