namespace Presso.API.Application.Interfaces;

using Presso.API.Application.DTOs.Common;

public interface IStudentVerificationService
{
    Task<Result<bool>> SubmitAsync(Guid userId, string idPhotoUrl);
    Task<Result<bool>> ReviewAsync(Guid verificationId, bool approved, string? reviewNote);
}
