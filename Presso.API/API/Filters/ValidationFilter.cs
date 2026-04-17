namespace Presso.API.API.Filters;

using FluentValidation;
using Presso.API.Application.DTOs.Common;

public static class ValidationFilter
{
    public static async ValueTask<object?> ValidateAsync<T>(T request, IValidator<T> validator, HttpContext context, Func<T, Task<IResult>> next)
    {
        var result = await validator.ValidateAsync(request);
        if (!result.IsValid)
        {
            var errors = result.Errors.Select(e => e.ErrorMessage).ToList();
            return Results.BadRequest(ApiResponse.Fail("Validation failed", errors));
        }
        return await next(request);
    }

    public static RouteHandlerBuilder WithValidation<T>(this RouteHandlerBuilder builder) where T : class
    {
        return builder.AddEndpointFilter(async (context, next) =>
        {
            var validator = context.HttpContext.RequestServices.GetService<IValidator<T>>();
            if (validator == null) return await next(context);

            var argument = context.Arguments.OfType<T>().FirstOrDefault();
            if (argument == null) return await next(context);

            var validationResult = await validator.ValidateAsync(argument);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return Results.BadRequest(ApiResponse.Fail("Validation failed", errors));
            }

            return await next(context);
        });
    }
}
