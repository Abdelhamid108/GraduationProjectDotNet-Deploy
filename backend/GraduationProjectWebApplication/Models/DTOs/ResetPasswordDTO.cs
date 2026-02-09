namespace GraduationProjectWebApplication.Models.DTOs
{
    public class ResetPasswordDTO
    {
        public string OTP { get; set; } = string.Empty; 
        public string NewPassword { get; set; } = string.Empty;
    }
}
