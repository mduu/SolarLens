using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using ImageUpload.Functions.Models;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Services;

public class BlobStorageService
{
    private readonly BlobContainerClient containerClient;
    private readonly ILogger<BlobStorageService> logger;
    private readonly int maxFileSizeBytes;

    public BlobStorageService(ILogger<BlobStorageService> logger)
    {
        this.logger = logger;

        var connectionString = Environment.GetEnvironmentVariable("BlobStorageConnectionString")
                               ?? throw new InvalidOperationException("BlobStorageConnectionString not configured");
        var containerName = Environment.GetEnvironmentVariable("BlobContainerName")
                            ?? "uploaded-images";

        maxFileSizeBytes = int.TryParse(Environment.GetEnvironmentVariable("MaxFileSizeBytes"), out var size)
            ? size
            : 8_388_608; // Default 8MB

        var blobServiceClient = new BlobServiceClient(connectionString);
        containerClient = blobServiceClient.GetBlobContainerClient(containerName);
    }

    public async Task InitializeAsync()
    {
        await containerClient.CreateIfNotExistsAsync();
        logger.LogInformation("Blob container initialized: {ContainerName}", containerClient.Name);
    }

    public async Task<bool> UploadImageAsync(ImageMetadata metadata, byte[] imageData)
    {
        try
        {
            // Validate file size
            if (imageData.Length > maxFileSizeBytes)
            {
                logger.LogWarning("Image too large: {Size} bytes (max: {Max})",
                    imageData.Length, maxFileSizeBytes);
                return false;
            }

            var blobName = metadata.GetBlobName();
            var blobClient = containerClient.GetBlobClient(blobName);

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

            logger.LogInformation("Uploaded image: {BlobName} ({Size} bytes)", blobName, imageData.Length);
            return true;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to upload image for device {DeviceId}", metadata.DeviceId);
            return false;
        }
    }

    public async Task<ImageMetadata?> GetImageMetadataAsync(string deviceId, string imageType)
    {
        try
        {
            foreach (var format in new[] { "png", "jpeg" })
            {
                var blobName = $"{deviceId}_{imageType}.{format}";
                var blobClient = containerClient.GetBlobClient(blobName);

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


            return null;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to get image metadata for device {DeviceId}", deviceId);
            return null;
        }
    }

    public async Task<byte[]?> DownloadImageAsync(string deviceId, string imageType)
    {
        try
        {
            var metadata = await GetImageMetadataAsync(deviceId, imageType);
            if (metadata == null)
                return null;

            var blobName = metadata.GetBlobName();
            var blobClient = containerClient.GetBlobClient(blobName);

            using var memoryStream = new MemoryStream();
            await blobClient.DownloadToAsync(memoryStream);

            logger.LogInformation("Downloaded image: {BlobName} ({Size} bytes)",
                blobName, memoryStream.Length);

            return memoryStream.ToArray();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to download image for device {DeviceId}", deviceId);
            return null;
        }
    }

    public async Task<bool> DeleteImageAsync(string deviceId, string imageType)
    {
        try
        {
            var metadata = await GetImageMetadataAsync(deviceId, imageType);
            if (metadata == null)
                return false;

            var blobName = metadata.GetBlobName();
            var blobClient = containerClient.GetBlobClient(blobName);

            await blobClient.DeleteIfExistsAsync();

            logger.LogInformation("Deleted image: {BlobName}", blobName);
            return true;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to delete image for device {DeviceId}", deviceId);
            return false;
        }
    }

    public async Task CleanupExpiredImagesAsync(TimeSpan maxAge)
    {
        try
        {
            var cutoffTime = DateTime.UtcNow - maxAge;
            var deletedCount = 0;

            await foreach (var blobItem in containerClient.GetBlobsAsync(BlobTraits.Metadata))
            {
                if (blobItem.Properties.CreatedOn < cutoffTime)
                {
                    var blobClient = containerClient.GetBlobClient(blobItem.Name);
                    await blobClient.DeleteIfExistsAsync();
                    deletedCount++;
                }
            }

            if (deletedCount > 0)
            {
                logger.LogInformation("Cleaned up {Count} expired images", deletedCount);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to cleanup expired images");
        }
    }
}