namespace Presso.API.Application.DTOs.Common;

using System.Security.Claims;

public static class ResultExtensions
{
    public static IResult ToResult<T>(this Result<T> result)
    {
        if (result.IsSuccess)
            return Results.Ok(ApiResponse<T>.Ok(result.Value!));

        return result.StatusCode switch
        {
            401 => Results.Unauthorized(),
            403 => Results.Json(ApiResponse.Fail(result.Error!), statusCode: 403),
            404 => Results.NotFound(ApiResponse.Fail(result.Error!)),
            _ => Results.BadRequest(ApiResponse.Fail(result.Error!))
        };
    }

    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var claim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(claim, out var id) ? id : Guid.Empty;
    }
}
