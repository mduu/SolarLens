using System.Text.Json;
using Azure.Storage.Queues;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

/// <summary>
/// The alarm clock (story #9): once a minute, hand every due schedule to the
/// push queue. Deliberately dumb — it never looks at what an automation does,
/// only at timestamps.
/// </summary>
public class WakeSchedulerFunction
{
    private readonly WakeScheduleService schedules;
    private readonly QueueClient queue;
    private readonly QueueClient poisonQueue;
    private readonly ILogger<WakeSchedulerFunction> logger;

    public WakeSchedulerFunction(
        WakeScheduleService schedules,
        ApnsQueueProvider queueProvider,
        ILogger<WakeSchedulerFunction> logger)
    {
        this.schedules = schedules;
        this.queue = queueProvider.Queue;
        this.poisonQueue = queueProvider.PoisonQueue;
        this.logger = logger;
    }

    [Function("WakeScheduler")]
    public async Task Run([TimerTrigger("0 * * * * *")] TimerInfo timer)
    {
        var now = DateTimeOffset.UtcNow;
        var due = await schedules.GetDueAsync(now);

        if (due.Count > 0)
        {
            logger.LogInformation("Wake scheduler: {Count} schedules due", due.Count);
        }

        foreach (var entity in due)
        {
            var message = new ApnsPushMessage
            {
                DeviceToken = entity.PartitionKey,
                Environment = entity.Environment,
                ScheduleId = entity.RowKey,
                PushKind = entity.PushKind,
                Automation = entity.Automation,
                Category = entity.Category,
                DeepLink = entity.DeepLink,
                Title = entity.DefaultTitle,
                Body = entity.DefaultBody,
                FireAt = entity.NextFireAt ?? now,
                Attempt = 0
            };

            try
            {
                await queue.SendMessageAsync(JsonSerializer.Serialize(message));
                // Park (deadline) or roll forward (window) only after the
                // message is safely queued, so a failure here means we retry
                // next minute rather than losing the push.
                await schedules.AdvanceAsync(entity, now);
            }
            catch (Exception ex)
            {
                logger.LogError(ex,
                    "Failed to enqueue push for device {Device}",
                    WakeScheduleService.Redact(entity.PartitionKey));
            }
        }

        // Once a day (first run after midnight UTC): housekeeping and a health
        // signal for the poison queue, which is the only place unexpected
        // failures accumulate.
        if (now.Hour == 0 && now.Minute == 0)
        {
            var removed = await schedules.CleanupExpiredAsync(now);
            if (removed > 0)
                logger.LogInformation(
                    "Wake scheduler: cleaned up {Count} expired schedules", removed);

            await LogPoisonQueueDepthAsync();
        }
    }

    /// <summary>
    /// The poison queue is a diagnostic inbox, not a replay source: whatever
    /// lands there is stale by the time anyone looks. So we never drain it —
    /// we only make sure it cannot rot unnoticed. Alert on this warning.
    /// </summary>
    private async Task LogPoisonQueueDepthAsync()
    {
        try
        {
            if (!await poisonQueue.ExistsAsync()) return;
            var properties = await poisonQueue.GetPropertiesAsync();
            var depth = properties.Value.ApproximateMessagesCount;
            if (depth > 0)
            {
                logger.LogWarning(
                    "APNs poison queue holds {Count} messages — pushes are failing unexpectedly (bad .p8 key, wrong topic, payload bug). Inspect in the Azure Portal storage browser, fix the cause, then purge; the messages themselves are too stale to replay.",
                    depth);
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Could not read poison queue depth");
        }
    }
}
