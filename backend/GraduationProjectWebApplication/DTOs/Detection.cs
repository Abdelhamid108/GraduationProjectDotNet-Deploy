namespace GraduationProjectWebApplication.DTOs
{
    public class Detection
    {
        public float X { get; set; }
        public float Y { get; set; }
        public float Width { get; set; }
        public float Height { get; set; }
        public float Confidence { get; set; }
        public int ClassId { get; set; }
        public string ClassLabelArabic { get; set; } // Store Arabic for display
        public string ClassLabelEnglish { get; set; } // Store Arabic for display

        // Converts center-x, center-y, width, height to min-x, min-y, max-x, max-y
        public float XMin => X - Width / 2;
        public float YMin => Y - Height / 2;
        public float XMax => X + Width / 2;
        public float YMax => Y + Height / 2;

        // Calculates the area of the bounding box
        public float Area => Width * Height;
    }


}
