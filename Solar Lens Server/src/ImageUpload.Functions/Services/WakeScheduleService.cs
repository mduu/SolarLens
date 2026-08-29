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

    private readonly TableClient table;
    private readonly ILogger<WakeScheduleService> logger;
    private bool initialized;

    public WakeScheduleService(ILogger<WakeScheduleService> logger)
    {
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

    /// <summary>Rows whose push is due now (including the catch-up window).</summary>
    public async Task<List<WakeScheduleEntity>> GetDueAsync(DateTimeOffset now)
    {
        await EnsureTableAsync();
        var from = now - CatchUpWindow;
        var due = new List<WakeScheduleEntity>();

        // Hand-written OData rather than a LINQ expression: the expression
        // translator does not turn `Nullable<DateTimeOffset>` comparisons into
        // a working filter, and the failure mode is an empty result set rather
        // than an error — i.e. pushes silently never sent. Rows whose
        // NextFireAt is null (a parked deadline) simply have no such property
        // in Table storage and never match.
        var filter = TableClient.CreateQueryFilter(
            $"NextFireAt le {now} and NextFireAt gt {from}");
        var query = table.QueryAsync<WakeScheduleEntity>(filter);
        await foreach (var entity in query) due.Add(entity);
        return due;
    }

    /// <summary>
    /// Marks a row as handed over to the queue. Deadlines are parked
    /// (<c>NextFireAt = null</c>) rather than deleted, so the sender can still
    /// see whether the schedule was cancelled in the meantime; windows move to
    /// their next occurrence, skipping any the device was asleep for.
    /// </summary>
    public async Task AdvanceAsync(
        WakeScheduleEntity entity, DateTimeOffset now)
    {
        await EnsureTableAsync();

        if (entity.Kind == WakeKinds.Deadline)
        {
            entity.NextFireAt = null;
            entity.UpdatedAt = now;
            await table.UpdateEntityAsync(entity, ETag.All, TableUpdateMode.Replace);
            return;
        }

        var cadence = TimeSpan.FromMinutes(
            entity.CadenceMinutes ?? MinCadenceMinutes);
        var next = (entity.NextFireAt ?? now) + cadence;
        while (next <= now) next += cadence;

        if (entity.Until is { } until && next > until)
        {
            await table.DeleteEntityAsync(entity.PartitionKey, entity.RowKey);
            return;
        }

        entity.NextFireAt = next;
        entity.UpdatedAt = now;
        await table.UpdateEntityAsync(entity, ETag.All, TableUpdateMode.Replace);
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
