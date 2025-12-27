using System.Net;
using System.Text.Json;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

public class CheckFunction
{
    private readonly BlobStorageService blobStorage;
    private readonly RateLimitService rateLimit;
    private readonly ILogger<CheckFunction> logger;

    public CheckFunction(
        BlobStorageService blobStorage,
        RateLimitService rateLimit,
        ILogger<CheckFunction> logger)
    {
        this.blobStorage = blobStorage;
        this.rateLimit = rateLimit;
        this.logger = logger;
    }

    [Function("Check")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "check/{deviceId}/{imageType}")]
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

            // Check rate limit (more lenient for check operations)
            if (!rateLimit.IsAllowed(clientIp, "check"))
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

            // Check if image exists
            var metadata = await blobStorage.GetImageMetadataAsync(deviceId.ToLowerInvariant(), imageType);

            var checkResponse = new ImageCheckResponse
            {
                Available = metadata != null,
                ImageType = metadata?.ImageType,
                Format = metadata?.Format
            };

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            var json = JsonSerializer.Serialize(checkResponse, JsonSerializerOptionsDefaults.CamelCase);
            await response.WriteStringAsync(json);

            return response;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error checking image for device {DeviceId}", deviceId);
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteStringAsync("An error occurred");
            return errorResponse;
        }
    }
}