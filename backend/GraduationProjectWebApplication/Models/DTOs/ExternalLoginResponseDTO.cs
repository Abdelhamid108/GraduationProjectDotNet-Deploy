namespace GraduationProjectWebApplication.Models.DTOs
{
    public class ExternalLoginResponseDTO
    {
        public TokenResponseDTO TokenResponseDTO {  get; set; }
        public string Base64Image { get; set; } = string.Empty;
    }
}
