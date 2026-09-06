using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ImageUpload.Functions.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<BlobStorageService>();
        // Wake scheduler / APNs pipeline (story #9). The HTTP/2 connection to
        // APNs is reused across invocations and its handler is never recycled
        // underneath us.
        //
        // ApnsClient is registered explicitly as a singleton. `AddHttpClient<T>`
        // would register the typed client as *transient*, so each push built a
        // fresh ApnsClient with a fresh, empty provider-token cache and signed
        // a new JWT. Apple rejects more than one provider token per 20 minutes
        // with 429 TooManyProviderTokenUpdates, and a 429 is retried — which
        // mints another token. One device never hit it; a dozen always would.
        services.AddHttpClient(ApnsClient.HttpClientName, client =>
            {
                client.DefaultRequestVersion = System.Net.HttpVersion.Version20;
                client.DefaultVersionPolicy =
                    System.Net.Http.HttpVersionPolicy.RequestVersionOrHigher;
                client.Timeout = TimeSpan.FromSeconds(15);
            })
            .SetHandlerLifetime(Timeout.InfiniteTimeSpan);
        services.AddSingleton<ApnsClient>(sp => new ApnsClient(
            sp.GetRequiredService<IHttpClientFactory>()
                .CreateClient(ApnsClient.HttpClientName),
            sp.GetRequiredService<ILogger<ApnsClient>>()));
        services.AddSingleton<WakeScheduleService>();
        services.AddSingleton<ApnsQueueProvider>();
        services.AddSingleton<RateLimitService>();
        services.AddMemoryCache();
    })
    .Build();

host.Run();
