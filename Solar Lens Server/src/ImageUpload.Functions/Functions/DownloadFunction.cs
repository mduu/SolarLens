using System.Net;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

public class DownloadFunction
{
    private readonly BlobStorageService blobStorage;
    private readonly RateLimitService rateLimit;
    private readonly ILogger<DownloadFunction> logger;

    public DownloadFunction(
        BlobStorageService blobStorage,
        RateLimitService rateLimit,
        ILogger<DownloadFunction> logger)
    {
        this.blobStorage = blobStorage;
        this.rateLimit = rateLimit;
        this.logger = logger;
    }

    [Function("Download")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "download/{deviceId}/{imageType}")]
        HttpRequestData req,
        string deviceId,
        string imageType)
    {
        try
        {
            // Get client IP for rate limiting
            var clientIp = req.Headers.TryGetValues("X-Forwarded-For", out var forwardedFor)
                ? forwardedFor.First().Split(',')[0]
                : "unknown";

            // Check rate limit
            if (!rateLimit.IsAllowed(clientIp, "download"))
            {
                logger.LogWarning("Rate limit exceeded for IP: {IP}", clientIp);
                var rateLimitResponse = req.CreateResponse(HttpStatusCode.TooManyRequests);
                await rateLimitResponse.WriteStringAsync("Rate limit exceeded");
                return rateLimitResponse;
            }

            // Validate device ID format
            if (!Guid.TryParse(deviceId, out _))
            {
                var invalidResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await invalidResponse.WriteStringAsync("Invalid device ID format");
                return invalidResponse;
            }

            // Validate imageType
            if (imageType != "logo" && imageType != "background")
            {
                var invalidResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await invalidResponse.WriteStringAsync("Invalid imageType. Must be either 'logo' or 'background'");
                return invalidResponse;
            }

            // Initialize blob storage if needed
            await blobStorage.InitializeAsync();

            // Get image metadata first
            var metadata = await blobStorage.GetImageMetadataAsync(deviceId.ToLowerInvariant(), imageType);

            if (metadata == null)
            {
                var notFoundResponse = req.CreateResponse(HttpStatusCode.NotFound);
                await notFoundResponse.WriteStringAsync("No image found for this device");
                return notFoundResponse;
            }

            // Download the image
            var imageData = await blobStorage.DownloadImageAsync(deviceId.ToLowerInvariant(), imageType);

            if (imageData == null)
            {
                var downloadFailedResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await downloadFailedResponse.WriteStringAsync("Failed to download image");
                return downloadFailedResponse;
            }

            // Delete the image after successful download (one-time use)
            _ = Task.Run(async () =>
            {
                await Task.Delay(TimeSpan.FromSeconds(5)); // Small delay to ensure download completes
                await blobStorage.DeleteImageAsync(deviceId.ToLowerInvariant(), imageType);
                logger.LogInformation("Auto-deleted image after download for device {DeviceId}", deviceId);
            });

            logger.LogInformation("Image downloaded for device {DeviceId}: {Type}",
                deviceId, metadata.ImageType);

            // Return the image with appropriate content type
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", metadata.Format == "png" ? "image/png" : "image/jpeg");
            response.Headers.Add("Content-Disposition", $"attachment; filename=\"{metadata.GetBlobName()}\"");
            await response.Body.WriteAsync(imageData);

            return response;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error downloading image for device {DeviceId}", deviceId);
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteStringAsync("An error occurred");
            return errorResponse;
        }
    }
}