namespace GraduationProjectWebApplication.Models.DTOs
{
    public class ResetPasswordDTO
    {
        public Guid TokenId { get; set; }

        public string NewPassword { get; set; } = string.Empty;
    }
}
