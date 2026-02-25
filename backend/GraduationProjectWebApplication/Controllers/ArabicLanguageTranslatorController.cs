using GraduationProjectWebApplication.Models.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Newtonsoft.Json;
using System.Net;
using System.Text;

namespace GraduationProjectWebApplication.Controllers
{


    [Route("api/[controller]")]
    [ApiController]
    public class ArabicLanguageTranslatorController : BaseApiController
    {
        private readonly HttpClient _httpClient;
        private readonly string? generateTextFromAudioAPIKey;
        private readonly string? generateTextFromAudioBackupAPIKey;
        private readonly ILogger<ArabicLanguageTranslatorController> _logger;
        public ArabicLanguageTranslatorController(HttpClient httpClient, IConfiguration configuration, ILogger<ArabicLanguageTranslatorController> logger)
        {
            _httpClient = httpClient;
            generateTextFromAudioAPIKey = configuration["GENERATE_TEXT_FROM_AUDIO_KEY"];
            generateTextFromAudioBackupAPIKey = configuration["GENERATE_TEXT_FROM_AUDIO_BACKUP_KEY"];
            _logger = logger;
        }

        [HttpPost("text-to-sign")]
        [EnableRateLimiting("ArabicLimiter")]
        public async Task<ActionResult<APIResponseDTO<List<List<string>>>>> TextToSign([FromBody] TextToSignDTO textToSignDTO)
        {
            _logger.LogInformation("TextToSign endpoint called.");

            if (textToSignDTO == null || string.IsNullOrEmpty(textToSignDTO.Text))
            {
                _logger.LogWarning("Invalid request: No text provided.");
                return BadRequest(ErrorResponse<List<List<string>>>("No text provided."));
            }

            Dictionary<char, string> lettersDictionary = GraduationProject.StaticDetails.Dictionaries.lettersDictionary;

            List<List<string>> images = new List<List<string>>();

            try
            {
                string[] words = textToSignDTO.Text.Split(' ', StringSplitOptions.RemoveEmptyEntries);

                _logger.LogInformation("Processing {WordCount} words.", words.Length);

                foreach (string word in words)
                {
                    _logger.LogInformation("Processing word: {Word}", word);

                    List<string> letterImages = new List<string>();

                    foreach (char letter in word)
                    {
                        if (lettersDictionary.TryGetValue(letter, out string imagePath))
                        {
                            _logger.LogDebug("Found image for letter '{Letter}' at path {Path}", letter, imagePath);

                            byte[] imageBytes = System.IO.File.ReadAllBytes(imagePath);
                            string base64 = Convert.ToBase64String(imageBytes);
                            string imgData = $"data:image/png;base64,{base64}";

                            letterImages.Add(imgData);
                        }
                        else
                        {
                            _logger.LogWarning("Letter '{Letter}' not found in dictionary.", letter);
                        }
                    }

                    images.Add(letterImages);
                }

                _logger.LogInformation("TextToSign completed successfully. Generated {WordCount} word image groups.", images.Count);

                return Ok(SuccessResponse(images));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while processing TextToSign request.");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<List<List<string>>>($"An error occurred: {ex.Message}")
                );
            }
        }

