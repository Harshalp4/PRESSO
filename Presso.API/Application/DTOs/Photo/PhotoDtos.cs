namespace Presso.API.Application.DTOs.Photo;

public record PhotoUploadResponse(int UploadedCount, List<string> PhotoUrls, string Message);

public record PhotoListResponse(List<string> PhotoUrls, DateTime? UploadedAt, int Count);

public record PhotoDeleteResponse(int RemainingCount, List<string> PhotoUrls);
