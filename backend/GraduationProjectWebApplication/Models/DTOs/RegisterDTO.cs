using System.ComponentModel.DataAnnotations;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class RegisterDTO
    {
        [Required]
        public string Email { get; set; } = string.Empty;
        [Required]
        public string FullName { get; set; } = string.Empty;
        [Required]
        public string UserName { get; set; } = string.Empty;
        [Required]
        public string Password { get; set; } = string.Empty;
        [Required]
        public string PhoneNumber { get; set; } = string.Empty;
        public IFormFile? UserImage { get; set; }
    }
}
