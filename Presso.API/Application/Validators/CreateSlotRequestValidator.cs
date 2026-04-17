namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Admin;

public class CreateSlotRequestValidator : AbstractValidator<CreateSlotRequest>
{
    public CreateSlotRequestValidator()
    {
        RuleFor(x => x.StartTime).NotEmpty();
        RuleFor(x => x.EndTime).NotEmpty().GreaterThan(x => x.StartTime);
        RuleFor(x => x.MaxOrders).GreaterThan(0).LessThanOrEqualTo(100);
    }
}
