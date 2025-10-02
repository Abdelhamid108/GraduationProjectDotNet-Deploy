using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.LettersModelService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using static System.Net.WebRequestMethods;

namespace GraduationProjectWebApplication.Controllers
{

    [ApiController]
    [Route("api/[controller]")]
    public class SignLanguageTranslatorController : BaseApiController
    {


        private readonly HttpClient _httpClient;
        private readonly string? correctSentenceAPIKey;
        private readonly string? generateAudioAPIKey;
        private readonly IModelService _modelService;
        private readonly ApplicationDbContext _context;
        public SignLanguageTranslatorController(HttpClient httpClient, IConfiguration configuration,
            IModelService modelService, ApplicationDbContext context)
        {

            _httpClient = httpClient;

            correctSentenceAPIKey = configuration.GetSection("APIKeys:CorrectSentenceKey").Value;
            generateAudioAPIKey = configuration.GetSection("APIKeys:GenerateAudioKey").Value;
            _modelService = modelService;
            _context = context;
        }

        [HttpPost]
        public async Task<ActionResult<APIResponseDTO<string>>> TranslateSign([FromBody] FrameData frameData)
        {
            if (string.IsNullOrEmpty(frameData?.ImageData))
            {
                return BadRequest(ErrorResponse<string>("No image data provided."));
            }

            try
            {
                var base64Image = frameData.ImageData.Replace("data:image/jpeg;base64,", "");
                byte[] imageBytes = Convert.FromBase64String(base64Image);

                if (imageBytes == null || imageBytes.Length == 0)
                {
                    return BadRequest(ErrorResponse<string>("Decoded image bytes are null or empty."));
                }


                ModelDetection modelDetection = await _modelService.ModelRunner(imageBytes);

                if (modelDetection.IsSuccess)
                {
                    if (modelDetection.FinalDetections.Any())
                    {
                        var bestDetection = modelDetection.FinalDetections.OrderByDescending(d => d.Confidence).First();

                        //Console.WriteLine($"Debug: Best detection: Arabic='{bestDetection.ClassLabelArabic}', Confidence={bestDetection.Confidence:F4}, At: {DateTime.Now}");
                        //Console.WriteLine($"Debug: Best detection: English='{bestDetection.ClassLabelEnglish}', Confidence={bestDetection.Confidence:F4}, At: {DateTime.Now}");
                        //Console.WriteLine("\n===============================\n");
                        if (bestDetection.Confidence > 0.71)
                        {
                            Console.WriteLine($"Debug: Best detection: Arabic='{bestDetection.ClassLabelArabic}', Confidence={bestDetection.Confidence:F4}, At: {DateTime.Now}");
                            Console.WriteLine($"Debug: Best detection: English='{bestDetection.ClassLabelEnglish}', Confidence={bestDetection.Confidence:F4}, At: {DateTime.Now}");

                            return Ok(SuccessResponse(new { translation = bestDetection.ClassLabelArabic }));

                        }

                        return Ok(SuccessResponse(new { translation = "No sign detected (try adjusting your gesture)." }));



                    }
                    else
                    {
                        return Ok(SuccessResponse(new { translation = "No sign detected." }));

                    }
                }
                else
                {
                    return BadRequest(ErrorResponse<string>(modelDetection.ErrorMessage));

                }
            }
            catch (Exception ex)
            {

                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));

            }
        }

        [HttpPost("finalize-sentence")]
        public async Task<ActionResult<APIResponseDTO<string>>> FinalizeSentence([FromBody] SentenceData data)
        {
            if (string.IsNullOrEmpty(data?.Sentence))
            {
                return BadRequest(ErrorResponse<string>("No sentence data provided."));
            }

            try
            {
                
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


                string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={correctSentenceAPIKey}";

                HttpResponseMessage response = await _httpClient.PostAsync(apiUrl, content);
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"Debug: Gemini API Raw Response for adding spaces and Correction: {responseBody}");


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

                        Console.WriteLine($"Debug: Cleaned JSON response: {jsonText}");

                        //CorrectedResponse correctedResponse = new CorrectedResponse();

                        //correctedResponse.suggestion.correctedSentence = jsonText;

                        if (jsonText != null)
                        {
                            //var claimsidentity = (ClaimsIdentity)User.Identity;
                            //string? userId = claimsidentity.FindFirst(ClaimTypes.NameIdentifier).Value;

                            //UserRecord userRecord = new UserRecord()
                            //{
                            //    UserId = userId,
                            //    FormedSentence = correctedResponse.suggestion.correctedSentence,
                            //};

                            //_context.UserRecords.Add(userRecord);
                            //await _context.SaveChangesAsync();

                            return Ok(SuccessResponse(jsonText));

                        }
                    }
                }
                catch (JsonException jsonEx)
                {
                    Console.Error.WriteLine($"Failed to parse Gemini's JSON response: {jsonEx}");
                    Console.Error.WriteLine($"Response content: {responseBody}");
                }

                return Ok(SuccessResponse("None"));
            }
            catch (System.Exception ex)
            {
                // Log the exception ex
                return StatusCode(500, ErrorResponse<string>("An unexpected error occurred while finalizing the sentence."));
            }
        }


        //[Authorize]
        [HttpPost("CorrectSentence")]
        public async Task<ActionResult<APIResponseDTO<CorrectedResponse>>> CorrectSentence([FromBody] SentenceData sentenceData)
        {
            if (string.IsNullOrEmpty(sentenceData?.Sentence))
            {
                return BadRequest(ErrorResponse<CorrectedResponse>("No sentence provided for correction."));

                //return BadRequest(new { suggestion = new { correctedSentence = "[None]" }, error = "No sentence provided for correction." });
            }

            Console.WriteLine($"Debug: Received sentence for correction: {sentenceData.Sentence}");

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
                Console.WriteLine($"Debug: Gemini API Raw Response for Correction: {responseBody}");

                // Try to parse Gemini's response directly
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

                        Console.WriteLine($"Debug: Cleaned JSON response: {jsonText}");

                        var correctedResponse = JsonSerializer.Deserialize<CorrectedResponse>(jsonText);

                        if (correctedResponse?.suggestion?.correctedSentence != null)
                        {
                            //var claimsidentity = (ClaimsIdentity)User.Identity;
                            //string? userId = claimsidentity.FindFirst(ClaimTypes.NameIdentifier).Value;

                            //UserRecord userRecord = new UserRecord()
                            //{
                            //    UserId = userId,
                            //    FormedSentence = correctedResponse.suggestion.correctedSentence,
                            //};

                            //_context.UserRecords.Add(userRecord);
                            //await _context.SaveChangesAsync();

                            return Ok(SuccessResponse(correctedResponse));

                        }
                    }
                }
                catch (JsonException jsonEx)
                {
                    Console.Error.WriteLine($"Failed to parse Gemini's JSON response: {jsonEx}");
                    Console.Error.WriteLine($"Response content: {responseBody}");
                }

                return Ok(SuccessResponse(new { suggestion = new { correctedSentence = "[None]" } }));

            }
            catch (HttpRequestException httpEx)
            {
                Console.Error.WriteLine($"HTTP Request Error to Gemini API: {httpEx}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"HTTP Request Error to Gemini API: {httpEx.Message}"));

            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error during correction: {ex}");


                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"\"Error during correction: {ex.Message}"));

            }
        }

        //[Authorize]
        [HttpPost("GenerateAudio")]
        public async Task<ActionResult<APIResponseDTO<TTSResponse>>> GenerateAudio([FromBody] TTSRequest request)
        {


            if (string.IsNullOrEmpty(request.Text))
            {
                return BadRequest(ErrorResponse<TTSResponse>("Missing 'text' field in request body."));
            }

            const string ApiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent";

            // The payload remains the same, but we'll use the class-level consts
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

            var client = new HttpClient();
            var jsonPayload = JsonSerializer.Serialize(payload);
            var content = new StringContent(jsonPayload, System.Text.Encoding.UTF8, "application/json");

            try
            {
                // Correctly append the API key to the URL
                var response = await client.PostAsync($"{ApiUrl}?key={generateAudioAPIKey}", content);
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
                var rateMatch = System.Text.RegularExpressions.Regex.Match(mimeType, @"rate=(\d+)");
                if (rateMatch.Success)
                {
                    sampleRate = int.Parse(rateMatch.Groups[1].Value);
                }

                var ttsResponse = new TTSResponse
                {
                    AudioData = audioData,
                    SampleRate = sampleRate
                };

                return Ok(SuccessResponse(ttsResponse));

            }
            catch (HttpRequestException ex)
            {
                Console.WriteLine($"--------------------\n\nError calling Gemini API\n\n----------------------");
                // Handle specific HTTP errors from the Gemini API

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Error calling Gemini API: {ex.Message}"));

            }
            catch (Exception ex)
            {
                // Handle other parsing or general errors
                Console.WriteLine($"--------------------\n\nAn unexpected error occurred\n\n----------------------");

                return StatusCode(
                   (int)HttpStatusCode.InternalServerError,
                   ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }


    }
}