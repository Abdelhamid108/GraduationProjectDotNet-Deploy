using GraduationProjectWebApplication.Models.Entities;
using System.ComponentModel.DataAnnotations;

namespace GraduationProjectWebApplication.Models.DTOs
{
    public class UserRecordDTO
    {
        public int Id {  get; set; }
        public string FormedSentence { get; set; } = string.Empty;
        public DateTime FormedAt { get; set; }
    }
}
