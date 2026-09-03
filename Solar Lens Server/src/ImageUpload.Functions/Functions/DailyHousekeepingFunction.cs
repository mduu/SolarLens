using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

/// <summary>
/// Once-a-day housekeeping: deletes uploaded images that were never fetched,
/// and any wake schedule that outlived its window.
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
public class DailyHousekeepingFunction
{
    /// <summary>
    /// How long an unfetched image may wait for its TV. Generous enough to
    /// survive "upload now, switch on the TV tonight", short enough that
    /// nothing lingers.
    /// </summary>
    private static readonly TimeSpan MaxAge = TimeSpan.FromHours(24);

    private readonly BlobStorageService blobStorage;
    private readonly WakeScheduleService schedules;
    private readonly ILogger<DailyHousekeepingFunction> logger;

    public DailyHousekeepingFunction(
        BlobStorageService blobStorage,
        WakeScheduleService schedules,
        ILogger<DailyHousekeepingFunction> logger)
    {
        this.blobStorage = blobStorage;
        this.schedules = schedules;
        this.logger = logger;
    }

    [Function("DailyHousekeeping")]
    public async Task Run([TimerTrigger("0 0 3 * * *")] TimerInfo timer)
    {
        logger.LogInformation(
            "Cleaning up images older than {Hours} h", MaxAge.TotalHours);
        await blobStorage.CleanupExpiredImagesAsync(MaxAge);

        // Defensive: a wake schedule normally removes itself when it fires or
        // when the device cancels it. This catches rows that outlived their
        // window anyway.
        await schedules.RepairOverdueAsync(DateTimeOffset.UtcNow);
        var removed = await schedules.CleanupExpiredAsync(DateTimeOffset.UtcNow);
        if (removed > 0)
        {
            logger.LogInformation(
                "Removed {Count} expired wake schedules", removed);
        }
    }
}
