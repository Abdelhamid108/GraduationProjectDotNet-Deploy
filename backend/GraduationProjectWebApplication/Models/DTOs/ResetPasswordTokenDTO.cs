using GraduationProjectWebApplication.Models.Entities;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class ResetPasswordTokenDTO
    { 
        public string Otp { get; set; } = string.Empty;
        public string UserEmail {  get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
    }
}
