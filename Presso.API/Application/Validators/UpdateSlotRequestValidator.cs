namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Admin;

public class UpdateSlotRequestValidator : AbstractValidator<UpdateSlotRequest>
{
    public UpdateSlotRequestValidator()
    {
        RuleFor(x => x.MaxOrders).GreaterThan(0).When(x => x.MaxOrders.HasValue)
            .WithMessage("MaxOrders must be greater than 0");
    }
}
