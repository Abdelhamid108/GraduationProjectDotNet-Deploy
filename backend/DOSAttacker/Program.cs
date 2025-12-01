using System;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace DOSAttacker
{
    public class Program
    {
        private static readonly HttpClient client = new HttpClient();

        public static async Task Main(string[] args)
        {
            string baseUrl = "https://localhost:5001"; // Change to your backend URL
            string endpoint = "/api/Auth/register-user";

            for (int i = 1; i <= 15; i++)
            {
                // Prepare a unique register DTO for each request
                var registerDTO = new
                {
                    Email = $"test{i}@example.com",
                    FullName = $"Test User {i}",
                    UserName = $"testuser{i}",
                    Password = "Password123!",
                    PhoneNumber = $"010000000{i}"
                };

                try
                {
                    var response = await client.PostAsJsonAsync(baseUrl + endpoint, registerDTO);

                    if (response.IsSuccessStatusCode)
                    {
                        Console.WriteLine($"Request {i}: Success ({(int)response.StatusCode})");
                    }
                    else
                    {
                        string content = await response.Content.ReadAsStringAsync();
                        Console.WriteLine($"Request {i}: Failed ({(int)response.StatusCode}) - {content}");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Request {i}: Exception - {ex.Message}");
                }
            }

            Console.WriteLine("Test complete.");
        }
    }
}
