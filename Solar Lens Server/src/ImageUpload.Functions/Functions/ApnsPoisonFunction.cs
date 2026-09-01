using System.Text.Json;
using ImageUpload.Functions.Models;
using ImageUpload.Functions.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Functions;

/// <summary>
/// Reports pushes that failed in a way retrying could not fix.
///
/// Triggering on the poison queue rather than polling its depth means a broken
/// APNs key or a payload bug is on record within seconds instead of at the next
/// housekeeping run — which is the difference between noticing it and hearing
/// about it from a user.
///
/// The message is consumed on purpose: its diagnostic value is the log entry,
/// which is searchable and retained, whereas a message sitting in a queue has
/// to be found by someone who already suspects something.
/// </summary>
public class ApnsPoisonFunction
{
    private readonly ILogger<ApnsPoisonFunction> logger;

    public ApnsPoisonFunction(ILogger<ApnsPoisonFunction> logger)
    {
        this.logger = logger;
    }

    [Function("ApnsPoison")]
    public void Run(
        [QueueTrigger(ApnsQueueProvider.PoisonQueueName)] string body)
    {
        ApnsPushMessage? message = null;
        try
        {
            message = JsonSerializer.Deserialize<ApnsPushMessage>(body);
        }
        catch (JsonException)
        {
            // Fall through: an unreadable message is itself worth reporting.
        }

        logger.LogError(
            "A push could not be delivered and gave up: schedule {ScheduleId}, "
            + "device {Device}, kind {PushKind}, was due {FireAt}. Retrying did "
            + "not help — check the APNs key (Apns__KeyId / Apns__P8), the topic "
            + "and the payload.",
            message?.ScheduleId ?? "unreadable",
            message is null
                ? "unknown"
                : WakeScheduleService.Redact(message.DeviceToken),
            message?.PushKind ?? "unknown",
            message?.FireAt);
    }
}
