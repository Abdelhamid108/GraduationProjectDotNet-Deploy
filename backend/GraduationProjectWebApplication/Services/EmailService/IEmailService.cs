using GraduationProjectWebApplication.Models.DTOs;

namespace GraduationProjectWebApplication.Services.EmailService
{
    public interface IEmailService
    {
        Task<bool> SendMailAsync(MailData mailData);
    }
}
