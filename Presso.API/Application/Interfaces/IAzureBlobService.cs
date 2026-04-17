namespace Presso.API.Application.Interfaces;

public interface IAzureBlobService
{
    Task<string> UploadPhotoAsync(Stream fileStream, string fileName, string contentType, string folder);
    Task DeletePhotoAsync(string blobUrl);
    string GenerateSasUrl(string blobUrl, int expiryMinutes = 60);
}
