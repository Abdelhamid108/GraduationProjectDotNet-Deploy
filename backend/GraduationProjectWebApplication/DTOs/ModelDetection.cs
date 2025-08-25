namespace GraduationProjectWebApplication.DTOs
{
    public class ModelDetection
    {
        public List<Detection>? FinalDetections { get; set; }
        public string ErrorMessage { get; set; } = string.Empty;
        public bool IsSuccess { get; set; }

    }
}
