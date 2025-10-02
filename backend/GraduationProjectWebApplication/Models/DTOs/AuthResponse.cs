using System.Net;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class AuthResponse<T>
    {
        public bool IsSuccess { get; set; } = true;

        public string ErrorMessage { get; set; } = string.Empty;
        public T? Result { get; set; }
    }
}
