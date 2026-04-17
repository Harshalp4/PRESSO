namespace Presso.API.Application.Validators;

using FluentValidation;
using Presso.API.Application.DTOs.User;

public class StudentVerifyRequestValidator : AbstractValidator<StudentVerifyRequest>
{
    public StudentVerifyRequestValidator()
    {
        RuleFor(x => x.IdPhotoUrl).NotEmpty().MaximumLength(512)
            .WithMessage("Student ID photo URL is required");
    }
}
