using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.LettersModelService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using System.Collections.Generic;
using System.Net;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace GraduationProjectWebApplication.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SignLanguageTranslatorController : BaseApiController
    {
        private readonly HttpClient _httpClient;
        private readonly string? correctSentenceAPIKey;
        private readonly string? correctSentenceBackUpAPIKey;
        private readonly string? generateAudioAPIKey;
        private readonly string? generateAudioBackUpAPIKey;
        private readonly string? hardwareCorrectSentenceKey;
        private readonly string? hardwareCorrectSentenceBackUpKey;
        private readonly string? hardwareTTSKey;
        private readonly string? LocalTTSURL;
        private readonly IModelService _modelService;
        private readonly ApplicationDbContext _context;
        private readonly ILogger<SignLanguageTranslatorController> _logger;

        public SignLanguageTranslatorController(
            HttpClient httpClient,
            IConfiguration configuration,
            IModelService modelService,
            ApplicationDbContext context,
            ILogger<SignLanguageTranslatorController> logger)
        {
            _httpClient = httpClient;

            // Configure HttpClient timeouts
            _httpClient.Timeout = TimeSpan.FromSeconds(30);

            correctSentenceAPIKey = configuration["CORRECT_SENTENCE_KEY"];
            correctSentenceBackUpAPIKey = configuration["CORRECT_SENTENCE_BACKUP_KEY"];
            generateAudioAPIKey = configuration["GENERATE_AUDIO_KEY"];
            generateAudioBackUpAPIKey = configuration["GENERATE_AUDIO_BACKUP_KEY"];
            hardwareCorrectSentenceKey = configuration["HARDWARE_CORRECT_SENTENCE_KEY"];
            hardwareCorrectSentenceBackUpKey = configuration["HARDWARE_CORRECT_SENTENCE_BACKUP_KEY"];
            hardwareTTSKey = configuration["HARDWARE_TTS_KEY"];
            LocalTTSURL = configuration["TTS_SERVICE"];
            _modelService = modelService;
            _context = context;
            _logger = logger;
        }


        [HttpPost("finalize-sentence")]
        //[EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<string>>> FinalizeSentence([FromBody] SentenceData data, [FromQuery] string client = "frontend")
        {
          
            try
            {

                if (string.IsNullOrEmpty(data?.Sentence))
                {
                    _logger.LogWarning("FinalizeSentence: No sentence data provided");
                    return BadRequest(ErrorResponse<string>("No sentence data provided."));
                }

                if (string.IsNullOrEmpty(client))
                {
                    _logger.LogWarning("FinalizeSentence: Missing 'client' parameter");

                    return BadRequest(ErrorResponse<string>(
                       "Missing 'client' parameter. Please provide the client."));
                }

                client = client.ToLower();

                if (client != "frontend" && client != "hardware")
                {
                    return BadRequest(ErrorResponse<string>(
                        "Invalid format. Allowed values are 'frontend' or 'hardware'."));
                }


                _logger.LogInformation("FinalizeSentence: Processing sentence - {Sentence}", data.Sentence);

                var concatenatedText = data.Sentence;
                var prompt = $"""
                You are an expert in Arabic linguistics. Your task is to process a string of concatenated Arabic letters received from a real-time sign language translator.

                You must perform the following three steps:
                1. Insert spaces to form a coherent, contextually logical sentence.
                2. Correct any minor spelling mistakes based on the likely context.
                3. Apply full and grammatically correct Arabic diacritics (التشكيل الكامل - Tashkeel) to every word in the sentence.

                Return ONLY the final, corrected, and fully diacritized Arabic sentence as a plain string. Do not include any translations, explanations, or markdown formatting.

                Input Text: "{concatenatedText}"
                """;

                var payload = new
                {
                    contents = new[]
                    {
                        new
                        {
                            role = "user",
                            parts = new[]
                            {
                                new { text = prompt }
                            }
                        }
                    }
                };

                string jsonPayload = JsonSerializer.Serialize(payload);
                var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                string mainApiKey = correctSentenceAPIKey;
                string backupApiKey = correctSentenceBackUpAPIKey;

                if(client == "hardware")
                {
                    mainApiKey = hardwareCorrectSentenceKey;
                    backupApiKey = hardwareCorrectSentenceBackUpKey;
                }

                string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

                var request = new HttpRequestMessage(HttpMethod.Post, apiUrl);

                request.Headers.Add("x-goog-api-key", mainApiKey);
                request.Content = content;

                HttpResponseMessage response = await _httpClient.SendAsync(request);

                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    _logger.LogWarning("FinalizeSentence: Rate limit exceeded for primary API key, switching to backup key");
                    var backupRequest = new HttpRequestMessage(HttpMethod.Post, apiUrl);

                    backupRequest.Headers.Add("x-goog-api-key", backupApiKey);
                    backupRequest.Content = content;

                    response = await _httpClient.SendAsync(backupRequest);
                }

                response.EnsureSuccessStatusCode();


                string responseBody = await response.Content.ReadAsStringAsync();
                _logger.LogDebug("FinalizeSentence: Gemini API response received");

                try
                {
                    var geminiResponse = JsonSerializer.Deserialize<GeminiResponse>(responseBody);
                    if (geminiResponse?.candidates?.FirstOrDefault()?.content?.parts?.FirstOrDefault()?.text != null)
                    {
                        string jsonText = geminiResponse.candidates.First().content.parts.First().text;

                        // Clean the response by removing markdown code blocks
                        jsonText = jsonText.Trim()
                                          .Replace("```json", "")
                                          .Replace("```", "")
                                          .Trim();

                        _logger.LogInformation("FinalizeSentence: Finalized sentence - {Result}", jsonText);

                        if (!string.IsNullOrEmpty(jsonText))
                        {
                            return Ok(SuccessResponse(jsonText));
                        }
                    }
                }
                catch (JsonException jsonEx)
                {
                    _logger.LogError(jsonEx, "FinalizeSentence: Failed to parse Gemini's JSON response. Response: {Response}", responseBody);
                }

                return Ok(SuccessResponse("None"));
            }
            catch (HttpRequestException httpEx)
            {
                _logger.LogError(httpEx, "FinalizeSentence: HTTP request to Gemini API failed");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Failed to communicate with sentence correction service. {httpEx.Message}"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "FinalizeSentence: Unexpected error occurred");
                return StatusCode(
                    500,
                    ErrorResponse<string>("An unexpected error occurred while finalizing the sentence."));
            }
        }

        [HttpPost("generate-audio")]
        //[EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<TTSResponse>>> GenerateAudio([FromBody] TTSRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request?.Text))
                {
                    _logger.LogWarning("GenerateAudio: Missing 'text' field");
                    return BadRequest(ErrorResponse<TTSResponse>("Missing 'text' field. Please provide the text to convert to audio."));
                }

                _logger.LogInformation("GenerateAudio: Generating audio for text - {Text}", request.Text);

                const string ApiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent";

                var payload = new
                {
                    contents = new[]
                    {
                    new
                    {
                        parts = new[]
                        {
                            new { text = $"Say this in a clear, friendly voice: {request.Text}" }
                        }
                    }
                },
                    generationConfig = new
                    {
                        responseModalities = new[] { "AUDIO" },
                        speechConfig = new
                        {
                            voiceConfig = new
                            {
                                prebuiltVoiceConfig = new { voiceName = "Kore" }
                            }
                        }
                    }
                };

                var jsonPayload = JsonSerializer.Serialize(payload);
                var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                try
                {


                    var geminiRequest = new HttpRequestMessage(HttpMethod.Post, ApiUrl);

                    geminiRequest.Headers.Add("x-goog-api-key", generateAudioAPIKey);
                    geminiRequest.Content = content;

                    HttpResponseMessage response = await _httpClient.SendAsync(geminiRequest);


                    if (response.StatusCode == HttpStatusCode.TooManyRequests)
                    {
                        _logger.LogWarning("GenerateAudio: Rate limit exceeded for primary API key, switching to backup key");
                        var backupRequest = new HttpRequestMessage(HttpMethod.Post, ApiUrl);

                        backupRequest.Headers.Add("x-goog-api-key", generateAudioBackUpAPIKey);
                        backupRequest.Content = content;

                        response = await _httpClient.SendAsync(backupRequest);
                    }

                    response.EnsureSuccessStatusCode();

                    var jsonResponse = await response.Content.ReadAsStringAsync();

                    var geminiResult = JsonSerializer.Deserialize<JsonElement>(jsonResponse);

                    var audioPart = geminiResult
                        .GetProperty("candidates")[0]
                        .GetProperty("content")
                        .GetProperty("parts")[0];

                    var audioData = audioPart
                        .GetProperty("inlineData")
                        .GetProperty("data")
                        .GetString();

                    var mimeType = audioPart
                        .GetProperty("inlineData")
                        .GetProperty("mimeType")
                        .GetString();

                    var sampleRate = 24000;
                    var rateMatch = System.Text.RegularExpressions.Regex.Match(mimeType ?? "", @"rate=(\d+)");
                    if (rateMatch.Success)
                    {
                        sampleRate = int.Parse(rateMatch.Groups[1].Value);
                    }

                    var ttsResponse = new TTSResponse
                    {
                        AudioData = audioData,
                        SampleRate = sampleRate
                    };

                    _logger.LogInformation("GenerateAudio: Audio generated successfully with sample rate {SampleRate}", sampleRate);

                    return Ok(SuccessResponse(ttsResponse));
                }
                catch (HttpRequestException ex)
                {
                    _logger.LogError(ex, "GenerateAudio: Error calling Gemini API");
                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>($"Error calling Gemini API: {ex.Message}"));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GenerateAudio: Unexpected error occurred");
                return StatusCode(
                   (int)HttpStatusCode.InternalServerError,
                   ErrorResponse<string>($"An unexpected error occurred."));
            }
        }

        [HttpPost("text-to-speech/hardware")]
        //[EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult> AzureTTS([FromBody] TTSRequest request, [FromQuery] string format = "mp3")
        {
            try
            {
                if (string.IsNullOrEmpty(request?.Text))
                {
                    _logger.LogWarning("AzureTTS: Missing 'text' field");
                    return BadRequest(ErrorResponse<TTSResponse>("Missing 'text' field. Please provide the text to convert to audio."));
                }

                if (string.IsNullOrEmpty(format))
                {
                    _logger.LogWarning("AzureTTS: Missing 'format' parameter");

                    return BadRequest(ErrorResponse<TTSResponse>(
                       "Missing 'format' parameter. Please provide the format to convert to audio."));
                }

                format = format.ToLower();

                if (format != "mp3" && format != "base64")
                {
                    return BadRequest(ErrorResponse<TTSResponse>(
                        "Invalid format. Allowed values are 'mp3' or 'base64'."));
                }

                _logger.LogInformation("AzureTTS: Generating audio for text - {Text}", request.Text);


                const string ApiUrl = "https://eastus.tts.speech.microsoft.com/cognitiveservices/v1";

                var ssmlBody = $@"
                                <speak version='1.0' xml:lang='ar-EG'>
                                    <voice name='ar-EG-SalmaNeural'>
                                        {System.Security.SecurityElement.Escape(request.Text)}
                                    </voice>
                                </speak>";

                var content = new StringContent(ssmlBody, Encoding.UTF8, "application/ssml+xml");

                var requestMessage = new HttpRequestMessage(HttpMethod.Post, ApiUrl);
                requestMessage.Headers.Add("Ocp-Apim-Subscription-Key", hardwareTTSKey);
                requestMessage.Headers.Add("X-Microsoft-OutputFormat", "audio-16khz-32kbitrate-mono-mp3");
                requestMessage.Headers.Add("User-Agent", "dotnet-api");
                requestMessage.Content = content;


                try
                {
                    var response = await _httpClient.SendAsync(requestMessage);
                    response.EnsureSuccessStatusCode();


                    var audioBytes = await response.Content.ReadAsByteArrayAsync();

                    if (format.ToLower() == "base64")
                    {
                        var base64Audio = Convert.ToBase64String(audioBytes);


                        var result = new TTSResponse
                        {
                            AudioData = base64Audio,
                            SampleRate = 16000
                        };

                        return Ok(SuccessResponse(result));

                    }
                    else
                    {
                        return File(audioBytes, "audio/mpeg", "speech.mp3");
                    }

                }
                catch (HttpRequestException httpEx)
                {
                    _logger.LogError(httpEx, "AzureTTS: Error calling Azure API");
                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>($"Error calling Azure API: {httpEx.Message}"));
                }


            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AzureTTS: Unexpected error occurred");
                return StatusCode(
                   (int)HttpStatusCode.InternalServerError,
                   ErrorResponse<string>($"An unexpected error occurred."));
            }
        }

        [HttpPost("generate-local-tts")]
        public async Task<ActionResult> GenerateLocalTts([FromBody] TTSRequest request, [FromQuery] string format = "mp3")
        {
            if (string.IsNullOrWhiteSpace(request.Text))
            {
                return BadRequest(new { IsSuccess = false, ErrorMessage = "Text cannot be empty." });
            }

            try
            {
                string localTtsUrl = $"{LocalTTSURL}/tts/";

                var pythonRequestBody = new
                {
                    text = request.Text,
                    speaker = 1,
                    pace = 1.0
                };

                var response = await _httpClient.PostAsJsonAsync(localTtsUrl, pythonRequestBody);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    return StatusCode(500, new { IsSuccess = false, ErrorMessage = $"Python TTS failed: {errorContent}" });
                }

                // 1. THE FIX: Read the response as raw bytes, NOT as JSON!
                byte[] audioBytes = await response.Content.ReadAsByteArrayAsync();

                // 2. Format the response for the frontend
                if (format.Equals("base64", StringComparison.OrdinalIgnoreCase))
                {
                    // If the frontend asked for base64, convert the bytes and wrap in JSON
                    return Ok(new
                    {
                        Result = new
                        {
                            OriginalText = request.Text,
                            AudioData = Convert.ToBase64String(audioBytes),
                            SampleRate = 22050
                        }
                    });
                }
                else
                {
                    // Default: Send the raw playable audio file to the frontend
                    return File(audioBytes, "audio/wav", "speech.wav");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { IsSuccess = false, ErrorMessage = $"An error occurred connecting to the local AI: {ex.Message}" });
            }
        }
    }
}
