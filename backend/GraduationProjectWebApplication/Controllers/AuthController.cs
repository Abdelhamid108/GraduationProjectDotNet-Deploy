using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.AuthenticationSerivce;
using GraduationProjectWebApplication.Services.EmailService;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Security.Claims;

namespace GraduationProjectWebApplication.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : BaseApiController
    {

        private readonly IAuthService _authService;
        private readonly IEmailService _emailService;
        public AuthController(IAuthService authService, IEmailService emailService)
        {
            _authService = authService;
            _emailService = emailService;
        }
        [HttpPost("register-user")]
        public async Task<ActionResult<APIResponseDTO<ApplicationUserDTO>>> RegisterAsync(RegisterDTO registerDTO)
        {
            AuthResponse<ApplicationUserDTO>? authResponse = new AuthResponse<ApplicationUserDTO>();

            try
            {
                if (registerDTO == null)
                {
                    return BadRequest(ErrorResponse<ApplicationUserDTO>(authResponse.ErrorMessage));
                }
                else
                {
                    authResponse = await _authService.RegisterAsync(registerDTO);

                    if (authResponse != null)
                    {
                        if (!authResponse.IsSuccess)
                        {
                            return BadRequest(ErrorResponse<ApplicationUserDTO>(authResponse.ErrorMessage));
                        }
                        else
                        {
                            return Ok(SuccessResponse<ApplicationUserDTO>(authResponse.Result));
                        }
                    }
                    else
                    {
                        Console.WriteLine($"An unexpected error occurred");

                        return StatusCode(
                            (int)HttpStatusCode.InternalServerError,
                            ErrorResponse<ApplicationUserDTO>($"An unexpected error occurred"));
                    }

                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<ApplicationUserDTO>($"An unexpected error occurred: {ex.Message}"));
            }

        }


        [HttpPost("login-user")]
        public async Task<ActionResult<APIResponseDTO<TokenResponseDTO>>> LoginAsync(LoginDTO loginDTO)
        {
            AuthResponse<TokenResponseDTO>? authResponse = new AuthResponse<TokenResponseDTO>();

            try
            {
                if (loginDTO == null)
                {
                    return BadRequest(ErrorResponse<TokenResponseDTO>("Invaild Credentials"));
                }
                else
                {
                    authResponse = await _authService.LoginAsync(loginDTO);

                    if (authResponse != null)
                    {
                        if (authResponse.IsSuccess == false)
                        {
                            return BadRequest(ErrorResponse<TokenResponseDTO>(authResponse.ErrorMessage));
                        }
                        else
                        {
                            return Ok(SuccessResponse<TokenResponseDTO>(authResponse.Result));
                        }
                    }
                    else
                    {
                        Console.WriteLine($"An unexpected error occurred");

                        return StatusCode(
                            (int)HttpStatusCode.InternalServerError,
                            ErrorResponse<bool>($"An unexpected error occurred"));
                    }
                }

            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }

        }

        [HttpPost("refresh-tokens")]
        public async Task<ActionResult<APIResponseDTO<TokenResponseDTO>>> RefreshTokens(TokenRequestDTO tokenRequestDTO)
        {
            try
            {
                TokenResponseDTO? tokenResponse = await _authService.RefreshTokensAsync(tokenRequestDTO);

                if (tokenResponse == null || tokenResponse.RefreshToken == null || tokenResponse.AccessToken == null)
                    return Unauthorized(ErrorResponse<TokenResponseDTO>("Invaild Refresh Token !"));

                return Ok(SuccessResponse<TokenResponseDTO>(tokenResponse));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpPost("get-reset-password-token")]
        public async Task<ActionResult<APIResponseDTO<bool>>> GetResetPasswordToken(string Email)
        {

            if (string.IsNullOrEmpty(Email))
                return BadRequest(ErrorResponse<ResetPasswordToken>("Invaild Email"));

            try
            {
                AuthResponse<ResetPasswordToken>? authResponse = new AuthResponse<ResetPasswordToken>();

                authResponse = await _authService.GenerateResetPasswordTokenAsync(Email);

                if (authResponse != null)
                {
                    if (!authResponse.IsSuccess) return BadRequest(ErrorResponse<bool>(authResponse.ErrorMessage));

                    ResetPasswordToken? resetPasswordToken = authResponse.Result;


                    MailData mailData = new MailData()
                    {
                        EmailToId = Email,
                        EmailToName = resetPasswordToken.User.UserName,
                        EmailSubject = "Reset Your Password",
                        EmailBody = $@"
                        Hello {resetPasswordToken.User.UserName},

                        You recently requested to reset your password.

                        Here is your password reset token:

                        {resetPasswordToken.Id}

                        This token will expire in 15 minutes and can only be used once.

                        To complete the password reset, copy this token and paste it into the reset form in the app or website.

                        If you did not request this, please ignore this message.

                        Thanks,  
                        Ema2a Team"
                    };

                    bool result = await _emailService.SendMailAsync(mailData);

                    if (!result)
                    {
                        Console.WriteLine($"An unexpected error occurred");

                        return StatusCode(
                            (int)HttpStatusCode.InternalServerError,
                            ErrorResponse<bool>($"An unexpected error occurred"));
                    }

                    return Ok(SuccessResponse<bool>(true));
                }
                else
                {
                    Console.WriteLine($"An unexpected error occurred");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<bool>($"An unexpected error occurred"));
                }


            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<ResetPasswordToken>($"An unexpected error occurred: {ex.Message}"));
            }

        }

        [HttpPost("reset-password")]
        public async Task<ActionResult<APIResponseDTO<bool>>> ResetPassword(ResetPasswordDTO resetPasswordDTO)
        {
            try
            {
                if ( String.IsNullOrEmpty(resetPasswordDTO.NewPassword) || resetPasswordDTO.TokenId == null)
                    return BadRequest(ErrorResponse<bool>("Invaild token or password"));

                AuthResponse<bool>? authResponse = new AuthResponse<bool>();


                authResponse = await _authService.ResetPasswordAsync(resetPasswordDTO);

                if(authResponse != null)
                {
                    if (!authResponse.IsSuccess)
                        return BadRequest(ErrorResponse<bool>(authResponse.ErrorMessage));

                    return Ok(SuccessResponse<bool>(authResponse.Result));

                }
                else
                {
                    Console.WriteLine($"An unexpected error occurred");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<ResetPasswordToken>($"An unexpected error occurred"));

                }
            }
            catch(Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("change-password")]
        public async Task<ActionResult<APIResponseDTO<bool>>> ChangePassword([FromForm] ChangePasswordDTO changePasswordDTO)
        {
            try
            {
                string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                AuthResponse<bool>? authResponse = new AuthResponse<bool>();


                authResponse = await _authService.ChangePasswordAsync(userId, changePasswordDTO);

                if(authResponse != null)
                {
                    if (!authResponse.IsSuccess)
                    {
                        return BadRequest(ErrorResponse<bool>(authResponse.ErrorMessage));
                    }

                    return Ok(SuccessResponse<bool>(authResponse.Result));
                }
                else
                {
                    Console.WriteLine($"An unexpected error occurred");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<ResetPasswordToken>($"An unexpected error occurred"));
                }
            }
            catch(Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }
    
        [HttpGet("login-google")]
        public IActionResult LoginWithGoogle()
        {
            var redirectUrl = Url.Action("GoogleCallback", "Auth");
            var properties = new AuthenticationProperties { RedirectUri = redirectUrl };
            return Challenge(properties, GoogleDefaults.AuthenticationScheme);
        }

        [HttpGet("google-callback")]
        public async Task<ActionResult<APIResponseDTO<ExternalLoginResponseDTO>>> GoogleCallback()
        {
            try
            {
                // Use "External" instead of CookieAuthenticationDefaults.AuthenticationScheme
                var result = await HttpContext.AuthenticateAsync(IdentityConstants.ExternalScheme);
                if (!result.Succeeded)
                    return Unauthorized("External authentication failed.");

                var claims = result.Principal.Identities.FirstOrDefault()?.Claims;
                var email = claims?.FirstOrDefault(c => c.Type == ClaimTypes.Email)?.Value;
                var name = claims?.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value;
                var googleId = claims?.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
                var phoneNumber = claims?.FirstOrDefault(c => c.Type == ClaimTypes.MobilePhone)?.Value;

                var loginDto = new ExternalLoginDTO
                {
                    Provider = "Google",
                    ProviderUserId = googleId,
                    Email = email,
                    Name = name,
                    PhoneNumber = phoneNumber
                };

                ExternalLoginResponseDTO response = await _authService.ExternalLoginAsync(loginDto);
                if (response == null)
                    return BadRequest(ErrorResponse<string>("JWT token not issued"));

                // Optional: Clear the external cookie
                await HttpContext.SignOutAsync(IdentityConstants.ExternalScheme);


                return Ok(SuccessResponse<ExternalLoginResponseDTO>(response)); // You can also redirect to your frontend with the token in query string
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<ExternalLoginResponseDTO>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("update-user-image")]
        public async Task<ActionResult<APIResponseDTO<string>>> ChangeUserImage( IFormFile newImge)
        {
            try
            {
                if(newImge == null)
                    return BadRequest(ErrorResponse<string>("No Image Provided"));

                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if(userId == null)
                {
                    Console.WriteLine($"An unexpected error occurred: Failed to get user credentails");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>($"An unexpected error occurred: Failed to get user credentails"));
                }

                var response = await _authService.UpdateUserImage(userId, newImge);

                if(!response.IsSuccess)
                    return BadRequest(ErrorResponse<string>(response.ErrorMessage));

                return Ok(SuccessResponse<string>(response.Result));


            }
            catch (Exception ex) 
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout(TokenRequestDTO tokenRequestDTO)
        {
            try
            {
                string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                bool result = await _authService.LogoutAsync(tokenRequestDTO.RefreshToken, userId);

                if(result)
                    return Ok(SuccessResponse<bool>(true));

                return BadRequest(ErrorResponse<string>("Error"));

            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        //[Authorize]
        //[HttpPost("Get-Remove-Account-Token")]
        //public async Task<IActionResult> GetRemoveAccountToken(string Email)
        //{
        //    if (string.IsNullOrEmpty(Email)) return BadRequest();

        //    ApiResponse = await _authService.GenerateRemoveAccountTokenAsync(Email);

        //    if (!ApiResponse.IsSuccess) return BadRequest(ApiResponse.ErrorMessage);

        //    RemoveAccountToken removeAccountToken = (RemoveAccountToken)ApiResponse.Result;


        //    MailData mailData = new MailData()
        //    {
        //        EmailToId = Email,
        //        EmailToName = removeAccountToken.ApplicationUser.UserName,
        //        EmailSubject = "Remove Your Account",
        //        EmailBody = $@"
        //        Hello {removeAccountToken.ApplicationUser.UserName},

        //        You recently requested to delete your account.

        //        Here is your account deletion token:

        //        {removeAccountToken.Id}

        //        This token will expire on {removeAccountToken.ExpiresAt:u} and can only be used once.

        //        To complete the account deletion, copy this token and paste it into the reset form in the app or website.

        //        If you did not request this, please ignore this message.

        //        Blease Not That Your Account Will Be Deleted Permanently !!!!

        //        Thanks,  
        //        JWT Authentication .NET Identity"
        //    };

        //    bool result = _mailService.SendMail(mailData);

        //    if (!result) return BadRequest();

        //    return Ok("An email is sent to you with the required token, please check your inbox");

        //}



        //[Authorize]
        //[HttpPost("Remove-Account")]
        //public async Task<IActionResult> RemoveAccount(RemoveAccountDTO removeAccountDTO)
        //{
        //    if (removeAccountDTO.TokenId == null) return BadRequest();

        //    string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        //    ApiResponse = await _authService.RemoveAccountAsync(removeAccountDTO, userId);

        //    if (!ApiResponse.IsSuccess)
        //        return BadRequest(ApiResponse.ErrorMessage);

        //    return Ok(ApiResponse);
        //}

        // For testing 

        [Authorize]
        [HttpGet("TestAuthentication")]
        public IActionResult YouAreAuthenticated()
        {
            return Ok("You Are Authenticated");
        }

        // For testing 


        //[Authorize(Roles = "Admin")]
        //[HttpGet("TestAuthorization")]
        //public IActionResult YouAreAtuhorized()
        //{
        //    return Ok("You Are an admin");
        //}
    }
}
