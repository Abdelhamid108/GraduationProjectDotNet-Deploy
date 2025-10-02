using System.Net;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class APIResponseDTO<T>
    {
        public string ErrorMessage { get; set; } = string.Empty;
        public T? Data { get; set; }
        public bool Success { get; set; }
        public HttpStatusCode StatusCode { get; set; }

    }
}
