using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using ImageUpload.Functions.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<BlobStorageService>();
        // Wake scheduler / APNs pipeline (story #9). The HttpClient is a
        // singleton so the HTTP/2 connection to APNs is reused across
        // invocations, and its handler is never recycled underneath us.
        services.AddHttpClient<ApnsClient>(client =>
            {
                client.DefaultRequestVersion = System.Net.HttpVersion.Version20;
                client.DefaultVersionPolicy =
                    System.Net.Http.HttpVersionPolicy.RequestVersionOrHigher;
                client.Timeout = TimeSpan.FromSeconds(15);
            })
            .SetHandlerLifetime(Timeout.InfiniteTimeSpan);
        services.AddSingleton<WakeScheduleService>();
        services.AddSingleton<ApnsQueueProvider>();
        services.AddSingleton<RateLimitService>();
        services.AddMemoryCache();
    })
    .Build();

host.Run();
