using System.Text.Json;
using System.Security.Cryptography;
using System.Text;
using Azure;
using Azure.Data.Tables;
using ImageUpload.Functions.Models;
using Microsoft.Extensions.Logging;

namespace ImageUpload.Functions.Services;

/// <summary>
/// Storage for wake schedules (story #9). Backed by an Azure Table in the
/// existing storage account — a few hundred rows at the expected user count,
/// so a filtered scan once per minute is cheap and no partitioning scheme is
/// needed yet.
/// </summary>
public class WakeScheduleService
{
    /// <summary>Minimum cadence we accept for silent-push windows. Guards cost and APNs budget.</summary>
    public const int MinCadenceMinutes = 10;

    /// <summary>Longest window we keep alive without the app renewing it.</summary>
    public static readonly TimeSpan MaxWindowDuration = TimeSpan.FromDays(7);

    /// <summary>
    /// How far back the scheduler still picks up due rows, so a deploy or a
    /// cold start doesn't silently swallow a minute's worth of pushes.
    /// </summary>
    public static readonly TimeSpan CatchUpWindow = TimeSpan.FromMinutes(15);

    /// Azure Storage caps a message's invisibility at seven days, so a wake-up
    /// further out is enqueued in hops: the message surfaces early, the sender
    /// sees the row is not due yet and re-enqueues for the remainder.
    public static readonly TimeSpan MaxVisibility = TimeSpan.FromDays(6);

    /// A message may surface a moment before its time; anything inside this is
    /// treated as due rather than re-queued.
    public static readonly TimeSpan DueTolerance = TimeSpan.FromSeconds(5);

    private readonly TableClient table;
    private readonly ApnsQueueProvider queues;
    private readonly ILogger<WakeScheduleService> logger;
    private bool initialized;

    public WakeScheduleService(
        ApnsQueueProvider queues,
        ILogger<WakeScheduleService> logger)
    {
        this.queues = queues;
        this.logger = logger;

        var connectionString =
            Environment.GetEnvironmentVariable("BlobStorageConnectionString")
            ?? Environment.GetEnvironmentVariable("AzureWebJobsStorage")
            ?? throw new InvalidOperationException(
                "No storage connection string configured");
        var tableName =
            Environment.GetEnvironmentVariable("WakeScheduleTableName")
            ?? "WakeSchedules";

        // Same reasoning as ApnsQueueProvider: pin the service version so the
        // local Azurite emulator keeps working when the SDK moves ahead.
        table = new TableClient(
            connectionString,
            tableName,
            new TableClientOptions(TableClientOptions.ServiceVersion.V2019_02_02));
    }

    private async Task EnsureTableAsync()
    {
        if (initialized) return;
        await table.CreateIfNotExistsAsync();
        initialized = true;
    }

