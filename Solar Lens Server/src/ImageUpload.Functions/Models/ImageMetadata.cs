namespace ImageUpload.Functions.Models;

public class ImageMetadata
{
    public required string DeviceId { get; set; }
    public required string ImageType { get; set; } // "logo" or "background"
    public required string Format { get; set; } // "png" or "jpeg"
    public int SizeBytes { get; set; }
    public DateTime UploadedAt { get; set; }
    public int DownloadCount { get; set; }

    public string GetBlobName() => $"{DeviceId}_{ImageType}.{Format}";
}

public class ImageUploadRequest
{
    public required string DeviceId { get; set; }
    public required string ImageType { get; set; }
    public required string ImageData { get; set; } // Base64 encoded
    public required string Format { get; set; }
}

public class ImageCheckResponse
{
    public bool Available { get; set; }
    public string? ImageType { get; set; }
    public string? Format { get; set; }
}