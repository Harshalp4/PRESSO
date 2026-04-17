namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.Rider;

public class LocationUpdateRequestValidator : AbstractValidator<LocationUpdateRequest>
{
    public LocationUpdateRequestValidator()
    {
        RuleFor(x => x.Lat).InclusiveBetween(-90, 90);
        RuleFor(x => x.Lng).InclusiveBetween(-180, 180);
    }
}
