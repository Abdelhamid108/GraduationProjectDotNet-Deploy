namespace GraduationProjectWebApplication.Models.Entities
{
    public class ResetPasswordToken
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string IdentityToken { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string OtpHash { get; set; } = string.Empty;
        public ApplicationUser User { get; set; }
        public DateTime ExpiresAt { get; set; }
        public bool IsUsed { get; set; } = false;
    }
}
