using System.Net;
using System.Text.Json;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

public class UploadFunction
{
    private readonly BlobStorageService _blobStorage;
    private readonly RateLimitService _rateLimit;
    private readonly ILogger<UploadFunction> _logger;

    public UploadFunction(
        BlobStorageService blobStorage,
        RateLimitService rateLimit,
        ILogger<UploadFunction> logger)
    {
        _blobStorage = blobStorage;
        _rateLimit = rateLimit;
        _logger = logger;
    }

    [Function("Upload")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "upload")] HttpRequestData req)
    {
        try
        {
            // Get client IP for rate limiting
            var clientIp = req.Headers.TryGetValues("X-Forwarded-For", out var forwardedFor)
                ? forwardedFor.First().Split(',')[0]
                : "unknown";

            // Check rate limit
            if (!_rateLimit.IsAllowed(clientIp, "upload"))
            {
                _logger.LogWarning("Rate limit exceeded for IP: {IP}", clientIp);
                var rateLimitResponse = req.CreateResponse(HttpStatusCode.TooManyRequests);
                await rateLimitResponse.WriteStringAsync("Rate limit exceeded. Please try again later.");
                return rateLimitResponse;
            }

            // Parse request body
            var body = await new StreamReader(req.Body).ReadToEndAsync();
            var uploadRequest = JsonSerializer.Deserialize<ImageUploadRequest>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (uploadRequest == null)
            {
                var badRequestResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badRequestResponse.WriteStringAsync("Invalid request format");
                return badRequestResponse;
            }

            // Validate device ID format (UUID)
            if (!Guid.TryParse(uploadRequest.DeviceId, out _))
            {
                var invalidDeviceResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await invalidDeviceResponse.WriteStringAsync("Invalid device ID format. Must be a valid UUID.");
                return invalidDeviceResponse;
            }

            // Validate image type
            if (uploadRequest.ImageType != "logo" && uploadRequest.ImageType != "background")
            {
                var invalidTypeResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await invalidTypeResponse.WriteStringAsync("Invalid image type. Must be 'logo' or 'background'.");
                return invalidTypeResponse;
            }

            // Validate format
            if (uploadRequest.Format != "png" && uploadRequest.Format != "jpeg")
            {
                var invalidFormatResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await invalidFormatResponse.WriteStringAsync("Invalid format. Must be 'png' or 'jpeg'.");
                return invalidFormatResponse;
            }

            // Decode base64 image data
            byte[] imageData;
            try
            {
                imageData = Convert.FromBase64String(uploadRequest.ImageData);
            }
            catch (FormatException)
            {
                var invalidBase64Response = req.CreateResponse(HttpStatusCode.BadRequest);
                await invalidBase64Response.WriteStringAsync("Invalid base64 image data");
                return invalidBase64Response;
            }

            // Validate image data is not empty
            if (imageData.Length == 0)
            {
                var emptyImageResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await emptyImageResponse.WriteStringAsync("Image data is empty");
                return emptyImageResponse;
            }

            // Initialize blob storage if needed
            await _blobStorage.InitializeAsync();

            // Create metadata
            var metadata = new ImageMetadata
            {
                DeviceId = uploadRequest.DeviceId.ToLowerInvariant(),
                ImageType = uploadRequest.ImageType,
                Format = uploadRequest.Format,
                SizeBytes = imageData.Length,
                UploadedAt = DateTime.UtcNow,
                DownloadCount = 0
            };

            // Upload to blob storage
            var uploaded = await _blobStorage.UploadImageAsync(metadata, imageData);

            if (!uploaded)
            {
                var uploadFailedResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await uploadFailedResponse.WriteStringAsync("Failed to upload image. Image may be too large.");
                return uploadFailedResponse;
            }

            _logger.LogInformation("Image uploaded successfully for device {DeviceId}: {Type}",
                uploadRequest.DeviceId, uploadRequest.ImageType);

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(new
            {
                success = true,
                message = "Image uploaded successfully",
                deviceId = uploadRequest.DeviceId,
                imageType = uploadRequest.ImageType
            });

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing upload request");
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteStringAsync("An error occurred while processing your request");
            return errorResponse;
        }
    }
}
