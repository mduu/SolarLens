using Azure.Storage.Queues;

namespace ImageUpload.Functions.Services;

/// <summary>
/// Owns the queue clients used by the push pipeline (story #9).
///
/// One message = one push, on purpose: a batch containing a single dead token
/// would retry the whole batch and duplicate pushes to the healthy devices,
/// and the poison queue would lose per-push granularity.
/// </summary>
public class ApnsQueueProvider
{
    public const string QueueName = "apns-push";

    /// <summary>
    /// Name is fixed by the Functions runtime: after <c>maxDequeueCount</c>
    /// failures a message is moved to <c>&lt;queue&gt;-poison</c>. This is
    /// Azure Storage Queues' equivalent of dead-lettering.
    /// </summary>
    public const string PoisonQueueName = QueueName + "-poison";

    public QueueClient Queue { get; }
    public QueueClient PoisonQueue { get; }

    public ApnsQueueProvider()
    {
        var connectionString =
            Environment.GetEnvironmentVariable("BlobStorageConnectionString")
            ?? Environment.GetEnvironmentVariable("AzureWebJobsStorage")
            ?? throw new InvalidOperationException(
                "No storage connection string configured");

        // Pin the service version instead of taking the SDK's newest: Azurite
        // (local development) rejects API versions it does not know yet, and
        // Azure Storage keeps older versions supported indefinitely. Bump this
        // deliberately, not implicitly via an SDK update.
        var options = new QueueClientOptions(
            QueueClientOptions.ServiceVersion.V2025_11_05)
        {
            // The Functions queue trigger expects base64 messages.
            MessageEncoding = QueueMessageEncoding.Base64
        };

        Queue = new QueueClient(connectionString, QueueName, options);
        Queue.CreateIfNotExists();

        PoisonQueue = new QueueClient(
            connectionString, PoisonQueueName, options);
    }
}
