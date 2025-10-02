using Microsoft.AspNetCore.Identity;

namespace GraduationProjectWebApplication.Models.Entities
{
    public class ApplicationUser: IdentityUser
    {
        public string FullName { get; set; } = string.Empty;
        public string? ImagePath {  get; set; } = string.Empty;
        public bool HasImage { get; set; } = true;
    }
}
