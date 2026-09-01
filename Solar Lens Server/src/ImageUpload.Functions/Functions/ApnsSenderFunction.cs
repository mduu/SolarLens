using System.Text.Json;
using Azure.Storage.Queues;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

/// <summary>
/// Sends one push per queue message (story #9).
///
/// Error handling has exactly three classes, and only the last one reaches the
/// poison queue:
///
/// <list type="bullet">
/// <item><b>Invalid device</b> — nothing can ever be delivered to that token:
/// delete the device's schedules and complete the message.</item>
/// <item><b>Transient</b> — re-queue ourselves with a delay until the push is
/// too stale to be useful, then drop it with a warning. The runtime's own
/// retries fire within seconds and would be useless during a multi-minute
/// APNs blip.</item>
/// <item><b>Unexpected</b> — throw, so after <c>maxDequeueCount</c> the
/// runtime parks the message in <c>apns-push-poison</c> for a human.</item>
/// </list>
/// </summary>
public class ApnsSenderFunction
{
    /// <summary>How long a push stays worth retrying after its due time.</summary>
    private static readonly TimeSpan MaxRetryAge = TimeSpan.FromMinutes(10);

    private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(45);

    private readonly ApnsClient apns;
    private readonly WakeScheduleService schedules;
    private readonly QueueClient queue;
    private readonly ILogger<ApnsSenderFunction> logger;

    public ApnsSenderFunction(
        ApnsClient apns,
        WakeScheduleService schedules,
        ApnsQueueProvider queueProvider,
        ILogger<ApnsSenderFunction> logger)
    {
        this.apns = apns;
        this.schedules = schedules;
        this.queue = queueProvider.Queue;
        this.logger = logger;
    }

    [Function("ApnsSender")]
    public async Task Run(
        [QueueTrigger(ApnsQueueProvider.QueueName)] string body,
        CancellationToken cancellationToken)
    {
        var message = JsonSerializer.Deserialize<ApnsPushMessage>(body)
            ?? throw new InvalidOperationException(
                "Unreadable APNs queue message");

        // The queue message is the schedule: it becomes visible when the push
        // is due. The row is still the source of truth for whether it is
        // wanted and when.
        var schedule = await schedules.GetAsync(
            message.DeviceToken, message.ScheduleId);
        if (schedule is null)
        {
            logger.LogInformation(
                "Skipping push for cancelled schedule {ScheduleId}",
                message.ScheduleId);
            return;
        }

        // Re-registered since this message was queued: a newer message carries
        // the current time, so this one is stale.
        if (schedule.NextFireAt != message.FireAt)
        {
            logger.LogInformation(
                "Skipping superseded push for schedule {ScheduleId}",
                message.ScheduleId);
            return;
        }

        // Not due yet — either a wake-up further out than a message may stay
        // invisible, or clock skew. Re-queue for what is left.
        var now = DateTimeOffset.UtcNow;
        if (schedule.NextFireAt > now + WakeScheduleService.DueTolerance)
        {
            await schedules.EnqueueAsync(schedule, now);
            return;
        }

        var result = await apns.SendAsync(message, cancellationToken);

        switch (result.Kind)
        {
            case ApnsResultKind.Delivered:
                if (schedule.Kind == WakeKinds.Deadline)
                {
                    await schedules.CompleteDeadlineAsync(
                        message.DeviceToken, message.ScheduleId);
                }
                else
                {
                    // A window keeps itself going: queue its next occurrence,
                    // or let it end once it has passed `until`.
                    await schedules.AdvanceWindowAsync(schedule, now);
                }
                logger.LogInformation(
                    "Push delivered to {Device} ({PushKind})",
                    WakeScheduleService.Redact(message.DeviceToken),
                    message.PushKind);
                return;

            case ApnsResultKind.InvalidDevice:
                logger.LogInformation(
                    "APNs reports device {Device} as gone ({Reason}) — removing its schedules",
                    WakeScheduleService.Redact(message.DeviceToken),
                    result.Reason);
                await schedules.PurgeDeviceAsync(message.DeviceToken);
                return;

            case ApnsResultKind.Transient:
                await RetryLaterAsync(message, result);
                return;

            default:
                // Bad provider token, wrong topic, malformed payload: retrying
                // cannot fix it, so let it land in the poison queue where the
                // daily depth warning will surface it.
                throw new InvalidOperationException(
                    $"APNs rejected the push with {result.StatusCode} "
                    + $"({result.Reason ?? "no reason"}) for schedule "
                    + $"{message.ScheduleId}");
        }
    }

    private async Task RetryLaterAsync(
        ApnsPushMessage message, ApnsResult result)
    {
        var age = DateTimeOffset.UtcNow - message.FireAt;
        if (age > MaxRetryAge)
        {
            // A deadline push this late is worse than none — the device's own
            // fallback notification has already fired — and a silent wake is
            // superseded by the next window tick.
            logger.LogWarning(
                "Dropping push for schedule {ScheduleId} after {Minutes} min of APNs trouble ({Status} {Reason})",
                message.ScheduleId,
                (int)age.TotalMinutes,
                result.StatusCode,
                result.Reason);
            return;
        }

        message.Attempt++;
        await queue.SendMessageAsync(
            JsonSerializer.Serialize(message),
            visibilityTimeout: RetryDelay);
        logger.LogInformation(
            "APNs transient failure ({Status} {Reason}) — retrying schedule {ScheduleId} in {Delay}s (attempt {Attempt})",
            result.StatusCode, result.Reason, message.ScheduleId,
            (int)RetryDelay.TotalSeconds, message.Attempt);
    }
}
