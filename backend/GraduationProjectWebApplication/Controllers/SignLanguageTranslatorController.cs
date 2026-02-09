using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.LettersModelService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
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
        private readonly string? textToAudioAPIKey;
        private readonly string? textToAudioStep2APIKey;
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
            textToAudioAPIKey = configuration["TEXT_TO_AUDIO_KEY"];
            textToAudioStep2APIKey = configuration["TEXT_TO_AUDIO_STEP_2_KEY"];
            _modelService = modelService;
            _context = context;
            _logger = logger;
        }


        [HttpPost]
        public async Task<ActionResult<APIResponseDTO<string>>> TranslateSign([FromBody] FrameData frameData)
        {
            if (string.IsNullOrEmpty(frameData?.ImageData))
            {
                _logger.LogWarning("TranslateSign: No image data provided");
                return BadRequest(ErrorResponse<string>("No image data provided. Please include base64-encoded image in 'ImageData'."));
            }

            byte[]? imageBytes = null;

            try
            {
                var base64Image = frameData.ImageData.Replace("data:image/jpeg;base64,", "");
                imageBytes = Convert.FromBase64String(base64Image);

                if (imageBytes == null || imageBytes.Length == 0)
                {
                    _logger.LogWarning("TranslateSign: Decoded image bytes are null or empty");
                    return BadRequest(ErrorResponse<string>("Decoded image bytes are null or empty."));
                }

                _logger.LogDebug("TranslateSign: Processing image of size {Size} bytes", imageBytes.Length);

                ModelDetection modelDetection = await _modelService.ModelRunner(imageBytes);

                if (modelDetection.IsSuccess)
                {
                    if (modelDetection.FinalDetections.Any())
                    {
                        var bestDetection = modelDetection.FinalDetections
                            .OrderByDescending(d => d.Confidence)
                            .First();

                        if (bestDetection.Confidence > 0.71)
                        {
                            _logger.LogInformation(
                                "TranslateSign: Detected '{Arabic}' (English: '{English}') with confidence {Confidence:F4}",
                                bestDetection.ClassLabelArabic,
                                bestDetection.ClassLabelEnglish,
                                bestDetection.Confidence);

                            return Ok(SuccessResponse(new { translation = bestDetection.ClassLabelArabic }));
                        }

                        _logger.LogDebug(
                            "TranslateSign: Best detection confidence {Confidence:F4} below threshold 0.71",
                            bestDetection.Confidence);

                        return Ok(SuccessResponse(new { translation = "No sign detected (try adjusting your gesture)." }));
                    }
                    else
                    {
                        _logger.LogDebug("TranslateSign: No detections found");
                        return Ok(SuccessResponse(new { translation = "No sign detected." }));
                    }
                }
                else
                {
                    _logger.LogError("TranslateSign: Model detection failed - {Error}", modelDetection.ErrorMessage);
                    return BadRequest(ErrorResponse<string>(modelDetection.ErrorMessage));
                }
            }
            catch (FormatException ex)
            {
                _logger.LogError(ex, "TranslateSign: Invalid base64 image format");
                return BadRequest(ErrorResponse<string>("Invalid image format. Ensure the image is a valid base64-encoded JPEG."));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "TranslateSign: Unexpected error occurred");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Unexpected server error while processing the image: {ex.Message}"));
            }
            finally
            {
                // Help GC by clearing byte array
                if (imageBytes != null && imageBytes.Length > 0)
                {
                    Array.Clear(imageBytes, 0, imageBytes.Length);
                }
            }
        }

        [HttpPost("finalize-sentence")]
        [EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<string>>> FinalizeSentence([FromBody] SentenceData data)
        {
            if (string.IsNullOrEmpty(data?.Sentence))
            {
                _logger.LogWarning("FinalizeSentence: No sentence data provided");
                return BadRequest(ErrorResponse<string>("No sentence data provided."));
            }

            try
            {
                _logger.LogInformation("FinalizeSentence: Processing sentence - {Sentence}", data.Sentence);

                var concatenatedText = data.Sentence;
                var prompt = $"""
                You are an expert in Arabic linguistics. Your task is to take a string of concatenated Arabic letters, 
                which comes from a real-time sign language translator, and insert spaces to form a coherent sentence. 
                You should also correct minor spelling mistakes based on the most likely context.
                Return ONLY the corrected sentence as a plain string.
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

                string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={correctSentenceAPIKey}";

                HttpResponseMessage response = await _httpClient.PostAsync(apiUrl, content);

                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    _logger.LogWarning("FinalizeSentence: Rate limit exceeded for primary API key, switching to backup key");
                    string backupApiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={correctSentenceBackUpAPIKey}";
                    response = await _httpClient.PostAsync(backupApiUrl, content);
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

        [HttpPost("correct-sentence")]
        [EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<CorrectedResponse>>> CorrectSentence([FromBody] SentenceData sentenceData)
        {
            if (string.IsNullOrEmpty(sentenceData?.Sentence))
            {
                _logger.LogWarning("CorrectSentence: No sentence provided");
                return BadRequest(ErrorResponse<CorrectedResponse>("No sentence provided for correction."));
            }

            _logger.LogInformation("CorrectSentence: Correcting sentence - {Sentence}", sentenceData.Sentence);

            try
            {
                string prompt = $"I have a task that needs an Arabic grammar and spelling expert, " +
                $"and I want you to help me in it, the process is as the following: " +
                $"\r\nThe user will provide a single Arabic sentence that might have grammatical or spelling errors, " +
                $"some might include Arabic names as well, " +
                $"so you should look for the similar names possible to the wrong name sent to you." +
                $"\r\nYou need to provide the most likely corrected version of this sentence.\r\n" +
                $"Return ONLY a JSON object with the following exact format (no markdown, no code blocks, no additional text): " +
                $"{{\"suggestion\": {{\"correctedSentence\": \"the_corrected_sentence_here\"}}}} " +
                $"Do not include any other text, explanations, or formatting. " +
                $"The sentence to correct is: '{sentenceData.Sentence}'";

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

                string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={correctSentenceAPIKey}";

                HttpResponseMessage response = await _httpClient.PostAsync(apiUrl, content);
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();
                _logger.LogDebug("CorrectSentence: Gemini API response received");

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

                        _logger.LogDebug("CorrectSentence: Cleaned JSON response - {CleanedJson}", jsonText);

                        var correctedResponse = JsonSerializer.Deserialize<CorrectedResponse>(jsonText);

                        if (correctedResponse?.suggestion?.correctedSentence != null)
                        {
                            _logger.LogInformation("CorrectSentence: Corrected to - {Corrected}", correctedResponse.suggestion.correctedSentence);
                            return Ok(SuccessResponse(correctedResponse));
                        }
                    }
                }
                catch (JsonException jsonEx)
                {
                    _logger.LogError(jsonEx, "CorrectSentence: Failed to parse Gemini's JSON response. Response: {Response}", responseBody);
                }

                return Ok(SuccessResponse(new { suggestion = new { correctedSentence = "[None]" } }));
            }
            catch (HttpRequestException httpEx)
            {
                _logger.LogError(httpEx, "CorrectSentence: HTTP request to Gemini API failed");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"HTTP Request Error to Gemini API: {httpEx.Message}"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CorrectSentence: Unexpected error occurred");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Error during correction: {ex.Message}"));
            }
        }

        [HttpPost("generate-audio")]
        [EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<TTSResponse>>> GenerateAudio([FromBody] TTSRequest request)
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
                var response = await _httpClient.PostAsync($"{ApiUrl}?key={generateAudioAPIKey}", content);

                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    _logger.LogWarning("GenerateAudio: Rate limit exceeded for primary API key, switching to backup key");
                    response = await _httpClient.PostAsync($"{ApiUrl}?key={generateAudioBackUpAPIKey}", content);
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
            catch (Exception ex)
            {
                _logger.LogError(ex, "GenerateAudio: Unexpected error occurred");
                return StatusCode(
                   (int)HttpStatusCode.InternalServerError,
                   ErrorResponse<string>($"An unexpected error occurred."));
            }
        }

        [HttpPost("text-to-audio")]
        [EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<TTSResponse>>> TextToAudio([FromBody] SentenceData data)
        {
            if (string.IsNullOrEmpty(data?.Sentence))
            {
                _logger.LogWarning("TextToAudio: Missing 'Sentence' field");
                return BadRequest(ErrorResponse<TTSResponse>("Missing 'Sentence' field in request body."));
            }

            try
            {
                // -------------------------------------------------------------
                // 1) FIRST GEMINI CALL → Finalize the Arabic sentence
                // -------------------------------------------------------------
                _logger.LogInformation("TextToAudio: Finalizing sentence - {Sentence}", data.Sentence);

                var prompt = $"""
                You are an expert in Arabic linguistics. Your task is to take a string of concatenated 
                Arabic letters (from a real-time sign language translator) and insert spaces to form 
                a coherent sentence. You should also correct minor spelling mistakes based on context.
                Return ONLY the corrected Arabic sentence as plain text.
                Input Text: "{data.Sentence}"
                """;

                var finalizePayload = new
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

                string jsonFinalize = JsonSerializer.Serialize(finalizePayload);
                var finalizeContent = new StringContent(jsonFinalize, Encoding.UTF8, "application/json");

                string finalizeUrl =
                    $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={textToAudioAPIKey}";

                var finalizeResponse = await _httpClient.PostAsync(finalizeUrl, finalizeContent);
                finalizeResponse.EnsureSuccessStatusCode();

                string finalizeResponseBody = await finalizeResponse.Content.ReadAsStringAsync();

                var finalizeModel = JsonSerializer.Deserialize<GeminiResponse>(finalizeResponseBody);
                string finalSentence = finalizeModel?.candidates?.FirstOrDefault()
                                                       ?.content?.parts?.FirstOrDefault()?.text;

                if (string.IsNullOrWhiteSpace(finalSentence))
                {
                    _logger.LogWarning("TextToAudio: Sentence finalization returned empty text");
                    return Ok(ErrorResponse<TTSResponse>("Failed to finalize sentence"));
                }

                // Clean markdown if any
                finalSentence = finalSentence.Trim()
                                             .Replace("```json", "")
                                             .Replace("```", "")
                                             .Trim();

                _logger.LogInformation("TextToAudio: Final sentence → {Sentence}", finalSentence);



                // -------------------------------------------------------------
                // 2) SECOND GEMINI CALL → Generate Audio
                // -------------------------------------------------------------
                _logger.LogInformation("TextToAudio: Generating audio...");

                const string audioApiUrl =
                    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent";

                var audioPayload = new
                {
                    contents = new[]
                    {
                new
                {
                    parts = new[]
                    {
                        new { text = $"Say this in a clear, friendly voice: {finalSentence}" }
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

                var jsonAudio = JsonSerializer.Serialize(audioPayload);
                var audioContent = new StringContent(jsonAudio, Encoding.UTF8, "application/json");

                var audioResponse = await _httpClient.PostAsync($"{audioApiUrl}?key={textToAudioStep2APIKey}", audioContent);
                audioResponse.EnsureSuccessStatusCode();

                var audioJson = await audioResponse.Content.ReadAsStringAsync();
                var audioModel = JsonSerializer.Deserialize<JsonElement>(audioJson);

                var audioPart = audioModel
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0];

                string audioBase64 = audioPart
                    .GetProperty("inlineData").GetProperty("data").GetString();

                string mimeType = audioPart
                    .GetProperty("inlineData").GetProperty("mimeType").GetString();


                // Extract sample rate if included
                int sampleRate = 24000;
                var match = Regex.Match(mimeType ?? "", @"rate=(\d+)");
                if (match.Success)
                    sampleRate = int.Parse(match.Groups[1].Value);


                // Create response object
                var ttsResponse = new TTSResponse
                {
                    AudioData = audioBase64,
                    SampleRate = sampleRate
                };

                _logger.LogInformation("TextToAudio: Audio generation successful");

                return Ok(SuccessResponse(ttsResponse));
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "TextToAudio: API request failure");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Failed communicating with Gemini API {ex.Message.ToString()}.")
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "TextToAudio: Unexpected error");
                return StatusCode(
                    500,
                    ErrorResponse<string>("Unexpected error occurred while processing the request.")
                );
            }
        }

    }
}
