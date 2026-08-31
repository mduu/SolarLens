using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using ImageUpload.Functions.Models;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Services;

/// <summary>What APNs told us about one push. Drives retry vs. cleanup vs. poison.</summary>
public enum ApnsResultKind
{
    /// <summary>Accepted by APNs (HTTP 200).</summary>
    Delivered,

    /// <summary>The token is dead (410 Unregistered / 400 BadDeviceToken).
    /// Nothing will ever be delivered to it — delete the device's schedules.</summary>
    InvalidDevice,

    /// <summary>APNs is busy or unreachable (429/5xx/network). Worth retrying.</summary>
    Transient,

    /// <summary>Our own fault: bad key, wrong topic, malformed payload.
    /// Retrying cannot help; a human has to look.</summary>
    Fatal
}

public record ApnsResult(ApnsResultKind Kind, int StatusCode, string? Reason);

/// <summary>
/// Minimal APNs provider client (story #9). Apple ships no server SDK — the
/// provider API is plain HTTP/2 with a JWT — so this is deliberately hand
/// written instead of taking a dependency for two request shapes.
/// </summary>
public class ApnsClient
{
    private const string ProductionHost = "https://api.push.apple.com";
    private const string SandboxHost = "https://api.sandbox.push.apple.com";

    /// <summary>
    /// Apple requires a provider token to be reused for 20–60 minutes; minting
    /// one per request gets us throttled. Cached per worker process — a cold
    /// start or a scale-out simply mints a new one, which is exactly the
    /// intended pattern.
    /// </summary>
    private static readonly TimeSpan TokenLifetime = TimeSpan.FromMinutes(50);

    private readonly HttpClient http;
    private readonly ILogger<ApnsClient> logger;
    private readonly string teamId;
    private readonly string keyId;
    private readonly string bundleId;
    private readonly ECDsa signingKey;
    private readonly Lock gate = new();

    private string? cachedToken;
    private DateTimeOffset cachedTokenIssuedAt;

    public ApnsClient(HttpClient http, ILogger<ApnsClient> logger)
    {
        this.http = http;
        this.logger = logger;

        teamId = Require("Apns__TeamId");
        keyId = Require("Apns__KeyId");
        bundleId = Require("Apns__BundleId");
        var p8 = Require("Apns__P8");

        signingKey = ECDsa.Create();
        signingKey.ImportPkcs8PrivateKey(DecodeP8(p8), out _);
    }

    private static string Require(string name) =>
        Environment.GetEnvironmentVariable(name)
        ?? Environment.GetEnvironmentVariable(name.Replace("__", ":"))
        ?? throw new InvalidOperationException($"{name} is not configured");

    /// <summary>
    /// Accepts the .p8 either as raw PEM (with header/footer) or as base64 of
    /// the file's contents — both shapes turn up depending on how the secret
    /// was pasted into the Function App settings.
    /// </summary>
    private static byte[] DecodeP8(string value)
    {
        var text = value.Trim();
        if (!text.Contains("BEGIN PRIVATE KEY"))
        {
            try
            {
                text = Encoding.UTF8.GetString(Convert.FromBase64String(text));
            }
            catch (FormatException)
            {
                // Not base64 — assume it is already the key body.
            }
        }

        var body = text
            .Replace("-----BEGIN PRIVATE KEY-----", string.Empty)
            .Replace("-----END PRIVATE KEY-----", string.Empty)
            .Replace("\r", string.Empty)
            .Replace("\n", string.Empty)
            .Trim();
        return Convert.FromBase64String(body);
    }

    private string GetProviderToken()
    {
        lock (gate)
        {
            var now = DateTimeOffset.UtcNow;
            if (cachedToken is not null
                && now - cachedTokenIssuedAt < TokenLifetime)
            {
                return cachedToken;
            }

            cachedTokenIssuedAt = now;
            cachedToken = CreateProviderToken(now);
            return cachedToken;
        }
    }

    /// <summary>
    /// Apple rejects providers that mint tokens too often
    /// (<c>TooManyProviderTokenUpdates</c>), so a token may only be replaced
    /// once it is old enough — even when APNs just rejected it.
    /// </summary>
    private static readonly TimeSpan MinTokenAge = TimeSpan.FromMinutes(20);

    /// <summary>
    /// Discards the cached JWT so the next send mints a fresh one — but only
    /// if the current one is old enough to be replaced. Returns false when
    /// re-minting would get us rate limited, in which case the caller must
    /// treat the rejection as fatal rather than retrying.
    /// </summary>
    private bool TryInvalidateProviderToken()
    {
        lock (gate)
        {
            if (cachedToken is null) return false;
            if (DateTimeOffset.UtcNow - cachedTokenIssuedAt < MinTokenAge)
            {
                return false;
            }
            cachedToken = null;
            return true;
        }
    }

    private string CreateProviderToken(DateTimeOffset issuedAt)
    {
        var header = Base64Url(JsonSerializer.SerializeToUtf8Bytes(
            new Dictionary<string, string>
            {
                ["alg"] = "ES256",
                ["kid"] = keyId
            }));
        var payload = Base64Url(JsonSerializer.SerializeToUtf8Bytes(
            new Dictionary<string, object>
            {
                ["iss"] = teamId,
                ["iat"] = issuedAt.ToUnixTimeSeconds()
            }));

        var signingInput = Encoding.UTF8.GetBytes($"{header}.{payload}");
        // JWS wants the raw r‖s concatenation, not the DER sequence
        // ECDsa.SignData produces by default.
        var signature = signingKey.SignData(
            signingInput,
            HashAlgorithmName.SHA256,
            DSASignatureFormat.IeeeP1363FixedFieldConcatenation);

        return $"{header}.{payload}.{Base64Url(signature)}";
    }

