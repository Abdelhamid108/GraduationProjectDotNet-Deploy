using System.Text.Json.Serialization;

namespace GraduationProjectWebApplication.DTOs
{
    public class TTSResponse
    {
        [JsonPropertyName("audioData")]
        public string AudioData { get; set; } = string.Empty;

        [JsonPropertyName("sampleRate")]
        public int SampleRate { get; set; }
    }
}
