using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using ImageUpload.Functions.Models;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Services;

public class BlobStorageService
{
    private readonly BlobContainerClient _containerClient;
    private readonly ILogger<BlobStorageService> _logger;
    private readonly int _maxFileSizeBytes;

    public BlobStorageService(ILogger<BlobStorageService> logger)
    {
        _logger = logger;

        var connectionString = Environment.GetEnvironmentVariable("BlobStorageConnectionString")
            ?? throw new InvalidOperationException("BlobStorageConnectionString not configured");
        var containerName = Environment.GetEnvironmentVariable("BlobContainerName")
            ?? "uploaded-images";

        _maxFileSizeBytes = int.TryParse(Environment.GetEnvironmentVariable("MaxFileSizeBytes"), out var size)
            ? size : 5242880; // Default 5MB

        var blobServiceClient = new BlobServiceClient(connectionString);
        _containerClient = blobServiceClient.GetBlobContainerClient(containerName);
    }

    public async Task InitializeAsync()
    {
        await _containerClient.CreateIfNotExistsAsync(PublicAccessType.None);
        _logger.LogInformation("Blob container initialized: {ContainerName}", _containerClient.Name);
    }

    public async Task<bool> UploadImageAsync(ImageMetadata metadata, byte[] imageData)
    {
        try
        {
            // Validate file size
            if (imageData.Length > _maxFileSizeBytes)
            {
                _logger.LogWarning("Image too large: {Size} bytes (max: {Max})",
                    imageData.Length, _maxFileSizeBytes);
                return false;
            }

            var blobName = metadata.GetBlobName();
            var blobClient = _containerClient.GetBlobClient(blobName);

            // Set blob metadata
            var blobMetadata = new Dictionary<string, string>
            {
                { "DeviceId", metadata.DeviceId },
                { "ImageType", metadata.ImageType },
                { "Format", metadata.Format },
                { "UploadedAt", metadata.UploadedAt.ToString("O") },
                { "SizeBytes", metadata.SizeBytes.ToString() }
            };

            // Upload with metadata
            using var stream = new MemoryStream(imageData);
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                Metadata = blobMetadata,
                HttpHeaders = new BlobHttpHeaders
                {
                    ContentType = metadata.Format == "png" ? "image/png" : "image/jpeg"
                }
            });

            _logger.LogInformation("Uploaded image: {BlobName} ({Size} bytes)", blobName, imageData.Length);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to upload image for device {DeviceId}", metadata.DeviceId);
            return false;
        }
    }

    public async Task<ImageMetadata?> GetImageMetadataAsync(string deviceId)
    {
        try
        {
            // Check for both logo and background (check logo first as it's more common)
            foreach (var imageType in new[] { "logo", "background" })
            {
                foreach (var format in new[] { "png", "jpeg" })
                {
                    var blobName = $"{deviceId}_{imageType}.{format}";
                    var blobClient = _containerClient.GetBlobClient(blobName);

                    if (await blobClient.ExistsAsync())
                    {
                        var properties = await blobClient.GetPropertiesAsync();

                        return new ImageMetadata
                        {
                            DeviceId = deviceId,
                            ImageType = imageType,
                            Format = format,
                            SizeBytes = (int)properties.Value.ContentLength,
                            UploadedAt = properties.Value.CreatedOn.DateTime,
                            DownloadCount = 0
                        };
                    }
                }
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get image metadata for device {DeviceId}", deviceId);
            return null;
        }
    }

    public async Task<byte[]?> DownloadImageAsync(string deviceId)
    {
        try
        {
            var metadata = await GetImageMetadataAsync(deviceId);
            if (metadata == null)
                return null;

            var blobName = metadata.GetBlobName();
            var blobClient = _containerClient.GetBlobClient(blobName);

            using var memoryStream = new MemoryStream();
            await blobClient.DownloadToAsync(memoryStream);

            _logger.LogInformation("Downloaded image: {BlobName} ({Size} bytes)",
                blobName, memoryStream.Length);

            return memoryStream.ToArray();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to download image for device {DeviceId}", deviceId);
            return null;
        }
    }

    public async Task<bool> DeleteImageAsync(string deviceId)
    {
        try
        {
            var metadata = await GetImageMetadataAsync(deviceId);
            if (metadata == null)
                return false;

            var blobName = metadata.GetBlobName();
            var blobClient = _containerClient.GetBlobClient(blobName);

            await blobClient.DeleteIfExistsAsync();

            _logger.LogInformation("Deleted image: {BlobName}", blobName);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete image for device {DeviceId}", deviceId);
            return false;
        }
    }

    public async Task CleanupExpiredImagesAsync(TimeSpan maxAge)
    {
        try
        {
            var cutoffTime = DateTime.UtcNow - maxAge;
            var deletedCount = 0;

            await foreach (var blobItem in _containerClient.GetBlobsAsync(BlobTraits.Metadata))
            {
                if (blobItem.Properties.CreatedOn < cutoffTime)
                {
                    var blobClient = _containerClient.GetBlobClient(blobItem.Name);
                    await blobClient.DeleteIfExistsAsync();
                    deletedCount++;
                }
            }

            if (deletedCount > 0)
            {
                _logger.LogInformation("Cleaned up {Count} expired images", deletedCount);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cleanup expired images");
        }
    }
}
