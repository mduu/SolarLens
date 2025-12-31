using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Services;

public class RateLimitService
{
    private readonly IMemoryCache cache;
    private readonly ILogger<RateLimitService> logger;
    private readonly int requestsPerMinute;

    public RateLimitService(IMemoryCache cache, ILogger<RateLimitService> logger)
    {
        this.cache = cache;
        this.logger = logger;

        requestsPerMinute = int.TryParse(
            Environment.GetEnvironmentVariable("RateLimitRequestsPerMinute"),
            out var limit) ? limit : 10;
    }

    public bool IsAllowed(string identifier, string operation)
    {
        var key = $"ratelimit_{operation}_{identifier}";

        if (!cache.TryGetValue(key, out int requestCount))
        {
            requestCount = 0;
        }

        if (requestCount >= requestsPerMinute)
        {
            logger.LogWarning("Rate limit exceeded for {Identifier} on {Operation}: {Count}/{Max}",
                identifier, operation, requestCount, requestsPerMinute);
            return false;
        }

        // Increment counter with sliding expiration
        cache.Set(key, requestCount + 1, TimeSpan.FromMinutes(1));

        return true;
    }

    public void RecordRequest(string identifier, string operation)
    {
        var key = $"ratelimit_{operation}_{identifier}";

        if (!cache.TryGetValue(key, out int requestCount))
        {
            requestCount = 0;
        }

        cache.Set(key, requestCount + 1, TimeSpan.FromMinutes(1));
    }

    public int GetRemainingRequests(string identifier, string operation)
    {
        var key = $"ratelimit_{operation}_{identifier}";

        if (!cache.TryGetValue(key, out int requestCount))
        {
            return requestsPerMinute;
        }

        return Math.Max(0, requestsPerMinute - requestCount);
    }
}
