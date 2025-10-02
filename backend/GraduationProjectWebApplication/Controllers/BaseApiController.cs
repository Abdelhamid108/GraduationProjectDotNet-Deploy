using GraduationProjectWebApplication.Models.DTOs;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Net;

namespace GraduationProjectWebApplication.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BaseApiController : ControllerBase
    {
        protected APIResponseDTO<T> SuccessResponse<T>(T data, HttpStatusCode statusCode = HttpStatusCode.OK)
        {
            return new APIResponseDTO<T>
            {
                Success = true,
                Data = data,
                StatusCode = statusCode
            };
        }

        protected APIResponseDTO<T> ErrorResponse<T>(string errorMessage, HttpStatusCode statusCode = HttpStatusCode.BadRequest)
        {
            return new APIResponseDTO<T>
            {
                Success = false,
                ErrorMessage = errorMessage,
                StatusCode = statusCode
            };
        }
    }
}
