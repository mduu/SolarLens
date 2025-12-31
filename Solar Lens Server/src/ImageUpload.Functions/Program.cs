using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using ImageUpload.Functions.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<BlobStorageService>();
        services.AddSingleton<RateLimitService>();
        services.AddMemoryCache();
    })
    .Build();

host.Run();
