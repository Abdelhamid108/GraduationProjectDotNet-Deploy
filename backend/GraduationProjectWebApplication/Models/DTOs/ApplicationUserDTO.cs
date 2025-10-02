namespace GraduationProjectWebApplication.Models.DTOs
{
    public class ApplicationUserDTO
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string? ImagePath { get; set; } = string.Empty;

    }
}
