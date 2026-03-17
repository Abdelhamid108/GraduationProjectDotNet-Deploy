using GraduationProjectWebApplication.Models.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.CognitiveServices.Speech;
using Microsoft.CognitiveServices.Speech.Audio;
using Newtonsoft.Json;
using System.Diagnostics;
using System.Net;
using System.Net.Http.Headers;
using System.Runtime.InteropServices;
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
        private readonly string? _azureSpeechKey;
        private readonly ILogger<ArabicLanguageTranslatorController> _logger;
        public ArabicLanguageTranslatorController(HttpClient httpClient, IConfiguration configuration, ILogger<ArabicLanguageTranslatorController> logger)
        {
            _httpClient = httpClient;
            generateTextFromAudioAPIKey = configuration["GENERATE_TEXT_FROM_AUDIO_KEY"];
            generateTextFromAudioBackupAPIKey = configuration["GENERATE_TEXT_FROM_AUDIO_BACKUP_KEY"];
            _azureSpeechKey = configuration["HARDWARE_TTS_KEY"];
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

                string jsonPayload = JsonConvert.SerializeObject(requestPayload);
                var httpContent = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                _logger.LogInformation("Sending request to Gemini API.");

                string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{activeModel}:generateContent";

                var httpRequest = new HttpRequestMessage(HttpMethod.Post, apiUrl);
                httpRequest.Headers.Add("x-goog-api-key", generateTextFromAudioAPIKey);
                httpRequest.Content = httpContent;

                HttpResponseMessage response = await _httpClient.SendAsync(httpRequest);
                if (response.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    _logger.LogWarning("Gemini API rate limit hit. Retrying request...");

                    var retryRequest = new HttpRequestMessage(HttpMethod.Post, apiUrl);
                    retryRequest.Headers.Add("x-goog-api-key", generateTextFromAudioBackupAPIKey);
                    retryRequest.Content = httpContent;

                    response = await _httpClient.SendAsync(retryRequest);
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


        [HttpPost("azure-audio-to-text")]
        [EnableRateLimiting("GeminiLimiter")]
        public async Task<ActionResult<APIResponseDTO<string>>> AzureAudioToText([FromBody] TranscriptionRequest request)
        {
            _logger.LogInformation("AzureAudioToText called. AudioData length: {A}, MimeType: {M}",
                request.AudioData?.Length ?? 0, request.MimeType ?? "null");

            if (string.IsNullOrEmpty(request.AudioData) || string.IsNullOrEmpty(request.MimeType))
            {
                _logger.LogWarning("Invalid request: AudioData or MimeType is missing.");
                return BadRequest(ErrorResponse<string>("Audio data or MIME type not provided."));
            }

            const int maxBase64Length = 14_000_000;
            if (request.AudioData.Length > maxBase64Length)
            {
                _logger.LogWarning("AudioData exceeds size limit. Size: {Size}", request.AudioData.Length);
                return BadRequest(ErrorResponse<string>("Audio data exceeds the maximum allowed size."));
            }

            byte[] audioBytes;
            try
            {
                audioBytes = Convert.FromBase64String(request.AudioData);
            }
            catch (FormatException ex)
            {
                _logger.LogWarning(ex, "AudioData is not valid base64.");
                return BadRequest(ErrorResponse<string>("AudioData is not valid base64-encoded content."));
            }

            try
            {
                // Azure REST API only accepts WAV PCM or OGG Opus.
                // We always convert to WAV to guarantee compatibility.
                byte[] wavBytes = await ConvertToWavAsync(audioBytes);
                _logger.LogInformation("Audio converted to WAV. Size: {Size} bytes", wavBytes.Length);

                // Exact Content-Type required by Azure docs
                const string azureContentType = "audio/wav; codecs=audio/pcm; samplerate=16000";
                const string azureUrl = "https://eastus.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=ar-EG";

                using var content = new ByteArrayContent(wavBytes);
                content.Headers.TryAddWithoutValidation("Content-Type", azureContentType);

                using var httpRequest = new HttpRequestMessage(HttpMethod.Post, azureUrl);
                httpRequest.Headers.Add("Ocp-Apim-Subscription-Key", _azureSpeechKey);
                httpRequest.Headers.Add("Accept", "application/json");
                httpRequest.Content = content;

                _logger.LogInformation("Sending WAV to Azure Speech REST API.");
                HttpResponseMessage response = await _httpClient.SendAsync(httpRequest);
                string responseBody = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Azure response: {Status} — {Body}", response.StatusCode, responseBody);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Azure Speech API error. Status: {Status}, Body: {Body}",
                        response.StatusCode, responseBody);
                    return StatusCode(
                        (int)HttpStatusCode.BadGateway,
                        ErrorResponse<string>($"Azure Speech API error: {response.StatusCode}"));
                }

                var result = JsonConvert.DeserializeObject<AzureSpeechResponse>(responseBody);

                if (result?.RecognitionStatus == "Success" && !string.IsNullOrEmpty(result.DisplayText))
                {
                    _logger.LogInformation("Transcription successful: {Text}", result.DisplayText);
                    return Ok(SuccessResponse(result.DisplayText));
                }

                _logger.LogWarning("Recognition status: {Status}", result?.RecognitionStatus);
                return StatusCode(
                    (int)HttpStatusCode.UnprocessableEntity,
                    ErrorResponse<string>($"Speech recognition was not successful: {result?.RecognitionStatus}"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in AzureAudioToText.");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        /// <summary>
        /// Converts any audio format to 16kHz 16-bit mono WAV.
        /// Uses NAudio on Windows, FFmpeg on Linux.
        /// </summary>
        private async Task<byte[]> ConvertToWavAsync(byte[] inputAudio)
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                return ConvertToWavWindows(inputAudio);
            else
                return await ConvertToWavLinuxAsync(inputAudio);
        }

        private static byte[] ConvertToWavWindows(byte[] inputAudio)
        {
            string tempInput = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.webm");
            try
            {
                System.IO.File.WriteAllBytes(tempInput, inputAudio);

                using var reader = new NAudio.Wave.MediaFoundationReader(tempInput);
                using var resampler = new NAudio.Wave.MediaFoundationResampler(
                    reader,
                    new NAudio.Wave.WaveFormat(16000, 16, 1)
                );
                using var ms = new MemoryStream();
                NAudio.Wave.WaveFileWriter.WriteWavFileToStream(ms, resampler);
                return ms.ToArray();
            }
            finally
            {
                if (System.IO.File.Exists(tempInput))
                    System.IO.File.Delete(tempInput);
            }
        }

        private async Task<byte[]> ConvertToWavLinuxAsync(byte[] inputAudio)
        {
            var psi = new ProcessStartInfo
            {
                FileName = "ffmpeg",
                Arguments = "-y -i pipe:0 -ar 16000 -ac 1 -acodec pcm_s16le -f wav pipe:1",
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(psi)
                ?? throw new InvalidOperationException("ffmpeg could not be started.");

            var writeTask = Task.Run(async () =>
            {
                await process.StandardInput.BaseStream.WriteAsync(inputAudio);
                process.StandardInput.BaseStream.Close();
            });

            var readOutputTask = Task.Run(async () =>
            {
                using var ms = new MemoryStream();
                await process.StandardOutput.BaseStream.CopyToAsync(ms);
                return ms.ToArray();
            });

            var stderrTask = process.StandardError.ReadToEndAsync();

            await Task.WhenAll(writeTask, readOutputTask, stderrTask);
            await process.WaitForExitAsync();

            if (process.ExitCode != 0)
            {
                _logger.LogError("FFmpeg failed. Stderr: {Stderr}", await stderrTask);
                throw new InvalidOperationException($"FFmpeg failed with exit code {process.ExitCode}.");
            }

            return await readOutputTask;
        }

    }
}

