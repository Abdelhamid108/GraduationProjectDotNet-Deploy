using GraduationProjectWebApplication.Services.LettersModelService;
using Microsoft.AspNetCore.SignalR;

namespace GraduationProjectWebApplication.Hubs
{
    public class SignHub : Hub
    {
        private readonly IModelService _modelService;

        public SignHub(IModelService modelService)
        {
            _modelService = modelService;
        }

        // The client sends base64 frames here
        public async Task ProcessFrame(string base64Image)
        {
            try
            {
                await Clients.Caller.SendAsync("ReceiveTranslation", "Frame received at " + DateTime.Now.ToLongTimeString());

                Console.WriteLine("\n================================= HUB CONNECTED =============================\n");

                if (string.IsNullOrEmpty(base64Image))
                {
                    await Clients.Caller.SendAsync("ReceiveTranslation", "Invalid image");
                    return;
                }

                byte[] imageBytes = Convert.FromBase64String(
                    base64Image.Replace("data:image/jpeg;base64,", "")
                );

                var modelDetection = await _modelService.ModelRunner(imageBytes);

                if (!modelDetection.IsSuccess || !modelDetection.FinalDetections.Any())
                {
                    await Clients.Caller.SendAsync("ReceiveTranslation", "No sign detected");
                    return;
                }

                var bestDetection = modelDetection.FinalDetections
                                                  .OrderByDescending(d => d.Confidence)
                                                  .First();

                if (bestDetection.Confidence > 0.71)
                {
                    await Clients.Caller.SendAsync("ReceiveTranslation", bestDetection.ClassLabelArabic);
                }
                else
                {
                    await Clients.Caller.SendAsync("ReceiveTranslation", "No confident match");
                }
            }
            catch (Exception ex)
            {
                await Clients.Caller.SendAsync("ReceiveTranslation", $"Error: {ex.Message}");
            }
        }
    }
}
