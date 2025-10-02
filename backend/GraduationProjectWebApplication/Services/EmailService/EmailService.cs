using GraduationProjectWebApplication.Configuration;
using GraduationProjectWebApplication.Models.DTOs;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using MailKit.Net.Smtp;

namespace GraduationProjectWebApplication.Services.EmailService
{
    public class EmailService : IEmailService
    {
        private readonly MailSettings _mailSettings;

        public EmailService(IOptions<MailSettings> options)
        {
            _mailSettings = options.Value;
        }

        public async Task<bool> SendMailAsync(MailData mailData)
        {
            try
            {
                // Build email message
                var email = new MimeMessage();
                email.From.Add(new MailboxAddress(_mailSettings.Name, _mailSettings.EmailId));
                email.To.Add(new MailboxAddress(mailData.EmailToName, mailData.EmailToId));
                email.Subject = mailData.EmailSubject;

                var builder = new BodyBuilder { TextBody = mailData.EmailBody };
                email.Body = builder.ToMessageBody();

                using var client = new SmtpClient();

                // Connect asynchronously with STARTTLS (port 587)
                await client.ConnectAsync(_mailSettings.Host, _mailSettings.Port, SecureSocketOptions.StartTls);

                // Authenticate with full email and App Password
                await client.AuthenticateAsync(_mailSettings.EmailId, _mailSettings.Password);

                // Send email asynchronously
                await client.SendAsync(email);

                await client.DisconnectAsync(true);

                return true;
            }
            catch (Exception ex)
            {
                // Log the exception if needed
                Console.WriteLine($"Email send error: {ex.Message}");
                return false;
            }
        }
    }
}
