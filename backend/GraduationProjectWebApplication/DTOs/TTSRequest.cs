using System.Text.Json.Serialization;

namespace GraduationProjectWebApplication.DTOs
{
    public class TTSRequest
    {
        [JsonPropertyName("text")]
        public string Text { get; set; } = string.Empty;
    }
}
