using System.Collections.Generic;
using System.IO;

namespace StaticDetails
{
    public static class Dictionaries
    {
        // base path becomes dynamic relative to the app root
        static string basePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "Images", "Letters");

        public static Dictionary<char, string> lettersDictionary = new Dictionary<char, string>
        {
            { 'ع', Path.Combine(basePath, "ain.png") },
            { 'ا', Path.Combine(basePath, "aleff.png") },
            { 'ب', Path.Combine(basePath, "bb.png") },
            { 'د', Path.Combine(basePath, "dal.png") },
            { 'ظ', Path.Combine(basePath, "dha.png") },
            { 'ض', Path.Combine(basePath, "dhad.png") },
            { 'ف', Path.Combine(basePath, "fa.png") },
            { 'ق', Path.Combine(basePath, "gaaf.png") },
            { 'غ', Path.Combine(basePath, "ghain.png") },
            { 'ه', Path.Combine(basePath, "ha.png") },
            { 'ح', Path.Combine(basePath, "haa.png") },
            { 'ج', Path.Combine(basePath, "jeem.png") },
            { 'ك', Path.Combine(basePath, "kaaf.png") },
            { 'خ', Path.Combine(basePath, "khaa.png") },
            { 'ل', Path.Combine(basePath, "laam.png") },
            { 'م', Path.Combine(basePath, "meem.png") },
            { 'ن', Path.Combine(basePath, "nun.png") },
            { 'ر', Path.Combine(basePath, "ra.png") },
            { 'ص', Path.Combine(basePath, "saad.png") },
            { 'س', Path.Combine(basePath, "seen.png") },
            { 'ش', Path.Combine(basePath, "sheen.png") },
            { 'ت', Path.Combine(basePath, "ta.png") },
            { 'ط', Path.Combine(basePath, "taa.png") },
            { 'ث', Path.Combine(basePath, "thaa.png") },
            { 'ذ', Path.Combine(basePath, "thal.png") },
            { 'ة', Path.Combine(basePath, "toot.png") },
            { 'و', Path.Combine(basePath, "waw.png") },
            { 'ي', Path.Combine(basePath, "yaa.png") },
            { 'ز', Path.Combine(basePath, "zay.png") }
        };
    }
}

