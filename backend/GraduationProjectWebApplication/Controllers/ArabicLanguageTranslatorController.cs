using GraduationProjectWebApplication.Models.DTOs;
using Microsoft.AspNetCore.Mvc;
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
        public ArabicLanguageTranslatorController(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            generateTextFromAudioAPIKey = configuration.GetSection("APIKeys:generateTextFromAudioAPIKey").Value;
        }

        [HttpPost("text-to-sign")]
        public async Task<ActionResult<APIResponseDTO<List<List<string>>>>> TextToSign([FromBody] TextToSignDTO textToSignDTO)
        {


            if (textToSignDTO == null || string.IsNullOrEmpty(textToSignDTO.Text))
            {
                return BadRequest(ErrorResponse<List<List<string>>>("No text provided."));
            }


            Dictionary<char, string> lettersDictionary = GraduationProject.StaticDetails.Dictionaries.lettersDictionary;

            List<List<string>> images = new List<List<string>>();

            try
            {
                string[] words = textToSignDTO.Text.Split(' ', StringSplitOptions.RemoveEmptyEntries);

                foreach (string word in words)
                {
                    List<string> letterImages = new List<string>();

                    foreach (char letter in word)
                    {
                        if (lettersDictionary.TryGetValue(letter, out string imagePath))
                        {
                            Console.WriteLine(imagePath);
                            byte[] imageBytes = System.IO.File.ReadAllBytes(imagePath);
                            string base64 = Convert.ToBase64String(imageBytes);
                            string imgData = $"data:image/png;base64,{base64}";

                            letterImages.Add(imgData);
                        }
                        else
                        {
                            // Optional: handle missing letters
                            Console.WriteLine($"Letter '{letter}' not found in dictionary.");
                        }
                    }

                    images.Add(letterImages);
                }

                return Ok(SuccessResponse(images));

            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in TextToSign: {ex}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<List<List<string>>>($"An error occurred: {ex.Message}"));

            }
        }

        [HttpPost("audio-to-text")]
        public async Task<ActionResult<APIResponseDTO<string>>> AudioToText([FromBody] TranscriptionRequest request)
        {
            if (string.IsNullOrEmpty(request.AudioData) || string.IsNullOrEmpty(request.MimeType))
            {
                return BadRequest(ErrorResponse<string>("Audio data or MIME type not provided.S"));
            }

            // In a real application, the API key should be stored securely.
            string apiKey = generateTextFromAudioAPIKey;
            string apiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key={apiKey}";
            const string prompt = "Please provide a complete and accurate transcription of the human speech in the audio in Arabic." +
                " Do not include any descriptions of non-speech sounds or background noise.";

            try
            {
                // Create the request payload using the new DTO properties.
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

                string jsonPayload = JsonConvert.SerializeObject(requestPayload);
                var httpContent = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                HttpResponseMessage response = await _httpClient.PostAsync(apiUrl, httpContent);
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();
                dynamic geminiResponse = JsonConvert.DeserializeObject(responseBody);

                string? transcribedText = geminiResponse?.candidates?[0]?.content?.parts?[0]?.text;

                if (!string.IsNullOrEmpty(transcribedText))
                {
                    return Ok(SuccessResponse(transcribedText));
                }
                else
                {
                    Console.WriteLine("Gemini API did not return a valid transcription.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>($"Gemini API did not return a valid transcription."));

                }
            }
            catch (HttpRequestException ex)
            {
                Console.WriteLine($"Error calling Gemini API: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.BadGateway,
                    ErrorResponse<string>($"Error calling Gemini API: {ex.Message}"));

            }
            catch (JsonException ex)
            {
                Console.WriteLine($"Error parsing Gemini API response: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"Error parsing Gemini API response: {ex.Message}"));
            }
            catch (Exception ex)
            {

                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpGet("letters-keyboard")]
        public async Task<ActionResult<APIResponseDTO<string>>> LettersKeyboard([FromQuery] char letter)
        {
            if (letter == default)
            {
                return BadRequest(ErrorResponse<string>("Letter parameter is required."));
            }

            try
            {
                Dictionary<char, string> lettersDictionary = GraduationProject.StaticDetails.Dictionaries.lettersDictionary;

                if (lettersDictionary.TryGetValue(letter, out string imagePath))
                {
                    Console.WriteLine(imagePath);
                    byte[] imageBytes = await System.IO.File.ReadAllBytesAsync(imagePath);
                    string base64 = Convert.ToBase64String(imageBytes);
                    string imgData = $"data:image/png;base64,{base64}";

                    return Ok(SuccessResponse(imgData));


                    //return Ok(new { imageData = $"data:image/png;base64,{base64}" });
                }
                else
                {
                    Console.WriteLine($"Letter '{letter}' not found in dictionary.");

                    return BadRequest(ErrorResponse<string>($"Letter '{letter}' not found in dictionary."));

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

    }
}

