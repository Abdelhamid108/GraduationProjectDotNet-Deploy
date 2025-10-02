using System.ComponentModel.DataAnnotations;

namespace GraduationProjectWebApplication.Models.Entities
{
    public class UserRecord
    {
        public UserRecord()
        {
            FormedAt = DateTime.Now;
        }

        [Key]
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser User { get; set; }  
        public string FormedSentence { get; set; } = string.Empty;
        public DateTime FormedAt {  get; set; }

    }
}
