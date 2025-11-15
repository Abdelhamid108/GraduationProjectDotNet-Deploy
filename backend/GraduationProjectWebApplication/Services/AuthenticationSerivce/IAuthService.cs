using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;

namespace GraduationProjectWebApplication.Services.AuthenticationSerivce
{
    public interface IAuthService
    {
        Task<AuthResponse<ApplicationUserDTO>?> RegisterAsync(RegisterDTO registerDTO);
        Task<AuthResponse<TokenResponseDTO>?> LoginAsync(LoginDTO loginDTO);
        Task<AuthResponse<bool>?> ChangePasswordAsync(string userId, ChangePasswordDTO changePasswordDTO);
        Task<AuthResponse<bool>?> ResetPasswordAsync(ResetPasswordDTO resetPasswordDTO);
        Task<AuthResponse<ResetPasswordToken>?> GenerateResetPasswordTokenAsync(string Email);
        Task<TokenResponseDTO?> RefreshTokensAsync(TokenRequestDTO tokenRequestDTO);
        Task<bool> RevokeRefreshTokenAsync(string refreshToken);
        Task<bool> RevokeAllUserRefreshTokensAsync(string userId);
        Task<ExternalLoginResponseDTO?> ExternalLoginAsync(ExternalLoginDTO loginDTO);
        Task<AuthResponse<string>> UpdateUserImage(string userId, IFormFile newImage);
        Task<AuthResponse<UserProfileDTO>> GetUserProfile(string userId);
        Task<AuthResponse<UserProfileDTO>?> UpdateUserProfile(string userId, UpdateUserProfileDTO updateUserProfileDTO);
        Task<bool> LogoutAsync(string refreshToken, string userId);
    }
}