        [HttpPost("audio-to-text")]
        [EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<string>>> AudioToText([FromBody] TranscriptionRequest request)
        {
            _logger.LogInformation("AudioToText endpoint called.");

            if (string.IsNullOrEmpty(request.AudioData) || string.IsNullOrEmpty(request.MimeType))
            {
                _logger.LogWarning("Invalid request: AudioData or MimeType is missing.");
                return BadRequest(ErrorResponse<string>("Audio data or MIME type not provided."));
            }

            const string prompt = "Please provide a complete and accurate transcription of the human speech in the audio in Arabic." +
                " Do not include any descriptions of non-speech sounds or background noise.";

            try
            {
                _logger.LogInformation("Preparing Gemini request. MimeType: {MimeType}, AudioSize: {Size}",
                    request.MimeType,
                    request.AudioData?.Length ?? 0);

                var requestPayload = new GeminiRequest
                {
                    contents = new[]
                    {
                new AudioContent
                {
                    parts = new AudioPart[]
                    {
                        new AudioPart { text = prompt },
                        new AudioPart
                        {
                            inlineData = new InlineData
                            {
                                mimeType = request.MimeType,
                                data = request.AudioData,
                            }
                        }
                    }
                }
            }
                };

                // Recommended for high-speed, high-accuracy audio tasks in 2026
                const string activeModel = "gemini-3-flash-preview";

                string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{activeModel}:generateContent?key={generateTextFromAudioAPIKey}"; 
                string jsonPayload = JsonConvert.SerializeObject(requestPayload);
                var httpContent = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                _logger.LogInformation("Sending request to Gemini API.");

                HttpResponseMessage response = await _httpClient.PostAsync(apiUrl, httpContent);

                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    _logger.LogWarning("Gemini API rate limit hit. Retrying request...");

                    apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{activeModel}:generateContent?key={generateTextFromAudioBackupAPIKey}";

                    response = await _httpClient.PostAsync(apiUrl, httpContent);
                }

                _logger.LogInformation("Gemini API responded with status code: {StatusCode}", response.StatusCode);

                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                _logger.LogDebug("Gemini raw response: {Response}", responseBody);

                dynamic geminiResponse = JsonConvert.DeserializeObject(responseBody);

                string? transcribedText = geminiResponse?.candidates?[0]?.content?.parts?[0]?.text;

                if (!string.IsNullOrEmpty(transcribedText))
                {
                    _logger.LogInformation("Transcription successful. Length: {Length}", transcribedText.Length);
                    return Ok(SuccessResponse(transcribedText));
                }
                else
                {
                    _logger.LogError("Gemini API returned empty transcription.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>("Gemini API did not return a valid transcription."));
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "HTTP error while calling Gemini API.");

                return StatusCode(
                    (int)HttpStatusCode.BadGateway,
                    ErrorResponse<string>($"Error calling Gemini API: {ex.Message}"));
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "Error parsing Gemini API response.");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Error parsing Gemini API response: {ex.Message}"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in AudioToText.");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpGet("letters-keyboard")]
        [EnableRateLimiting("ArabicLimiter")]
        public async Task<ActionResult<APIResponseDTO<string>>> LettersKeyboard([FromQuery] char letter)
        {
            _logger.LogInformation("LettersKeyboard endpoint called with letter: {Letter}", letter);

            if (letter == default)
            {
                _logger.LogWarning("Invalid request: Letter parameter is missing or default.");
                return BadRequest(ErrorResponse<string>("Letter parameter is required."));
            }

            try
            {
                Dictionary<char, string> lettersDictionary =
                    GraduationProject.StaticDetails.Dictionaries.lettersDictionary;

                if (lettersDictionary.TryGetValue(letter, out string imagePath))
                {
                    _logger.LogDebug("Image path found for letter '{Letter}': {Path}", letter, imagePath);

                    if (!System.IO.File.Exists(imagePath))
                    {
                        _logger.LogError("Image file does not exist at path: {Path}", imagePath);

                        return StatusCode(
                            (int)HttpStatusCode.InternalServerError,
                            ErrorResponse<string>("Image file not found on server."));
                    }

                    byte[] imageBytes = await System.IO.File.ReadAllBytesAsync(imagePath);
                    string base64 = Convert.ToBase64String(imageBytes);
                    string imgData = $"data:image/png;base64,{base64}";

                    _logger.LogInformation("Successfully generated image for letter '{Letter}'.", letter);

                    return Ok(SuccessResponse(imgData));
                }
                else
                {
                    _logger.LogWarning("Letter '{Letter}' not found in dictionary.", letter);

                    return BadRequest(
                        ErrorResponse<string>($"Letter '{letter}' not found in dictionary."));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred in LettersKeyboard for letter '{Letter}'.", letter);

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

    }
}

