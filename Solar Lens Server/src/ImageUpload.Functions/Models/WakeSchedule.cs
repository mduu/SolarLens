using Azure;
using Azure.Data.Tables;

namespace ImageUpload.Functions.Models;

/// <summary>
/// One scheduled wake-up for one device. This is the <b>entire</b> knowledge the
/// Solar Lens server has about a user's automations (story #9 / ADR-006): a
/// device token, when to wake it, and opaque strings the device itself supplied
/// for the notification. No credentials, no rules, no measurements.
/// </summary>
public class WakeScheduleEntity : ITableEntity
{
    /// <summary>APNs device token (64 hex chars).</summary>
    public string PartitionKey { get; set; } = string.Empty;

    /// <summary>Schedule id, generated on the device (automation run / monitor id).</summary>
    public string RowKey { get; set; } = string.Empty;

    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }

    /// <summary>"sandbox" for debug builds, "production" for TestFlight/App Store.</summary>
    public string Environment { get; set; } = WakeEnvironments.Production;

    /// <summary><see cref="WakeKinds"/>: one-shot deadline or a repeating window.</summary>
    public string Kind { get; set; } = WakeKinds.Deadline;

    /// <summary><see cref="WakePushKinds"/>: visible alert (runs the NSE) or silent background wake.</summary>
    public string PushKind { get; set; } = WakePushKinds.Alert;

    /// <summary>
    /// When the next push is due. Null once a deadline has been handed to the
    /// queue, so the timer never selects it twice.
    /// </summary>
    public DateTimeOffset? NextFireAt { get; set; }

    /// <summary>Repeat interval for <see cref="WakeKinds.Window"/> schedules.</summary>
    public int? CadenceMinutes { get; set; }

    /// <summary>Hard end for a window; the row is deleted once passed.</summary>
    public DateTimeOffset? Until { get; set; }

    /// <summary>Opaque automation identifier the device registered (echoed back in the payload).</summary>
    public string? Automation { get; set; }

    /// <summary>Notification category id, chosen by the device.</summary>
    public string? Category { get; set; }

    /// <summary>Deep link the notification should open, e.g. solarlens://automations.</summary>
    public string? DeepLink { get; set; }

    /// <summary>
    /// Fallback notification text, already localized <b>on the device</b> — the
    /// server has no idea what language the user speaks, and the extension
    /// overwrites this text with the real outcome anyway.
    /// </summary>
    public string? DefaultTitle { get; set; }

    public string? DefaultBody { get; set; }

    /// <summary>SHA-256 of the per-install secret; guards updates and deletes.</summary>
    public string SecretHash { get; set; } = string.Empty;

    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

public static class WakeKinds
{
    public const string Deadline = "deadline";
    public const string Window = "window";

    public static bool IsValid(string? value) =>
        value is Deadline or Window;
}

public static class WakePushKinds
{
    public const string Alert = "alert";
    public const string Silent = "silent";

    public static bool IsValid(string? value) =>
        value is Alert or Silent;
}

public static class WakeEnvironments
{
    public const string Sandbox = "sandbox";
    public const string Production = "production";

    public static bool IsValid(string? value) =>
        value is Sandbox or Production;
}

/// <summary>Body of <c>PUT /api/wake/{deviceToken}/{scheduleId}</c>.</summary>
public class WakeScheduleRequest
{
    public string? Environment { get; set; }
    public string? Kind { get; set; }
    public string? PushKind { get; set; }
    public DateTimeOffset? FireAt { get; set; }
    public int? CadenceMinutes { get; set; }
    public DateTimeOffset? Until { get; set; }
    public string? Automation { get; set; }
    public string? Category { get; set; }
    public string? DeepLink { get; set; }
    public string? DefaultTitle { get; set; }
    public string? DefaultBody { get; set; }
    public string? InstallSecret { get; set; }
}

/// <summary>One queued push. Deliberately one message per push, never a batch.</summary>
public class ApnsPushMessage
{
    public required string DeviceToken { get; set; }
    public required string Environment { get; set; }
    public required string ScheduleId { get; set; }
    public required string PushKind { get; set; }
    public string? Automation { get; set; }
    public string? Category { get; set; }
    public string? DeepLink { get; set; }
    public string? Title { get; set; }
    public string? Body { get; set; }

    /// <summary>The moment this push was due — used to give up on stale retries.</summary>
    public DateTimeOffset FireAt { get; set; }

    /// <summary>Incremented by our own transient-retry loop (not the queue's dequeue count).</summary>
    public int Attempt { get; set; }
}
