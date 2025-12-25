using System.Net;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

public class CheckFunction
{
    private readonly BlobStorageService _blobStorage;
    private readonly RateLimitService _rateLimit;
    private readonly ILogger<CheckFunction> _logger;

    public CheckFunction(
        BlobStorageService blobStorage,
        RateLimitService rateLimit,
        ILogger<CheckFunction> logger)
    {
        _blobStorage = blobStorage;
        _rateLimit = rateLimit;
        _logger = logger;
    }

    [Function("Check")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "check/{deviceId}")] HttpRequestData req,
        string deviceId)
    {
        try
        {
            // Get client IP for rate limiting
            var clientIp = req.Headers.TryGetValues("X-Forwarded-For", out var forwardedFor)
                ? forwardedFor.First().Split(',')[0]
                : "unknown";

            // Check rate limit (more lenient for check operations)
            if (!_rateLimit.IsAllowed(clientIp, "check"))
            {
                _logger.LogWarning("Rate limit exceeded for IP: {IP}", clientIp);
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

            // Initialize blob storage if needed
            await _blobStorage.InitializeAsync();

            // Check if image exists
            var metadata = await _blobStorage.GetImageMetadataAsync(deviceId.ToLowerInvariant());

            var checkResponse = new ImageCheckResponse
            {
                Available = metadata != null,
                ImageType = metadata?.ImageType,
                Format = metadata?.Format
            };

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(checkResponse);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking image for device {DeviceId}", deviceId);
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteStringAsync("An error occurred");
            return errorResponse;
        }
    }
}
