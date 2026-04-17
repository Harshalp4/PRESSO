namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Order;

public class CreateOrderRequestValidator : AbstractValidator<CreateOrderRequest>
{
    public CreateOrderRequestValidator()
    {
        RuleFor(x => x.AddressId).NotEmpty();
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required");
        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ServiceId).NotEmpty();
            item.RuleFor(i => i.Quantity).GreaterThan(0).LessThanOrEqualTo(100);
        });
        RuleFor(x => x.CoinsToRedeem).GreaterThanOrEqualTo(0);
    }
}
