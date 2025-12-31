using System.Text.Json;

namespace ImageUpload.Functions.Services;

public static class JsonSerializerOptionsDefaults
{
    public static JsonSerializerOptions CamelCase { get; } = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };
}