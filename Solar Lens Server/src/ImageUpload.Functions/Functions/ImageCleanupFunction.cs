using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

/// <summary>
/// Deletes uploaded images that were never fetched.
///
/// The normal path deletes an image the moment the Apple TV downloads it
/// (<see cref="DownloadFunction"/>), so this only ever catches uploads whose
/// TV never came to collect them — a cancelled setup, a wrong QR code, a
/// device that went offline in between.
///
/// That matters beyond tidiness: an image is someone's picture, and keeping it
/// only as long as it takes to service the transfer is what makes this a
/// transfer rather than data collection.
/// </summary>
public class ImageCleanupFunction
{
    /// <summary>
    /// How long an unfetched image may wait for its TV. Generous enough to
    /// survive "upload now, switch on the TV tonight", short enough that
    /// nothing lingers.
    /// </summary>
    private static readonly TimeSpan MaxAge = TimeSpan.FromHours(24);

    private readonly BlobStorageService blobStorage;
    private readonly ILogger<ImageCleanupFunction> logger;

    public ImageCleanupFunction(
        BlobStorageService blobStorage,
        ILogger<ImageCleanupFunction> logger)
    {
        this.blobStorage = blobStorage;
        this.logger = logger;
    }

    [Function("ImageCleanup")]
    public async Task Run([TimerTrigger("0 0 3 * * *")] TimerInfo timer)
    {
        logger.LogInformation(
            "Cleaning up images older than {Hours} h", MaxAge.TotalHours);
        await blobStorage.CleanupExpiredImagesAsync(MaxAge);
    }
}
