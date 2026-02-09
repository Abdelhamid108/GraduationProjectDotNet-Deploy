using System.Text;

namespace GeminiEndPointsTesting
{
    public class Program
    {
        static async Task Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;
            Console.InputEncoding = Encoding.UTF8;

            string start = Console.ReadLine();

            if (!string.IsNullOrEmpty(start))
            {
                Console.WriteLine("Starting API test... Press Ctrl+C to stop.");

                var test = new Test();
                using var cts = new CancellationTokenSource();

                Console.CancelKeyPress += (_, e) =>
                {
                    e.Cancel = true;     // prevent immediate shutdown
                    cts.Cancel();
                    Console.WriteLine("Stopping...");
                };

                await test.TestFinalizeSentence(cts.Token);

                Console.WriteLine("Test finished.");
            }
        }
    }
}