    private static string Base64Url(byte[] value) =>
        Convert.ToBase64String(value)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');

    public async Task<ApnsResult> SendAsync(
        ApnsPushMessage message,
        CancellationToken cancellationToken = default)
    {
        var result = await SendOnceAsync(message, cancellationToken);

        // An expired or rejected provider token is the one "fatal" case worth
        // one automatic retry: the JWT may simply have aged out between mint
        // and send.
        if (result is { Kind: ApnsResultKind.Fatal, StatusCode: 403 })
        {
            if (TryInvalidateProviderToken())
            {
                logger.LogWarning(
                    "APNs rejected the provider token ({Reason}) — minting a new one and retrying once",
                    result.Reason);
                result = await SendOnceAsync(message, cancellationToken);
            }
            else
            {
                // The token is fresh and APNs still rejects it: the .p8 key,
                // key id or team id is wrong. Re-minting would only earn us a
                // TooManyProviderTokenUpdates throttle.
                logger.LogError(
                    "APNs rejected a freshly minted provider token ({Reason}) — check Apns__KeyId / Apns__TeamId / Apns__P8",
                    result.Reason);
            }
        }

        return result;
    }

    private async Task<ApnsResult> SendOnceAsync(
        ApnsPushMessage message,
        CancellationToken cancellationToken)
    {
        var host = message.Environment == WakeEnvironments.Sandbox
            ? SandboxHost
            : ProductionHost;
        var isAlert = message.PushKind == WakePushKinds.Alert;

        using var request = new HttpRequestMessage(
            HttpMethod.Post, $"{host}/3/device/{message.DeviceToken}")
        {
            // APNs speaks HTTP/2 only; without this .NET may negotiate 1.1
            // and the request is rejected outright.
            Version = HttpVersion.Version20,
            VersionPolicy = HttpVersionPolicy.RequestVersionOrHigher,
            Content = new StringContent(
                BuildPayload(message, isAlert),
                Encoding.UTF8,
                "application/json")
        };

        request.Headers.TryAddWithoutValidation(
            "authorization", $"bearer {GetProviderToken()}");
        request.Headers.TryAddWithoutValidation("apns-topic", bundleId);
        request.Headers.TryAddWithoutValidation(
            "apns-push-type", isAlert ? "alert" : "background");
        request.Headers.TryAddWithoutValidation(
            "apns-priority", isAlert ? "10" : "5");
        request.Headers.TryAddWithoutValidation(
            "apns-collapse-id", message.ScheduleId);
        // A deadline push that arrives late is worse than none: the device's
        // own fallback notification has fired by then.
        request.Headers.TryAddWithoutValidation(
            "apns-expiration",
            message.FireAt.AddMinutes(10).ToUnixTimeSeconds().ToString());

        try
        {
            using var response = await http.SendAsync(request, cancellationToken);
            if (response.IsSuccessStatusCode)
                return new ApnsResult(ApnsResultKind.Delivered, 200, null);

            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            var reason = ExtractReason(body);
            var status = (int)response.StatusCode;

            var kind = status switch
            {
                410 => ApnsResultKind.InvalidDevice,
                400 when reason is "BadDeviceToken" or "DeviceTokenNotForTopic"
                    => ApnsResultKind.InvalidDevice,
                429 => ApnsResultKind.Transient,
                >= 500 => ApnsResultKind.Transient,
                _ => ApnsResultKind.Fatal
            };

            return new ApnsResult(kind, status, reason);
        }
        catch (Exception ex) when (
            ex is HttpRequestException or TaskCanceledException)
        {
            logger.LogWarning(
                "APNs request failed for device {Device}: {Message}",
                WakeScheduleService.Redact(message.DeviceToken), ex.Message);
            return new ApnsResult(ApnsResultKind.Transient, 0, ex.GetType().Name);
        }
    }

    private static string? ExtractReason(string body)
    {
        if (string.IsNullOrWhiteSpace(body)) return null;
        try
        {
            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.TryGetProperty("reason", out var reason)
                ? reason.GetString()
                : null;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static string BuildPayload(ApnsPushMessage message, bool isAlert)
    {
        var solarLens = new Dictionary<string, object?>
        {
            ["kind"] = isAlert ? "automation-deadline" : "wake",
            ["scheduleId"] = message.ScheduleId
        };
        if (message.Automation is not null)
            solarLens["automation"] = message.Automation;

        var payload = new Dictionary<string, object?>
        {
            ["solarlens"] = solarLens
        };

        if (isAlert)
        {
            var aps = new Dictionary<string, object?>
            {
                ["alert"] = new Dictionary<string, object?>
                {
                    ["title"] = message.Title ?? "Solar Lens",
                    ["body"] = message.Body
                        ?? "Scheduled automation is running…"
                },
                // Wakes the Notification Service Extension, which replaces this
                // text with what actually happened.
                ["mutable-content"] = 1,
                ["sound"] = "default",
                ["interruption-level"] = "time-sensitive"
            };
            if (message.Category is not null) aps["category"] = message.Category;
            payload["aps"] = aps;
            if (message.DeepLink is not null)
                payload["deepLink"] = message.DeepLink;
        }
        else
        {
            payload["aps"] = new Dictionary<string, object?>
            {
                ["content-available"] = 1
            };
        }

        return JsonSerializer.Serialize(payload);
    }
}
