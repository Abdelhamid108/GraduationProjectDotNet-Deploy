using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace GeminiEndPointsTesting
{
    using GraduationProjectWebApplication.Models.DTOs;
    using System.Net;
    using System.Text;
    using System.Text.Json;

    public class Test
    {
        static readonly string baseUrl = "https://localhost:5001/api/SignLanguageTranslator/";
        private readonly HttpClient _httpClient;

        public Test()
        {
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(baseUrl)
            };
        }

        public async Task TestFinalizeSentence(CancellationToken cancellationToken)
        {
            int counter = 1;
            string url = "finalize-sentence";

            while (!cancellationToken.IsCancellationRequested)
            {
                var payload = new
                {
                    Sentence = $"انااسميمروان {counter} "
                };

                var json = JsonSerializer.Serialize(payload);
                using var content = new StringContent(json, Encoding.UTF8, "application/json");

                try
                {
                    using HttpResponseMessage response =
                        await _httpClient.PostAsync(url, content, cancellationToken);

                    var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);

                    var apiResponse =
                        JsonSerializer.Deserialize<APIResponseDTO<string>>(
                            responseJson,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                        );

                    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Request #{counter}");

                    if (apiResponse?.Success == true)
                    {
                        Console.WriteLine($"✅ Success: {apiResponse.Data}");
                    }
                    else
                    {
                        Console.WriteLine($"❌ Error: {apiResponse?.ErrorMessage}");
                    }

                    Console.WriteLine(apiResponse.StatusCode);

                    Console.WriteLine(new string('-', 50));
                }
                catch (TaskCanceledException)
                {
                    Console.WriteLine("⏹ Request loop stopped.");
                    break;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"🔥 Exception: {ex.Message}");
                }

                counter++;

                // ⏱ wait 30 seconds
                await Task.Delay(TimeSpan.FromSeconds(5), cancellationToken);
            }
        }
    }
}
