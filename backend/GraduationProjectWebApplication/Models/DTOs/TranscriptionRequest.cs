using System.Text.Json.Serialization;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class TranscriptionRequest
    {
        [JsonPropertyName("audioData")]
        public string? AudioData { get; set; }

        [JsonPropertyName("mimeType")]
        public string? MimeType { get; set; }
    }
}
