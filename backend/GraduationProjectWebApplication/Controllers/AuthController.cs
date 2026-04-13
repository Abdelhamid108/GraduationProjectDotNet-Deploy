using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.AuthenticationSerivce;
using GraduationProjectWebApplication.Services.EmailService;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
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
        private readonly ILogger<AuthController> _logger;
        public AuthController(IAuthService authService, IEmailService emailService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _emailService = emailService;
            _logger = logger;
        }

        [HttpPost("register-user")]
        [EnableRateLimiting("RegisterLimiter")]
        public async Task<ActionResult<APIResponseDTO<ApplicationUserDTO>>> RegisterAsync([FromForm] RegisterDTO registerDTO)
        {
            _logger.LogInformation("Register endpoint called.");

            AuthResponse<ApplicationUserDTO>? authResponse;

            try
            {
                if (registerDTO == null)
                {
                    _logger.LogWarning("Register failed: RegisterDTO is null.");
                    return BadRequest(ErrorResponse<ApplicationUserDTO>("Null DTO"));
                }

                _logger.LogInformation("Attempting to register user with username: {Username}", registerDTO.UserName);

                authResponse = await _authService.RegisterAsync(registerDTO);

                if (authResponse == null)
                {
                    _logger.LogError("AuthService returned null response during registration.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<ApplicationUserDTO>("An unexpected error occurred"));
                }

                if (!authResponse.IsSuccess)
                {
                    _logger.LogWarning("User registration failed for username: {Username}. Reason: {Reason}",
                        registerDTO.UserName,
                        authResponse.ErrorMessage);

                    return BadRequest(ErrorResponse<ApplicationUserDTO>(authResponse.ErrorMessage));
                }

                _logger.LogInformation("User registered successfully. Username: {Username}", registerDTO.UserName);

                return Ok(SuccessResponse<ApplicationUserDTO>(authResponse.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during user registration for username: {Username}",
                    registerDTO?.UserName);

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<ApplicationUserDTO>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpPost("login-user")]
        [EnableRateLimiting("LoginLimiter")]
        public async Task<ActionResult<APIResponseDTO<TokenResponseDTO>>> LoginAsync([FromBody] LoginDTO loginDTO)
        {
            _logger.LogInformation("Login endpoint called.");

            AuthResponse<TokenResponseDTO>? authResponse;

            try
            {
                if (loginDTO == null)
                {
                    _logger.LogWarning("Login failed: LoginDTO is null.");
                    return BadRequest(ErrorResponse<TokenResponseDTO>("Invalid Credentials"));
                }

                _logger.LogInformation("Login attempt for username: {Username}", loginDTO.UserName);

                authResponse = await _authService.LoginAsync(loginDTO);

                if (authResponse == null)
                {
                    _logger.LogError("AuthService returned null response during login.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<TokenResponseDTO>("An unexpected error occurred"));
                }

                if (!authResponse.IsSuccess)
                {
                    _logger.LogWarning("Login failed for username: {Username}. Reason: {Reason}",
                        loginDTO.UserName,
                        authResponse.ErrorMessage);

                    return BadRequest(ErrorResponse<TokenResponseDTO>(authResponse.ErrorMessage));
                }

                _logger.LogInformation("Login successful for username: {Username}", loginDTO.UserName);

                return Ok(SuccessResponse<TokenResponseDTO>(authResponse.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during login for username: {Username}",
                    loginDTO?.UserName);

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpPost("refresh-tokens")]
        [EnableRateLimiting("RefreshTokenLimiter")]
        public async Task<ActionResult<APIResponseDTO<TokenResponseDTO>>> RefreshTokens([FromBody] TokenRequestDTO tokenRequestDTO)
        {
            _logger.LogInformation("RefreshTokens endpoint called.");

            try
            {
                if (tokenRequestDTO == null)
                {
                    _logger.LogWarning("RefreshTokens failed: TokenRequestDTO is null.");
                    return BadRequest(ErrorResponse<TokenResponseDTO>("Invalid request."));
                }

                _logger.LogInformation("Attempting to refresh tokens.");

                TokenResponseDTO? tokenResponse = await _authService.RefreshTokensAsync(tokenRequestDTO);

                if (tokenResponse == null ||
                    string.IsNullOrEmpty(tokenResponse.RefreshToken) ||
                    string.IsNullOrEmpty(tokenResponse.AccessToken))
                {
                    _logger.LogWarning("Invalid refresh token attempt.");

                    return Unauthorized(
                        ErrorResponse<TokenResponseDTO>("Invalid Refresh Token!"));
                }

                _logger.LogInformation("Tokens refreshed successfully.");

                return Ok(SuccessResponse<TokenResponseDTO>(tokenResponse));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during token refresh.");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpPost("get-reset-password-token")]
        [EnableRateLimiting("GetResetPasswordLimiter")]
        public async Task<ActionResult<APIResponseDTO<bool>>> GetResetPasswordToken([FromBody] GetResetPasswordTokenByEmailDTO tokenByEmailDTO)
        {
            _logger.LogInformation("GetResetPasswordToken endpoint called.");

            if (tokenByEmailDTO == null || string.IsNullOrEmpty(tokenByEmailDTO.Email))
            {
                _logger.LogWarning("Invalid request: Email is missing.");
                return BadRequest(ErrorResponse<bool>("Invalid Email"));
            }

            try
            {
                _logger.LogInformation("Generating reset password token for email: {Email}", tokenByEmailDTO.Email);

                AuthResponse<ResetPasswordTokenDTO>? authResponse =
                    await _authService.GenerateResetPasswordTokenAsync(tokenByEmailDTO.Email);

                if (authResponse == null)
                {
                    _logger.LogError("AuthService returned null while generating reset password token.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<bool>("An unexpected error occurred"));
                }

                if (!authResponse.IsSuccess)
                {
                    _logger.LogWarning("Failed to generate reset token for email: {Email}. Reason: {Reason}",
                        tokenByEmailDTO.Email,
                        authResponse.ErrorMessage);

                    return BadRequest(ErrorResponse<bool>(authResponse.ErrorMessage));
                }

                ResetPasswordTokenDTO? resetPasswordToken = authResponse.Result;

                _logger.LogInformation("Reset password token generated successfully for email: {Email}", tokenByEmailDTO.Email);

                MailData mailData = new MailData()
                {
                    EmailToId = tokenByEmailDTO.Email,
                    EmailToName = resetPasswordToken.UserName,
                    EmailSubject = "Reset Your Password",
                    EmailBody = $@"
                    Hello {resetPasswordToken.UserName},

                    You recently requested to reset your password.

                    Here is your password reset OTP:

                    {resetPasswordToken.Otp}

                    This token will expire in 10 minutes and can only be used once.

                    To complete the password reset, copy this token and paste it into the reset form in the app or website.

                    If you did not request this, please ignore this message.

                    Thanks,  
                    Ema2a Team"
                };

                _logger.LogInformation("Sending reset password email to: {Email}", tokenByEmailDTO.Email);

                bool result = await _emailService.SendMailAsync(mailData);

                if (!result)
                {
                    _logger.LogError("Failed to send reset password email to: {Email}", tokenByEmailDTO.Email);

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<bool>("Failed to send reset email."));
                }

                _logger.LogInformation("Reset password email sent successfully to: {Email}", tokenByEmailDTO.Email);

                return Ok(SuccessResponse<bool>(true));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while generating reset password token for email: {Email}",
                    tokenByEmailDTO?.Email);

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<bool>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpPost("reset-password")]
        [EnableRateLimiting("ResetPasswordLimiter")]
        public async Task<ActionResult<APIResponseDTO<bool>>> ResetPassword([FromBody] ResetPasswordDTO resetPasswordDTO)
        {
            _logger.LogInformation("ResetPassword endpoint called.");

            try
            {
                if (resetPasswordDTO == null ||
                    string.IsNullOrEmpty(resetPasswordDTO.NewPassword) ||
                    resetPasswordDTO.OTP == null)
                {
                    _logger.LogWarning("Invalid reset password request: missing password or OTP.");
                    return BadRequest(ErrorResponse<bool>("Invalid token or password"));
                }

                _logger.LogInformation("Attempting to reset password.");

                AuthResponse<bool>? authResponse =
                    await _authService.ResetPasswordAsync(resetPasswordDTO);

                if (authResponse == null)
                {
                    _logger.LogError("AuthService returned null during password reset.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<bool>("An unexpected error occurred"));
                }

                if (!authResponse.IsSuccess)
                {
                    _logger.LogWarning("Password reset failed. Reason: {Reason}",
                        authResponse.ErrorMessage);

                    return BadRequest(ErrorResponse<bool>(authResponse.ErrorMessage));
                }

                _logger.LogInformation("Password reset successful.");

                return Ok(SuccessResponse<bool>(authResponse.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during password reset.");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("change-password")]
        [EnableRateLimiting("ChangePasswordLimiter")]
        public async Task<ActionResult<APIResponseDTO<bool>>> ChangePassword([FromBody] ChangePasswordDTO changePasswordDTO)
        {
            _logger.LogInformation("ChangePassword endpoint called.");

            try
            {
                string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("Unauthorized request: UserId not found in token.");
                    return Unauthorized(ErrorResponse<bool>("Unauthorized"));
                }

                if (changePasswordDTO == null)
                {
                    _logger.LogWarning("Invalid request: ChangePasswordDTO is null.");
                    return BadRequest(ErrorResponse<bool>("Invalid request."));
                }

                _logger.LogInformation("User {UserId} attempting to change password.", userId);

                AuthResponse<bool>? authResponse =
                    await _authService.ChangePasswordAsync(userId, changePasswordDTO);

                if (authResponse == null)
                {
                    _logger.LogError("AuthService returned null during ChangePassword for UserId: {UserId}", userId);

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<bool>("An unexpected error occurred"));
                }

                if (!authResponse.IsSuccess)
                {
                    _logger.LogWarning("ChangePassword failed for UserId: {UserId}. Reason: {Reason}",
                        userId,
                        authResponse.ErrorMessage);

                    return BadRequest(ErrorResponse<bool>(authResponse.ErrorMessage));
                }

                _logger.LogInformation("Password changed successfully for UserId: {UserId}", userId);

                return Ok(SuccessResponse<bool>(authResponse.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during ChangePassword for UserId: {UserId}",
                    User?.FindFirstValue(ClaimTypes.NameIdentifier));

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpGet("login-google")]
        [EnableRateLimiting("GoogleLoginLimiter")]
        public IActionResult LoginWithGoogle()
        {
            _logger.LogInformation("LoginWithGoogle endpoint called.");

            try
            {
                // FIX: Read the public-facing scheme and host from X-Forwarded-* headers set by nginx.
                // The container runs on plain http internally, but the public site is https.
                // UseForwardedHeaders() populates Request.Scheme and Request.Host from these headers,
                // so Url.Action() will correctly build: https://ema2a.ddns.net/api/Auth/google-callback
                var redirectUrl = Url.Action(
                    action: "GoogleCallback",
                    controller: "Auth",
                    values: null,
                    protocol: Request.Scheme,
                    host: Request.Host.Value
                );

                if (string.IsNullOrEmpty(redirectUrl))
                {
                    _logger.LogError("Failed to generate Google callback URL.");

                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>("Failed to initiate Google login."));
                }

                _logger.LogInformation("Redirecting to Google authentication. Callback URL: {RedirectUrl}", redirectUrl);

                var properties = new AuthenticationProperties
                {
                    RedirectUri = redirectUrl
                };

                return Challenge(properties, GoogleDefaults.AuthenticationScheme);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while initiating Google login.");

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [HttpGet("google-callback")]
        [EnableRateLimiting("GoogleCallbackLimiter")]
        public async Task<ActionResult<APIResponseDTO<ExternalLoginResponseDTO>>> GoogleCallback()
        {
            _logger.LogInformation("GoogleCallback endpoint called.");

            try
            {
                var result = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);

                if (!result.Succeeded)
                {
                    _logger.LogWarning("External authentication failed.");
                    return Unauthorized(ErrorResponse<string>("External authentication failed."));
                }

                var claims = result.Principal?.Identities.FirstOrDefault()?.Claims;
                var email = claims?.FirstOrDefault(c => c.Type == ClaimTypes.Email)?.Value;
                var name = claims?.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value;
                var googleId = claims?.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
                var phoneNumber = claims?.FirstOrDefault(c => c.Type == ClaimTypes.MobilePhone)?.Value;

                if (string.IsNullOrEmpty(googleId))
                {
                    _logger.LogError("Google ID claim not found in external login.");
                    return BadRequest(ErrorResponse<string>("External login failed: missing Google ID."));
                }

                _logger.LogInformation("External login claims retrieved. Email: {Email}, Name: {Name}", email, name);

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
                {
                    _logger.LogError("JWT token not issued for external login.");
                    return BadRequest(ErrorResponse<string>("JWT token not issued"));
                }

                _logger.LogInformation("External login successful for Google ID: {GoogleId}", googleId);

                // Clear the external cookie
                await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                _logger.LogDebug("External authentication cookie cleared.");

                return Ok(SuccessResponse<ExternalLoginResponseDTO>(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during Google external login.");
                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<ExternalLoginResponseDTO>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("update-user-image")]
        [EnableRateLimiting("UpdateImageLimiter")]
        public async Task<ActionResult<APIResponseDTO<string>>> ChangeUserImage([FromForm] ChangeUserImageDTO changeUserImageDTO)
        {
            _logger.LogInformation("ChangeUserImage endpoint called.");

            try
            {
                if (changeUserImageDTO == null || changeUserImageDTO.NewImge == null)
                {
                    _logger.LogWarning("No image provided in ChangeUserImage request.");
                    return BadRequest(ErrorResponse<string>("No Image Provided"));
                }

                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogError("Failed to get user credentials from claims.");
                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>("An unexpected error occurred: Failed to get user credentials"));
                }

                _logger.LogInformation("Updating user image for UserId: {UserId}", userId);

                var response = await _authService.UpdateUserImage(userId, changeUserImageDTO.NewImge);

                if (!response.IsSuccess)
                {
                    _logger.LogWarning("Failed to update user image for UserId: {UserId}. Reason: {Reason}",
                        userId,
                        response.ErrorMessage);

                    return BadRequest(ErrorResponse<string>(response.ErrorMessage));
                }

                _logger.LogInformation("User image updated successfully for UserId: {UserId}", userId);

                return Ok(SuccessResponse<string>(response.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while updating user image for UserId: {UserId}",
                    User?.FindFirst(ClaimTypes.NameIdentifier)?.Value);

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("logout")]
        [EnableRateLimiting("LogoutLimiter")]
        public async Task<IActionResult> Logout([FromBody] TokenRequestDTO tokenRequestDTO)
        {
            _logger.LogInformation("Logout endpoint called.");

            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("Logout failed: UserId not found in claims.");
                    return Unauthorized(ErrorResponse<string>("Unauthorized"));
                }

                if (tokenRequestDTO == null || string.IsNullOrEmpty(tokenRequestDTO.RefreshToken))
                {
                    _logger.LogWarning("Logout failed: RefreshToken not provided.");
                    return BadRequest(ErrorResponse<string>("Invalid request."));
                }

                _logger.LogInformation("Attempting to logout UserId: {UserId}", userId);

                bool result = await _authService.LogoutAsync(tokenRequestDTO.RefreshToken, userId);

                if (result)
                {
                    _logger.LogInformation("UserId {UserId} logged out successfully.", userId);
                    return Ok(SuccessResponse<bool>(true));
                }
                else
                {
                    _logger.LogWarning("Logout failed for UserId {UserId}. Refresh token may be invalid.", userId);
                    return BadRequest(ErrorResponse<string>("Error logging out."));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred during logout for UserId: {UserId}",
                    User?.FindFirstValue(ClaimTypes.NameIdentifier));

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpGet("user-profile")]
        [EnableRateLimiting("UserProfileReadLimiter")]
        public async Task<ActionResult<APIResponseDTO<UserProfileDTO>>> UserProfile()
        {
            _logger.LogInformation("UserProfile endpoint called.");

            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("UserProfile request failed: UserId not found in claims.");
                    return Unauthorized(ErrorResponse<string>("Unauthorized"));
                }

                _logger.LogInformation("Fetching profile for UserId: {UserId}", userId);

                AuthResponse<UserProfileDTO>? response = await _authService.GetUserProfile(userId);

                if (response == null)
                {
                    _logger.LogError("AuthService returned null while fetching profile for UserId: {UserId}", userId);
                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>("An unexpected error occurred"));
                }

                if (!response.IsSuccess)
                {
                    _logger.LogWarning("Failed to fetch profile for UserId: {UserId}. Reason: {Reason}",
                        userId, response.ErrorMessage);

                    return BadRequest(ErrorResponse<string>(response.ErrorMessage));
                }

                _logger.LogInformation("Profile fetched successfully for UserId: {UserId}", userId);

                return Ok(SuccessResponse<UserProfileDTO>(response.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while fetching profile for UserId: {UserId}",
                    User?.FindFirstValue(ClaimTypes.NameIdentifier));

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        [Authorize]
        [HttpPost("update-user-profile")]
        [EnableRateLimiting("UserProfileUpdateLimiter")]
        public async Task<ActionResult<APIResponseDTO<UserProfileDTO>>> UpdateUserProfile([FromBody] UpdateUserProfileDTO updateUserProfileDTO)
        {
            _logger.LogInformation("UpdateUserProfile endpoint called.");

            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("UpdateUserProfile failed: UserId not found in claims.");
                    return Unauthorized(ErrorResponse<string>("Unauthorized"));
                }

                if (updateUserProfileDTO == null)
                {
                    _logger.LogWarning("UpdateUserProfile failed: Request body is null.");
                    return BadRequest(ErrorResponse<string>("Invalid request."));
                }

                _logger.LogInformation("Updating profile for UserId: {UserId}", userId);

                AuthResponse<UserProfileDTO>? response = await _authService.UpdateUserProfile(userId, updateUserProfileDTO);

                if (response == null)
                {
                    _logger.LogError("AuthService returned null while updating profile for UserId: {UserId}", userId);
                    return StatusCode(
                        (int)HttpStatusCode.InternalServerError,
                        ErrorResponse<string>("An unexpected error occurred"));
                }

                if (!response.IsSuccess)
                {
                    _logger.LogWarning("Failed to update profile for UserId: {UserId}. Reason: {Reason}",
                        userId, response.ErrorMessage);

                    return BadRequest(ErrorResponse<string>(response.ErrorMessage));
                }

                _logger.LogInformation("Profile updated successfully for UserId: {UserId}", userId);

                return Ok(SuccessResponse<UserProfileDTO>(response.Result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while updating profile for UserId: {UserId}",
                    User?.FindFirstValue(ClaimTypes.NameIdentifier));

                return StatusCode(
                    (int)HttpStatusCode.InternalServerError,
                    ErrorResponse<string>($"An unexpected error occurred: {ex.Message}"));
            }
        }

        // For testing 

        [Authorize]
        [HttpGet("test-authentication")]
        public IActionResult YouAreAuthenticated()
        {
            return Ok("You Are Authenticated");
        }
    }
}
