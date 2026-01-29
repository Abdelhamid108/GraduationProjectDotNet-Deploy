using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Text.Json;

namespace ApiLoadTester
{
    class Program
    {
        private static readonly string apiUrl = "https://localhost:5001/api/signlanguagetranslator";
        private static readonly string base64Image =
            "data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

        static async Task Main()
        {
            Console.WriteLine("🚀 Starting API tests...\n");

            // Functional test first
            await RunFunctionalTest();

            // Then load test
            await RunLoadTest(600, 200); // 600 requests, 200ms apart
        }

        private static async Task RunFunctionalTest()
        {
            Console.WriteLine("🧪 Running functional test (single API request)...");

            using var client = new HttpClient();
            var data = new { imageData = base64Image };
            var content = new StringContent(JsonSerializer.Serialize(data), Encoding.UTF8, "application/json");

            var sw = Stopwatch.StartNew();
            var response = await client.PostAsync(apiUrl, content);
            sw.Stop();

            string body = await response.Content.ReadAsStringAsync();

            Console.WriteLine($"✅ Status: {response.StatusCode}");
            Console.WriteLine($"⏱️ Time: {sw.ElapsedMilliseconds} ms");
            Console.WriteLine($"📦 Response: {body}");
            Console.WriteLine();
        }

        private static async Task RunLoadTest(int totalRequests, int delayMs)
        {
            Console.WriteLine($"💥 Running load test: {totalRequests} requests, {delayMs}ms apart...\n");

            using var client = new HttpClient();

            var data = new { imageData = base64Image };
            var json = JsonSerializer.Serialize(data);

            int successCount = 0;
            int failCount = 0;

            var stopwatch = Stopwatch.StartNew();
            var tasks = Enumerable.Range(1, totalRequests).Select(async i =>
            {
                try
                {
                    var content = new StringContent(json, Encoding.UTF8, "application/json");
                    var response = await client.PostAsync(apiUrl, content);
                    if (response.IsSuccessStatusCode)
                    {
                        Interlocked.Increment(ref successCount);
                    }
                    else
                    {
                        Interlocked.Increment(ref failCount);
                    }
                }
                catch
                {
                    Interlocked.Increment(ref failCount);
                }

                await Task.Delay(delayMs);
            });

            await Task.WhenAll(tasks);
            stopwatch.Stop();

            Console.WriteLine("\n=== 🧾 Load Test Summary ===");
            Console.WriteLine($"✅ Success: {successCount}");
            Console.WriteLine($"❌ Failed:  {failCount}");
            Console.WriteLine($"⏱️ Total time: {stopwatch.Elapsed.TotalSeconds:F2}s");
            Console.WriteLine($"⚡ Avg requests/sec: {(successCount + failCount) / stopwatch.Elapsed.TotalSeconds:F2}");
            Console.WriteLine("============================");

            Console.WriteLine("\n💡 Tip: Run `docker stats` in another terminal to monitor memory live.\n");
        }
    }
}
