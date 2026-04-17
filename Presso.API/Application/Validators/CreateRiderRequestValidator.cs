namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Rider;

public class CreateRiderRequestValidator : AbstractValidator<CreateRiderRequest>
{
    public CreateRiderRequestValidator()
    {
        RuleFor(x => x.UserId).NotEmpty().WithMessage("UserId is required");
        RuleFor(x => x.VehicleNumber).MaximumLength(20).When(x => x.VehicleNumber != null);
    }
}
