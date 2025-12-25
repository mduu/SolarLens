using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Services;

public class RateLimitService
{
    private readonly IMemoryCache _cache;
    private readonly ILogger<RateLimitService> _logger;
    private readonly int _requestsPerMinute;

    public RateLimitService(IMemoryCache cache, ILogger<RateLimitService> logger)
    {
        _cache = cache;
        _logger = logger;

        _requestsPerMinute = int.TryParse(
            Environment.GetEnvironmentVariable("RateLimitRequestsPerMinute"),
            out var limit) ? limit : 10;
    }

    public bool IsAllowed(string identifier, string operation)
    {
        var key = $"ratelimit_{operation}_{identifier}";

        if (!_cache.TryGetValue(key, out int requestCount))
        {
            requestCount = 0;
        }

        if (requestCount >= _requestsPerMinute)
        {
            _logger.LogWarning("Rate limit exceeded for {Identifier} on {Operation}: {Count}/{Max}",
                identifier, operation, requestCount, _requestsPerMinute);
            return false;
        }

        // Increment counter with sliding expiration
        _cache.Set(key, requestCount + 1, TimeSpan.FromMinutes(1));

        return true;
    }

    public void RecordRequest(string identifier, string operation)
    {
        var key = $"ratelimit_{operation}_{identifier}";

        if (!_cache.TryGetValue(key, out int requestCount))
        {
            requestCount = 0;
        }

        _cache.Set(key, requestCount + 1, TimeSpan.FromMinutes(1));
    }

    public int GetRemainingRequests(string identifier, string operation)
    {
        var key = $"ratelimit_{operation}_{identifier}";

        if (!_cache.TryGetValue(key, out int requestCount))
        {
            return _requestsPerMinute;
        }

        return Math.Max(0, _requestsPerMinute - requestCount);
    }
}
