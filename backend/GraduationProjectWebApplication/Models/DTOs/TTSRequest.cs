using System.Text.Json.Serialization;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class TTSRequest
    {
        [JsonPropertyName("text")]
        public string Text { get; set; } = string.Empty;
    }
}
