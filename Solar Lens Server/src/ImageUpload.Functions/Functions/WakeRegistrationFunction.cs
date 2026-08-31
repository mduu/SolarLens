using System.Net;
using System.Text.Json;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

/// <summary>
/// Registration API for wake schedules (story #9). The device tells us *when*
/// to wake it and nothing else; see <see cref="WakeScheduleEntity"/>.
/// </summary>
public class WakeRegistrationFunction
{
    private readonly WakeScheduleService schedules;
    private readonly RateLimitService rateLimit;
    private readonly ILogger<WakeRegistrationFunction> logger;

    public WakeRegistrationFunction(
        WakeScheduleService schedules,
        RateLimitService rateLimit,
        ILogger<WakeRegistrationFunction> logger)
    {
        this.schedules = schedules;
        this.rateLimit = rateLimit;
        this.logger = logger;
    }

    [Function("WakeUpsert")]
    public async Task<HttpResponseData> Upsert(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put",
            Route = "wake/{deviceToken}/{scheduleId}")]
        HttpRequestData req,
        string deviceToken,
        string scheduleId)
    {
        if (!Allowed(req)) return Status(req, HttpStatusCode.TooManyRequests, "Rate limit exceeded");
        if (!WakeScheduleService.IsValidDeviceToken(deviceToken))
            return Status(req, HttpStatusCode.BadRequest, "Invalid device token");
        if (string.IsNullOrWhiteSpace(scheduleId) || scheduleId.Length > 100)
            return Status(req, HttpStatusCode.BadRequest, "Invalid schedule id");

        WakeScheduleRequest? body;
        try
        {
            body = await JsonSerializer.DeserializeAsync<WakeScheduleRequest>(
                req.Body,
                new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
        }
        catch (JsonException)
        {
            return Status(req, HttpStatusCode.BadRequest, "Malformed JSON body");
        }

        if (body is null)
            return Status(req, HttpStatusCode.BadRequest, "Missing body");

        var (ok, error) = await schedules.UpsertAsync(
            deviceToken, scheduleId, body, DateTimeOffset.UtcNow);
        return ok
            ? Status(req, HttpStatusCode.NoContent, null)
            : Status(req, HttpStatusCode.BadRequest, error);
    }

    [Function("WakeDelete")]
    public async Task<HttpResponseData> Delete(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete",
            Route = "wake/{deviceToken}/{scheduleId}")]
        HttpRequestData req,
        string deviceToken,
        string scheduleId)
    {
        if (!Allowed(req)) return Status(req, HttpStatusCode.TooManyRequests, "Rate limit exceeded");
        if (!WakeScheduleService.IsValidDeviceToken(deviceToken))
            return Status(req, HttpStatusCode.BadRequest, "Invalid device token");

        var secret = Secret(req);
        var (ok, error) = await schedules.DeleteAsync(
            deviceToken, scheduleId, secret);
        return ok
            ? Status(req, HttpStatusCode.NoContent, null)
            : Status(req, HttpStatusCode.Forbidden, error);
    }

    /// <summary>Used by the Settings toggle and on logout: forget this device entirely.</summary>
    [Function("WakeDeleteAll")]
    public async Task<HttpResponseData> DeleteAll(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete",
            Route = "wake/{deviceToken}")]
        HttpRequestData req,
        string deviceToken)
    {
        if (!Allowed(req)) return Status(req, HttpStatusCode.TooManyRequests, "Rate limit exceeded");
        if (!WakeScheduleService.IsValidDeviceToken(deviceToken))
            return Status(req, HttpStatusCode.BadRequest, "Invalid device token");

        var (ok, error, deleted) = await schedules.DeleteAllForDeviceAsync(
            deviceToken, Secret(req));
        if (!ok) return Status(req, HttpStatusCode.Forbidden, error);

        logger.LogInformation(
            "Deleted {Count} schedules for device {Device}",
            deleted, WakeScheduleService.Redact(deviceToken));
        return Status(req, HttpStatusCode.NoContent, null);
    }

    /// <summary>Re-sync helper: what does the server think is scheduled for this device?</summary>
    [Function("WakeList")]
    public async Task<HttpResponseData> List(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get",
            Route = "wake/{deviceToken}")]
        HttpRequestData req,
        string deviceToken)
    {
        if (!Allowed(req)) return Status(req, HttpStatusCode.TooManyRequests, "Rate limit exceeded");
        if (!WakeScheduleService.IsValidDeviceToken(deviceToken))
            return Status(req, HttpStatusCode.BadRequest, "Invalid device token");

        var rows = await schedules.GetForDeviceAsync(deviceToken);
        var secret = Secret(req);
        if (rows.Count > 0)
        {
            if (secret is null)
                return Status(req, HttpStatusCode.Forbidden, "installSecret is required");
            var hash = WakeScheduleService.HashSecret(secret);
            if (!rows.Any(r => r.SecretHash == hash))
                return Status(req, HttpStatusCode.Forbidden, "installSecret does not match this device");
        }

        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(rows.Select(r => new
        {
            scheduleId = r.RowKey,
            kind = r.Kind,
            pushKind = r.PushKind,
            nextFireAt = r.NextFireAt,
            cadenceMinutes = r.CadenceMinutes,
            until = r.Until,
            automation = r.Automation
        }));
        return response;
    }

    // MARK: helpers

    private bool Allowed(HttpRequestData req)
    {
        var clientIp = req.Headers.TryGetValues("X-Forwarded-For", out var xff)
            ? xff.First().Split(',')[0]
            : "unknown";
        return rateLimit.IsAllowed(clientIp, "wake");
    }

    /// <summary>
    /// Per-install secret, generated on the device and kept in its Keychain.
    /// Without it, knowing a device token would be enough to cancel or spam
    /// someone else's schedules.
    /// </summary>
    private static string? Secret(HttpRequestData req)
    {
        if (req.Headers.TryGetValues("X-Install-Secret", out var values))
        {
            var value = values.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(value)) return value;
        }

        var query = System.Web.HttpUtility.ParseQueryString(
            req.Url.Query);
        var fromQuery = query["installSecret"];
        return string.IsNullOrWhiteSpace(fromQuery) ? null : fromQuery;
    }

    private static HttpResponseData Status(
        HttpRequestData req, HttpStatusCode code, string? message)
    {
        var response = req.CreateResponse(code);
        if (message is not null) response.WriteString(message);
        return response;
    }
}
