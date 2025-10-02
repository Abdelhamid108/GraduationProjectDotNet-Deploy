using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GraduationProject.StaticDetails
{
    public static class UserNameForbiddenDigits
    {
        public static List<char> invalidChars = new List<char>
        {
            '\\', '/', ':', '?', '*', '"', '<', '>', '|'
        };
    }
}
