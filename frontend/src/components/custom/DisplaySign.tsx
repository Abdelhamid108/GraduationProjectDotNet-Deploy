type DisplaySignProps = {
  imageUrl?: string | null;
  letter: string;
};

export default function DisplaySign({ imageUrl, letter }: DisplaySignProps) {
  return (
    <div
      className="bg-white w-full rounded-[35px] px-12 pt-10 pb-10"
      style={{ boxShadow: "0 10px 20px rgba(0,0,0,0.25)" }}
    >
      <h2
        className="text-center text-2xl font-bold tracking-wide mb-6"
        style={{
          color: "#19156C",
          fontFamily: "'Cairo', 'Tajawal', sans-serif",
          letterSpacing: "0.04em",
        }}
      >
        عرض الشاشة
      </h2>

      <div
        className="relative flex flex-col items-center justify-center rounded-[36px] select-none transition-all duration-200 overflow-hidden"
        style={{
          background: "#E7E7E7",
          border: "3px dashed #898989",
          backgroundClip: "padding-box",
          minHeight: "275px",
        }}
      >
        {imageUrl ? (
          <img
            src={imageUrl}
            alt="Selected letter sign"
            className=" object-contain"
          />
        ) : (
          <h3 className="text-8xl text-[#19156C]">{letter}</h3>
        )}
      </div>
      <h3 className="text-8xl text-[#19156C]">{letter}</h3>
    </div>
  );
}
