namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.User;

public class UpdateAddressRequestValidator : AbstractValidator<UpdateAddressRequest>
{
    public UpdateAddressRequestValidator()
    {
        RuleFor(x => x.Label).MaximumLength(50).When(x => x.Label != null);
        RuleFor(x => x.AddressLine1).MaximumLength(200).When(x => x.AddressLine1 != null);
        RuleFor(x => x.AddressLine2).MaximumLength(200).When(x => x.AddressLine2 != null);
        RuleFor(x => x.City).MaximumLength(100).When(x => x.City != null);
        RuleFor(x => x.Pincode).Length(6).When(x => x.Pincode != null)
            .WithMessage("Pincode must be 6 digits");
        RuleFor(x => x.Lat).InclusiveBetween(-90, 90).When(x => x.Lat.HasValue);
        RuleFor(x => x.Lng).InclusiveBetween(-180, 180).When(x => x.Lng.HasValue);
    }
}
