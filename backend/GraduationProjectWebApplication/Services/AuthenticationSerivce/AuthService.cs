using Azure;
using GraduationProject.StaticDetails;
using GraduationProjectWebApplication.Data;
using GraduationProjectWebApplication.Models.DTOs;
using GraduationProjectWebApplication.Models.Entities;
using GraduationProjectWebApplication.Services.FileService;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using OpenCvSharp;
using Org.BouncyCastle.Utilities.Net;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace GraduationProjectWebApplication.Services.AuthenticationSerivce
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _config;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IFileService _fileService;
        private readonly IWebHostEnvironment _webHostEnvironment;
        private readonly string _key;
        private readonly string _issuer;


        public AuthService(ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            IConfiguration config,
            IHttpContextAccessor httpContextAccessor,
            IFileService fileService,
            IWebHostEnvironment webHostEnvironment)
        {
            _context = context;
            _userManager = userManager;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
            _fileService = fileService;
            _webHostEnvironment = webHostEnvironment;

            _key = config["SECRET_KEY"];
            _issuer = config["ISSUER"];

        }
        public async Task<AuthResponse<TokenResponseDTO>?> LoginAsync(LoginDTO loginDTO)
        {
            if (loginDTO == null)
                return null;

            ApplicationUser? applicationUser = await _context.ApplicationUsers
                .FirstOrDefaultAsync(u => u.UserName == loginDTO.UserName);

            if (applicationUser == null)
                return new AuthResponse<TokenResponseDTO>()
                {
                    ErrorMessage = $"no such user {loginDTO.UserName} !",
                    Result = null,
                    IsSuccess = false,
                };

            bool passwordValid = await _userManager.CheckPasswordAsync(applicationUser, loginDTO.Password);

            if (!passwordValid)
                return new AuthResponse<TokenResponseDTO>()
                {
                    ErrorMessage = "Wrong password !",
                    Result = null,
                    IsSuccess = false,
                };

            TokenResponseDTO tokenResponseDTO = new TokenResponseDTO()
            {
                AccessToken = await GenerateAccessToken(applicationUser),
                RefreshToken = await SaveRefreshTokenAsync(applicationUser),
                AccessTokenExpires = DateTime.UtcNow.AddMinutes(30),
                RefreshTokenExpires = DateTime.UtcNow.AddDays(7)
            };


            return new AuthResponse<TokenResponseDTO>()
            {
                ErrorMessage = "",
                Result = tokenResponseDTO,
                IsSuccess = true,
            };
        }

        public async Task<AuthResponse<ApplicationUserDTO>?> RegisterAsync(RegisterDTO registerDTO)
        {

            if (registerDTO == null)
            {
                return null;
            }
            else
            {
                var existingEmailUser = await _userManager.FindByEmailAsync(registerDTO.Email);

                if (!UserNameUnique(registerDTO.UserName))
                {
                    return new AuthResponse<ApplicationUserDTO>()
                    {
                        ErrorMessage = $"a user with the same username {registerDTO.UserName} already exists !, try onther one",
                        Result = null,
                        IsSuccess = false,
                    };
                }
                else if (registerDTO.UserName.Any(c => UserNameForbiddenDigits.invalidChars.Contains(c)))
                {
                    return new AuthResponse<ApplicationUserDTO>()
                    {
                        ErrorMessage = $"User name can't contain \\ / : ? * \" <> |",
                        Result = null,
                        IsSuccess = false,
                    };
                }
                else if (existingEmailUser != null)
                {
                    return new AuthResponse<ApplicationUserDTO>()
                    {
                        ErrorMessage = $"A user with the email '{registerDTO.Email}' already exists!",
                        Result = null,
                        IsSuccess = false,
                    };
                }
                else
                {

                    if (registerDTO.UserImage != null)
                    {

                        string relativePath = Path.Combine("Images", "UserImages", registerDTO.UserName);

                        string webRootPath = _webHostEnvironment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                        string folderPath = Path.Combine(webRootPath, relativePath);

                        Directory.CreateDirectory(folderPath);

                        string fileRootPath = Path.Combine("Images", "UserImages", registerDTO.UserName) + Path.DirectorySeparatorChar;

                        FileResponse response = await _fileService
                            .SaveFile(registerDTO.UserImage, relativePath,
                            fileRootPath, AllowedExtensions.AllowedImageExtesnions);

                        if (!response.IsSuccess)
                            return new AuthResponse<ApplicationUserDTO>()
                            {
                                ErrorMessage = $"Invalid image type. Only .jpg, .jpeg, and .png files are allowed.",
                                Result = null,
                                IsSuccess = false,
                            };

                        ApplicationUser applicationUser = new ApplicationUser()
                        {
                            FullName = registerDTO.FullName,
                            UserName = registerDTO.UserName,
                            Email = registerDTO.Email,
                            PhoneNumber = registerDTO.PhoneNumber,
                            ImagePath = response.Path,
                        };

                        IdentityResult? result = await _userManager.CreateAsync(applicationUser, registerDTO.Password);

                        if (result.Succeeded)
                        {

                            if (registerDTO.Email.Contains("admin"))
                            {
                                await _userManager.AddToRoleAsync(applicationUser, "Admin");
                            }
                            else
                            {
                                await _userManager.AddToRoleAsync(applicationUser, "User");
                            }

                            string relative = response.Path.TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                            string imageFullPath = Path.Combine(_webHostEnvironment.WebRootPath ??
                                                               Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"),
                                                               relative);

                            string Base64Image = await _fileService.ConvertToBase64(imageFullPath);

                            ApplicationUserDTO applicationUserDTO = new ApplicationUserDTO()
                            {
                                FullName = applicationUser.FullName,
                                UserName = applicationUser.UserName,
                                Email = applicationUser.Email,
                                PhoneNumber = applicationUser.PhoneNumber,
                                ImagePath = Base64Image
                            };

                            return new AuthResponse<ApplicationUserDTO>()
                            {
                                ErrorMessage = "",
                                Result = applicationUserDTO,
                                IsSuccess = true,
                            };
                        }
                        else
                        {
                            return new AuthResponse<ApplicationUserDTO>()
                            {
                                ErrorMessage = "The password must consist of at least 6 characters, including uppercase, lowercase, a digit, and a special character.",
                                Result = null,
                                IsSuccess = false,
                            };
                        }
                    }
                    else
                    {

                        //string baseImagePath = Path.Combine("Images", "UserImages", "BaseImage.jpg");

                        //string relative = baseImagePath.TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                        //string baseImageFullPath = Path.Combine(_webHostEnvironment.WebRootPath ??
                        //                                   Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"),
                        //                                   relative);

                        ApplicationUser applicationUser = new ApplicationUser()
                        {
                            FullName = registerDTO.FullName,
                            UserName = registerDTO.UserName,
                            Email = registerDTO.Email,
                            PhoneNumber = registerDTO.PhoneNumber,
                            ImagePath = null,
                            HasImage = false
                        };

                        IdentityResult? result = await _userManager.CreateAsync(applicationUser, registerDTO.Password);

                        if (result.Succeeded)
                        {

                            if (registerDTO.Email.Contains("admin"))
                            {
                                await _userManager.AddToRoleAsync(applicationUser, "Admin");
                            }
                            else
                            {
                                await _userManager.AddToRoleAsync(applicationUser, "User");
                            }


                            ApplicationUserDTO applicationUserDTO = new ApplicationUserDTO()
                            {
                                FullName = applicationUser.FullName,
                                UserName = applicationUser.UserName,
                                Email = applicationUser.Email,
                                PhoneNumber = applicationUser.PhoneNumber,
                                ImagePath = null
                            };


                            return new AuthResponse<ApplicationUserDTO>()
                            {
                                ErrorMessage = "",
                                Result = applicationUserDTO,
                                IsSuccess = true,
                            };
                        }
                        else
                        {
                            return new AuthResponse<ApplicationUserDTO>()
                            {
                                ErrorMessage = "The password must consist of at least 6 characters, including uppercase, lowercase, a digit, and a special character.",
                                Result = null,
                                IsSuccess = false,
                            };
                        }
                    }
                }
            }
        }

        public async Task<AuthResponse<bool>?> ChangePasswordAsync(string userId, ChangePasswordDTO changePasswordDTO)
        {
            ApplicationUser? applicationUser = await _context.ApplicationUsers
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (applicationUser == null)
            {
                return new AuthResponse<bool>()
                {
                    IsSuccess = false,
                    ErrorMessage = "No such user !",
                    Result = false
                };
            }

            var result = await _userManager
                .ChangePasswordAsync(applicationUser, changePasswordDTO.CurrentPassword, changePasswordDTO.NewPassword);

            if (!result.Succeeded)
            {
                var errorDescription = string.Join("; ", result.Errors.Select(e => e.Description));

                return new AuthResponse<bool>()
                {
                    IsSuccess = false,
                    ErrorMessage = errorDescription,
                    Result = false
                };
            }

            return new AuthResponse<bool>()
            {
                IsSuccess = true,
                Result = true
            };


        }

        public async Task<AuthResponse<bool>?> ResetPasswordAsync(ResetPasswordDTO resetPasswordDTO)
        {
            AuthResponse<bool> authResponse;

            var user = await _userManager.FindByEmailAsync(resetPasswordDTO.Email);
            if (user == null)
                return authResponse = new AuthResponse<bool>()
                {
                    IsSuccess = false,
                    ErrorMessage = "Invalid user",
                    Result = false
                };



            ResetPasswordToken? resetPasswordToken =
                await _context.ResetPasswordTokens
                .Where(t => t.UserId == user.Id &&
                            !t.IsUsed &&
                            t.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(t => t.ExpiresAt)
                .FirstOrDefaultAsync();


            if (resetPasswordToken == null || resetPasswordToken.OtpHash != HashOtp(resetPasswordDTO.OTP))
                return new AuthResponse<bool>()
                {
                    IsSuccess = false,
                    ErrorMessage = "Invaild or expired OTP !",
                    Result = false,
                };

            var result = await _userManager
                .ResetPasswordAsync(user, resetPasswordToken.IdentityToken, resetPasswordDTO.NewPassword);

            if (!result.Succeeded)
            {
                var errorDescription = string.Join("; ", result.Errors.Select(e => e.Description));

                return new AuthResponse<bool>()
                {
                    IsSuccess = false,
                    ErrorMessage = errorDescription,
                    Result = false,
                };

            }

            resetPasswordToken.IsUsed = true;

            _context.ResetPasswordTokens.Update(resetPasswordToken);
            await _context.SaveChangesAsync();

            return new AuthResponse<bool>()
            {
                IsSuccess = true,
                Result = true,
            };
        }

        public async Task<AuthResponse<ResetPasswordTokenDTO>?> GenerateResetPasswordTokenAsync(string Email)
        {
            ApplicationUser? applicationUser = await _userManager.FindByEmailAsync(Email);

            if (applicationUser == null)
            {
                return new AuthResponse<ResetPasswordTokenDTO>()
                {
                    IsSuccess = false,
                    ErrorMessage = "No user with this email found",
                    Result = null,
                };
            }


            string identityToken = await _userManager.GeneratePasswordResetTokenAsync(applicationUser);
            string otp = GenerateOtp();

            ResetPasswordToken resetPasswordToken = new ResetPasswordToken()
            {
                UserId = applicationUser.Id,
                ExpiresAt = DateTime.Now.AddMinutes(10),
                IdentityToken = identityToken,
                User = applicationUser,
                OtpHash = HashOtp(otp),
            };


            _context.ResetPasswordTokens.Add(resetPasswordToken);
            await _context.SaveChangesAsync();

            return new AuthResponse<ResetPasswordTokenDTO>()
            {
                IsSuccess = true,
                Result = new ResetPasswordTokenDTO()
                {
                    Otp = otp,
                    ExpiresAt = resetPasswordToken.ExpiresAt,
                    UserEmail = applicationUser.Email,
                    UserName = applicationUser.UserName,
                }
            };
        }

        public async Task<TokenResponseDTO?> RefreshTokensAsync(TokenRequestDTO tokenRequestDTO)
        {
            RefreshToken? refreshToken = await _context.RefreshTokens
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Token == tokenRequestDTO.RefreshToken);

            bool result = !await ValidateRefreshToken(refreshToken);
            if (result) return null;


            refreshToken.RevokedAt = DateTime.Now;

            string newRefreshToken = await SaveRefreshTokenAsync(refreshToken.User);

            refreshToken.ReplacedByToken = newRefreshToken;

            await _context.SaveChangesAsync();

            return new TokenResponseDTO()
            {
                AccessToken = await GenerateAccessToken(refreshToken.User),
                RefreshToken = newRefreshToken,
                AccessTokenExpires = DateTime.Now.AddMinutes(30),
                RefreshTokenExpires = DateTime.Now.AddDays(7),
            };
        }
        public async Task<bool> RevokeRefreshTokenAsync(string refreshToken)
        {

            RefreshToken? refreshToken1 = await _context.RefreshTokens
                .FirstOrDefaultAsync(r => r.Token == refreshToken);

            if (refreshToken1 == null || !refreshToken1.IsActive) return false;

            refreshToken1.RevokedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return true;

        }
        public async Task<bool> LogoutAsync(string refreshToken, string userId)
        {
            ApplicationUser? applicationUser = await _context.ApplicationUsers
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (applicationUser == null) return false;

            bool result;

            if (!string.IsNullOrEmpty(refreshToken))
            {
                result = await RevokeRefreshTokenAsync(refreshToken);
            }
            else
            {
                result = await RevokeAllUserRefreshTokensAsync(userId);
            }

            return result;

        }
        public async Task<bool> RevokeAllUserRefreshTokensAsync(string userId)
        {
            List<RefreshToken>? refreshTokens = await _context.RefreshTokens
                 .Where(r => r.UserId == userId && r.IsActive == true).ToListAsync();

            if (refreshTokens == null) return false;

            foreach (RefreshToken refreshToken in refreshTokens)
            {
                refreshToken.RevokedAt = DateTime.UtcNow;
            }
            await _context.SaveChangesAsync();
            return true;
        }
        public async Task<ExternalLoginResponseDTO?> ExternalLoginAsync(ExternalLoginDTO loginDTO)
        {
            var user = await _userManager.FindByLoginAsync(loginDTO.Provider, loginDTO.ProviderUserId);
            string base64Iamge = string.Empty;

            if (user == null)
            {
                user = await _userManager.FindByEmailAsync(loginDTO.Email);
                if (user == null)
                {
                    string baseImagePath = @"\Images\UserImages\BaseImage.jpg";

                    string relative = baseImagePath.TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                    string baseImageFullPath = Path.Combine(_webHostEnvironment.WebRootPath ??
                                                       Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"),
                                                       relative);

                    user = new ApplicationUser
                    {
                        UserName = loginDTO.Email,
                        Email = loginDTO.Email,
                        EmailConfirmed = true,
                        FullName = loginDTO.Name,
                        PhoneNumber = loginDTO.PhoneNumber,
                        HasImage = false,
                        ImagePath = baseImageFullPath
                    };

                    base64Iamge = await _fileService.ConvertToBase64(baseImageFullPath);

                    var createResult = await _userManager.CreateAsync(user);
                    if (!createResult.Succeeded) return null;
                }

                var loginInfo = new UserLoginInfo(loginDTO.Provider, loginDTO.ProviderUserId, loginDTO.Provider);
                var addLoginResult = await _userManager.AddLoginAsync(user, loginInfo);
                if (!addLoginResult.Succeeded) return null;
            }

            TokenResponseDTO tokenResponseDTO = new TokenResponseDTO()
            {
                AccessToken = await GenerateAccessToken(user),
                RefreshToken = await SaveRefreshTokenAsync(user),
                AccessTokenExpires = DateTime.UtcNow.AddMinutes(30),
                RefreshTokenExpires = DateTime.UtcNow.AddDays(7)
            };



            return new ExternalLoginResponseDTO()
            {
                Base64Image = base64Iamge,
                TokenResponseDTO = tokenResponseDTO,
            };
        }
        public async Task<AuthResponse<string>> UpdateUserImage(string userId, IFormFile newImage)
        {
            ApplicationUser? applicationUser = await _context.ApplicationUsers
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (applicationUser == null)
                return new AuthResponse<string>()
                {
                    IsSuccess = false,
                    ErrorMessage = "No Such User",
                    Result = string.Empty
                };

            string relativePath = Path.Combine("Images", "UserImages", applicationUser.UserName);
            string webRootPath = _webHostEnvironment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            string folderPath = Path.Combine(webRootPath, relativePath);

            if (!applicationUser.HasImage)
            {
                Directory.CreateDirectory(folderPath);
            }

            string fileRootPath = Path.Combine("Images", "UserImages", applicationUser.UserName) + Path.DirectorySeparatorChar;

            var updateFileResponse = await _fileService
                    .UpdateFile(newImage, applicationUser.ImagePath, relativePath,
                    fileRootPath,
                    AllowedExtensions.AllowedImageExtesnions);

            if (!updateFileResponse.IsSuccess)
                return new AuthResponse<string>()
                {
                    IsSuccess = false,
                    ErrorMessage = $"Invalid image type. Only .jpg, .jpeg, and .png files are allowed.",
                    Result = string.Empty
                };

            applicationUser.ImagePath = updateFileResponse.Path;
            applicationUser.HasImage = true;

            _context.ApplicationUsers.Update(applicationUser);
            await _context.SaveChangesAsync();


            string relative = updateFileResponse.Path.TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string imageFullPath = Path.Combine(_webHostEnvironment.WebRootPath ??
                                               Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"),
                                               relative);

            string Base64Image = await _fileService.ConvertToBase64(imageFullPath);

            return new AuthResponse<string>()
            {
                IsSuccess = true,
                Result = Base64Image
            };
        }
        public async Task<AuthResponse<UserProfileDTO>> GetUserProfile(string userId)
        {
            ApplicationUser? applicationUser = await _context.ApplicationUsers
                           .FirstOrDefaultAsync(u => u.Id == userId);

            if (applicationUser == null)
            {
                return new AuthResponse<UserProfileDTO>()
                {
                    ErrorMessage = "No Such User",
                    Result = null,
                    IsSuccess = false
                };
            }

            string relative = applicationUser.ImagePath.TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string imageFullPath = Path.Combine(_webHostEnvironment.WebRootPath ??
                                               Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"),
                                               relative);
            string base64Image = string.Empty;

            if (!string.IsNullOrEmpty(applicationUser.ImagePath))
            {
                base64Image = await _fileService.ConvertToBase64(imageFullPath);
            }

            UserProfileDTO userProfileDTO = new UserProfileDTO()
            {
                UserName = applicationUser.UserName,
                Email = applicationUser.Email,
                PhoneNumber = applicationUser.PhoneNumber,
                ImagePath = base64Image,
                FullName = applicationUser.FullName,
            };

            return new AuthResponse<UserProfileDTO>()
            {
                IsSuccess = true,
                Result = userProfileDTO
            };
        }
        public async Task<AuthResponse<UserProfileDTO>?> UpdateUserProfile(string userId, UpdateUserProfileDTO updateUserProfileDTO)
        {
            ApplicationUser? applicationUser = await _context.ApplicationUsers
                           .FirstOrDefaultAsync(u => u.Id == userId);

            if (applicationUser == null)
            {
                return new AuthResponse<UserProfileDTO>()
                {
                    ErrorMessage = "No Such User",
                    Result = null,
                    IsSuccess = false
                };
            }

            if (applicationUser.FullName != updateUserProfileDTO.FullName && !string.IsNullOrEmpty(updateUserProfileDTO.FullName))
            {
                applicationUser.FullName = updateUserProfileDTO.FullName;
            }

            if (applicationUser.UserName != updateUserProfileDTO.UserName && !string.IsNullOrEmpty(updateUserProfileDTO.UserName))
            {
                if (UserNameUnique(updateUserProfileDTO.UserName))
                {
                    applicationUser.UserName = updateUserProfileDTO.UserName;
                }
                else
                {
                    return new AuthResponse<UserProfileDTO>()
                    {
                        ErrorMessage = "This user name is already taken",
                        Result = null,
                        IsSuccess = false
                    };
                }
            }

            if (applicationUser.Email != updateUserProfileDTO.Email && !string.IsNullOrEmpty(updateUserProfileDTO.Email))
            {
                var user = await _userManager.FindByEmailAsync(updateUserProfileDTO.Email);

                if (user == null)
                {
                    applicationUser.Email = updateUserProfileDTO.Email;
                }
                else
                {
                    return new AuthResponse<UserProfileDTO>()
                    {
                        ErrorMessage = "A user with this email already exists",
                        Result = null,
                        IsSuccess = false
                    };
                }
            }

            if (applicationUser.PhoneNumber != updateUserProfileDTO.PhoneNumber && !string.IsNullOrEmpty(updateUserProfileDTO.PhoneNumber))
            {
                applicationUser.PhoneNumber = updateUserProfileDTO.PhoneNumber;
            }

            _context.ApplicationUsers.Update(applicationUser);
            await _context.SaveChangesAsync();


            string relative = applicationUser.ImagePath.TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string imageFullPath = Path.Combine(_webHostEnvironment.WebRootPath ??
                                               Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"),
                                               relative);
            string base64Image = string.Empty;

            if (!string.IsNullOrEmpty(applicationUser.ImagePath))
            {
                base64Image = await _fileService.ConvertToBase64(imageFullPath);
            }

            return new AuthResponse<UserProfileDTO>()
            {
                IsSuccess = true,
                Result = new UserProfileDTO()
                {
                    ImagePath = base64Image,
                    Email = applicationUser.Email,
                    UserName = applicationUser.UserName,
                    FullName = applicationUser.FullName,
                    PhoneNumber = applicationUser.PhoneNumber,
                }
            };
        }

        private bool UserNameUnique(string userName)
        {
            bool result = false;
            ApplicationUser? applicationUser = _context.ApplicationUsers.FirstOrDefault(u => u.UserName.ToLower() == userName.ToLower());

            if (applicationUser == null)
            {
                result = true;
            }
            return result;
        }
        private async Task<string> GenerateAccessToken(ApplicationUser applicationUser)
        {
            var userRoles = await _userManager.GetRolesAsync(applicationUser);

            List<Claim> claims = new List<Claim>()
            {
                new Claim(ClaimTypes.Name, applicationUser.FullName),
                new Claim(ClaimTypes.NameIdentifier, applicationUser.Id,ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(JwtRegisteredClaimNames.Sub, applicationUser.Id)
            };

            foreach (var role in userRoles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_key));

            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512);

            var tokenDescriptor = new JwtSecurityToken
                (
                    issuer: _issuer,
                    claims: claims,
                    signingCredentials: creds,
                    expires: DateTime.Now.AddMinutes(30)
                );

            string finalToken = new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);

            return finalToken;

        }
        private async Task<string> SaveRefreshTokenAsync(ApplicationUser user)
        {
            RefreshToken refreshToken = new RefreshToken()
            {
                Token = await GenerateRefreshToken(),
                UserId = user.Id,
                CreatedAt = DateTime.Now,
                ExpiresAt = DateTime.Now.AddDays(7),
            };

            await _context.AddAsync(refreshToken);
            await _context.SaveChangesAsync();

            return refreshToken.Token;
        }
        private async Task<string> GenerateRefreshToken()
        {
            var randomNumber = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }
        private async Task<bool> ValidateRefreshToken(RefreshToken refreshToken)
        {
            if (refreshToken == null || !refreshToken.IsActive || refreshToken.IsExpired) return false;

            return true;
        }
        private static string GenerateOtp()
        {
            using var rng = RandomNumberGenerator.Create();
            var bytes = new byte[4];
            rng.GetBytes(bytes);

            int otp = BitConverter.ToInt32(bytes, 0) % 1_000_000;
            return Math.Abs(otp).ToString("D6");
        }


        private static string HashOtp(string otp)
        {
            using var sha = SHA256.Create();
            var bytes = Encoding.UTF8.GetBytes(otp);
            return Convert.ToBase64String(sha.ComputeHash(bytes));
        }



    }
}