    public static string HashSecret(string secret)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(bytes);
    }

    public static bool IsValidDeviceToken(string? token) =>
        !string.IsNullOrEmpty(token)
        && token.Length is >= 64 and <= 200
        && token.All(Uri.IsHexDigit);

    public async Task<WakeScheduleEntity?> GetAsync(
        string deviceToken, string scheduleId)
    {
        await EnsureTableAsync();
        try
        {
            return await table.GetEntityAsync<WakeScheduleEntity>(
                deviceToken, scheduleId);
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    public async Task<List<WakeScheduleEntity>> GetForDeviceAsync(
        string deviceToken)
    {
        await EnsureTableAsync();
        var results = new List<WakeScheduleEntity>();
        var query = table.QueryAsync<WakeScheduleEntity>(
            e => e.PartitionKey == deviceToken);
        await foreach (var entity in query) results.Add(entity);
        return results;
    }

    /// <summary>
    /// Creates or updates one schedule. Validation and clamping happen here so
    /// a buggy or malicious client cannot ask for a 10-second silent-push
    /// cadence or a schedule that never expires.
    /// </summary>
    public async Task<(bool ok, string? error)> UpsertAsync(
        string deviceToken,
        string scheduleId,
        WakeScheduleRequest request,
        DateTimeOffset now)
    {
        await EnsureTableAsync();

        if (string.IsNullOrWhiteSpace(request.InstallSecret))
            return (false, "installSecret is required");
        if (!WakeKinds.IsValid(request.Kind))
            return (false, "kind must be 'deadline' or 'window'");
        if (!WakePushKinds.IsValid(request.PushKind))
            return (false, "pushKind must be 'alert' or 'silent'");
        if (request.Environment is not null
            && !WakeEnvironments.IsValid(request.Environment))
            return (false, "environment must be 'sandbox' or 'production'");

        var existing = await GetAsync(deviceToken, scheduleId);
        var secretHash = HashSecret(request.InstallSecret!);
        if (existing is not null && existing.SecretHash != secretHash)
            return (false, "installSecret does not match this schedule");

        var entity = new WakeScheduleEntity
        {
            PartitionKey = deviceToken,
            RowKey = scheduleId,
            Environment = request.Environment ?? WakeEnvironments.Production,
            Kind = request.Kind!,
            PushKind = request.PushKind!,
            Automation = request.Automation,
            Category = request.Category,
            DeepLink = request.DeepLink,
            DefaultTitle = request.DefaultTitle,
            DefaultBody = request.DefaultBody,
            SecretHash = secretHash,
            CreatedAt = existing?.CreatedAt ?? now,
            UpdatedAt = now
        };

        if (entity.Kind == WakeKinds.Deadline)
        {
            if (request.FireAt is null)
                return (false, "fireAt is required for kind 'deadline'");
            // A deadline in the past is pointless; the device's own fallback
            // notification has long fired.
            if (request.FireAt < now - CatchUpWindow)
                return (false, "fireAt is too far in the past");
            entity.NextFireAt = request.FireAt;
        }
        else
        {
            var cadence = request.CadenceMinutes ?? MinCadenceMinutes;
            if (cadence < MinCadenceMinutes)
                cadence = MinCadenceMinutes;
            entity.CadenceMinutes = cadence;

            var until = request.Until ?? now + MaxWindowDuration;
            if (until > now + MaxWindowDuration)
                until = now + MaxWindowDuration;
            if (until <= now)
                return (false, "until must be in the future");
            entity.Until = until;

            // Renewing a window must not postpone its next push. The app
            // renews while work is running (and again after every cold start),
            // so recomputing "now + cadence" each time would starve the
            // silent pushes entirely on a device the user opens often.
            // Extending `Until` is the point of a renewal; the schedule itself
            // keeps ticking.
            var existingNext = existing?.NextFireAt;
            if (existing?.Kind == WakeKinds.Window
                && existing.CadenceMinutes == cadence
                && existingNext > now)
            {
                entity.NextFireAt = existingNext;
            }
            else
            {
                entity.NextFireAt = request.FireAt is { } fireAt && fireAt > now
                    ? fireAt
                    : now.AddMinutes(cadence);
            }
        }

        // Queue a message only when the pending slot is new or has moved.
        // A renewal that keeps NextFireAt must not enqueue: the message for
        // that slot is already in the queue, and a second one would be sent
        // too — both carry the row's exact fire time, so the sender's
        // staleness check cannot tell them apart.
        //
        // Enqueue before writing the row: an orphaned message (row write
        // fails) is dropped by the sender's row check, whereas a row without
        // a message would never fire.
        var pendingSlotUnchanged = existing is not null
            && existing.NextFireAt == entity.NextFireAt;
        if (!pendingSlotUnchanged)
        {
            await EnqueueAsync(entity, now);
        }
        await table.UpsertEntityAsync(entity, TableUpdateMode.Replace);
        logger.LogInformation(
            "Wake schedule upserted: device {Device}, kind {Kind}, next {Next}",
            Redact(deviceToken), entity.Kind, entity.NextFireAt);
        return (true, null);
    }

    public async Task<(bool ok, string? error)> DeleteAsync(
        string deviceToken, string scheduleId, string? installSecret)
    {
        await EnsureTableAsync();
        var existing = await GetAsync(deviceToken, scheduleId);
        if (existing is null) return (true, null); // already gone — idempotent

        if (installSecret is null
            || existing.SecretHash != HashSecret(installSecret))
            return (false, "installSecret does not match this schedule");

        await table.DeleteEntityAsync(deviceToken, scheduleId);
        return (true, null);
    }

    public async Task<(bool ok, string? error, int deleted)>
        DeleteAllForDeviceAsync(string deviceToken, string? installSecret)
    {
        await EnsureTableAsync();
        var rows = await GetForDeviceAsync(deviceToken);
        if (rows.Count == 0) return (true, null, 0);

        if (installSecret is null)
            return (false, "installSecret is required", 0);
        var hash = HashSecret(installSecret);
        if (!rows.Any(r => r.SecretHash == hash))
            return (false, "installSecret does not match this device", 0);

        foreach (var row in rows)
            await table.DeleteEntityAsync(row.PartitionKey, row.RowKey);
        return (true, null, rows.Count);
    }

    /// <summary>
    /// Removes every schedule of a device. Called when APNs reports the token
    /// as unregistered — no secret required, because APNs is the authority
    /// here and the rows can never deliver anything again.
    /// </summary>
    public async Task<int> PurgeDeviceAsync(string deviceToken)
    {
        await EnsureTableAsync();
        var rows = await GetForDeviceAsync(deviceToken);
        foreach (var row in rows)
            await table.DeleteEntityAsync(row.PartitionKey, row.RowKey);
        if (rows.Count > 0)
            logger.LogInformation(
                "Purged {Count} schedules for unregistered device {Device}",
                rows.Count, Redact(deviceToken));
        return rows.Count;
    }

    /// <summary>
    /// Puts the push on the queue so that it becomes visible exactly when the
    /// row is due. There is no polling timer: the queue is the schedule.
    /// </summary>
    public async Task EnqueueAsync(WakeScheduleEntity entity, DateTimeOffset now)
    {
        if (entity.NextFireAt is not { } fireAt) return;

        var delay = fireAt - now;
        if (delay < TimeSpan.Zero) delay = TimeSpan.Zero;
        if (delay > MaxVisibility) delay = MaxVisibility;

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
            FireAt = fireAt,
            Attempt = 0
        };

        await queues.Queue.SendMessageAsync(
            JsonSerializer.Serialize(message), visibilityTimeout: delay);
    }

    /// <summary>
    /// Moves a window to its next occurrence and re-queues it, or deletes it
    /// once it has passed `Until`. Returns false when the window is over.
    /// </summary>
    public async Task<bool> AdvanceWindowAsync(
        WakeScheduleEntity entity, DateTimeOffset now)
    {
        await EnsureTableAsync();

        var cadence = TimeSpan.FromMinutes(
            entity.CadenceMinutes ?? MinCadenceMinutes);
        var next = (entity.NextFireAt ?? now) + cadence;
        while (next <= now) next += cadence;

        if (entity.Until is { } until && next > until)
        {
            try
            {
                await table.DeleteEntityAsync(
                    entity.PartitionKey, entity.RowKey, entity.ETag);
            }
            catch (RequestFailedException ex) when (ex.Status == 412)
            {
                // Another worker touched the row first; leave it to them.
                return true;
            }
            return false;
        }

        entity.NextFireAt = next;
        entity.UpdatedAt = now;
        try
        {
            // The ETag is the duplicate killer: when the same slot is being
            // processed twice in parallel (queue delivery is at-least-once),
            // only one worker advances the row — the loser gets a 412 and
            // must not queue the next occurrence, otherwise one duplicate
            // becomes a duplicate of every slot that follows.
            await table.UpdateEntityAsync(
                entity, entity.ETag, TableUpdateMode.Replace);
        }
        catch (RequestFailedException ex) when (ex.Status == 412)
        {
            logger.LogInformation(
                "Window {ScheduleId} was advanced by a parallel worker — not queueing a second occurrence",
                entity.RowKey);
            return true;
        }
        await EnqueueAsync(entity, now);
        return true;
    }

    /// <summary>Deletes a deadline row after its push was accepted by APNs.</summary>
    public async Task CompleteDeadlineAsync(
        string deviceToken, string scheduleId)
    {
        await EnsureTableAsync();
        try
        {
            await table.DeleteEntityAsync(deviceToken, scheduleId);
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            // Already cancelled by the device — nothing to do.
        }
    }

    /// <summary>
    /// Heals schedules whose queue message went missing (lost, purged, or a
    /// crash between enqueue and row write in an older version). Skipping the
    /// enqueue on unchanged renewals makes such a row permanent otherwise: a
    /// stale deadline is dropped, an overdue window is moved to its next
    /// future slot and re-queued.
    /// </summary>
    public async Task<int> RepairOverdueAsync(DateTimeOffset now)
    {
        await EnsureTableAsync();
        var cutoff = now - TimeSpan.FromHours(1);
        var overdue = new List<WakeScheduleEntity>();
        var filter = TableClient.CreateQueryFilter($"NextFireAt lt {cutoff}");
        var query = table.QueryAsync<WakeScheduleEntity>(filter);
        await foreach (var entity in query) overdue.Add(entity);

        var repaired = 0;
        foreach (var entity in overdue)
        {
            if (entity.Kind == WakeKinds.Deadline)
            {
                // An hour late is far past the device's own fallback; the
                // push would only confuse.
                await table.DeleteEntityAsync(
                    entity.PartitionKey, entity.RowKey);
            }
            else
            {
                await AdvanceWindowAsync(entity, now);
            }
            repaired++;
        }
        if (repaired > 0)
        {
            logger.LogWarning(
                "Repaired {Count} schedules whose queue message had gone missing",
                repaired);
        }
        return repaired;
    }

    /// <summary>Removes rows that outlived their window (defensive; the normal path deletes them).</summary>
    public async Task<int> CleanupExpiredAsync(DateTimeOffset now)
    {
        await EnsureTableAsync();
        var cutoff = now.AddDays(-1);
        var stale = new List<WakeScheduleEntity>();
        var filter = TableClient.CreateQueryFilter($"Until lt {cutoff}");
        var query = table.QueryAsync<WakeScheduleEntity>(filter);
        await foreach (var entity in query) stale.Add(entity);

        foreach (var entity in stale)
            await table.DeleteEntityAsync(entity.PartitionKey, entity.RowKey);
        return stale.Count;
    }

    /// <summary>Device tokens are personal data — never log them in full.</summary>
    public static string Redact(string deviceToken) =>
        deviceToken.Length <= 8
            ? "…"
            : $"{deviceToken[..4]}…{deviceToken[^4..]}";
}
