namespace Presso.API.Infrastructure.ExternalServices;

using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using Presso.API.Application.Interfaces;

public class AzureBlobService : IAzureBlobService
{
    private readonly BlobContainerClient? _containerClient;
    private readonly ILogger<AzureBlobService> _logger;
    private static readonly HashSet<string> AllowedContentTypes = new() { "image/jpeg", "image/png", "image/webp" };
    private const long MaxFileSizeBytes = 5 * 1024 * 1024; // 5MB

    // Hardcoded for dev/testing — move to env vars for production
    private const string HardcodedConnectionString =
        "DefaultEndpointsProtocol=https;AccountName=pressoimages;AccountKey=9YRs6QaZ9QDp/a9dAYbApRsQ/jIJTHmhFzN7iKiZuPj12DJQRB7+nfQK/GY4MSBoeys64VDVIzJo+AStY9xHgg==;EndpointSuffix=core.windows.net";
    private const string HardcodedContainerName = "presso";

    public AzureBlobService(IConfiguration config, ILogger<AzureBlobService> logger)
    {
        _logger = logger;
        var connectionString = HardcodedConnectionString;
        var containerName = HardcodedContainerName;

        var blobServiceClient = new BlobServiceClient(connectionString);
        _containerClient = blobServiceClient.GetBlobContainerClient(containerName);
    }

    public async Task<string> UploadPhotoAsync(Stream fileStream, string fileName, string contentType, string folder)
    {
        if (_containerClient == null)
            throw new InvalidOperationException("Azure Blob Storage is not configured");

        if (!AllowedContentTypes.Contains(contentType))
            throw new ArgumentException($"Content type '{contentType}' not allowed. Allowed: jpeg, png, webp");

        if (fileStream.Length > MaxFileSizeBytes)
            throw new ArgumentException($"File exceeds maximum size of 5MB");

        await _containerClient.CreateIfNotExistsAsync(PublicAccessType.None);

        var blobName = $"{folder}{Guid.NewGuid()}_{fileName}";
        var blobClient = _containerClient.GetBlobClient(blobName);

        var headers = new BlobHttpHeaders { ContentType = contentType };
        await blobClient.UploadAsync(fileStream, new BlobUploadOptions { HttpHeaders = headers });

        _logger.LogInformation("Uploaded blob: {BlobName}", blobName);
        return blobClient.Uri.ToString();
    }

    public async Task DeletePhotoAsync(string blobUrl)
    {
        if (_containerClient == null) return;

        try
        {
            var uri = new Uri(blobUrl);
            var blobName = string.Join("/", uri.Segments.Skip(2)).TrimStart('/');
            var blobClient = _containerClient.GetBlobClient(blobName);
            await blobClient.DeleteIfExistsAsync();
            _logger.LogInformation("Deleted blob: {BlobName}", blobName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete blob: {BlobUrl}", blobUrl);
        }
    }

    public string GenerateSasUrl(string blobUrl, int expiryMinutes = 60)
    {
        if (_containerClient == null)
            return blobUrl;

        try
        {
            var uri = new Uri(blobUrl);
            var blobName = string.Join("/", uri.Segments.Skip(2)).TrimStart('/');
            var blobClient = _containerClient.GetBlobClient(blobName);

            if (!blobClient.CanGenerateSasUri)
                return blobUrl;

            var sasBuilder = new BlobSasBuilder
            {
                BlobContainerName = _containerClient.Name,
                BlobName = blobName,
                Resource = "b",
                ExpiresOn = DateTimeOffset.UtcNow.AddMinutes(expiryMinutes)
            };
            sasBuilder.SetPermissions(BlobSasPermissions.Read);

            return blobClient.GenerateSasUri(sasBuilder).ToString();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate SAS URL for {BlobUrl}", blobUrl);
            return blobUrl;
        }
    }
}
