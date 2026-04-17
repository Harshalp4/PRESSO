namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Order;

public class RepeatOrderRequestValidator : AbstractValidator<RepeatOrderRequest>
{
    public RepeatOrderRequestValidator()
    {
        RuleFor(x => x.OriginalOrderId).NotEmpty().WithMessage("Original order ID is required");
        RuleFor(x => x.AddressId).NotEmpty().WithMessage("Address ID is required");
    }
}
