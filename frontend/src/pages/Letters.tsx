import { useState } from "react";
import DisplaySign from "@/components/custom/DisplaySign";
import Keyboard from "@/components/custom/Keyboard";
import ScreenWrapper from "@/Layouts/ScreenWrapper";
import { lettersKeyboard } from "@/Api/APICalls";
import BlurWrapper from "@/Layouts/BlurWrapper";

const Letters = () => {
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [letter, setLetter] = useState("");

  const handleKeyClick = async (letter: string) => {
    const response = await lettersKeyboard(letter);
    setLetter(letter);
    setImageUrl(response?.data ?? null);
  };

  return (
    <ScreenWrapper>
      <div className="w-full h-full flex flex-col   py-[10vh]">
        <h1 className="text-6xl text-white mt-4 mb-4">
          لوحة مفاتيح لغة الاشارة العربية
        </h1>
        <h2 className="text-3xl text-[#A9A9A9] mb-4">
          انقر علي الحرف لعرض الاشارة
        </h2>

        <BlurWrapper className="mt-4">
          <DisplaySign imageUrl={imageUrl} letter={letter} />
          <Keyboard onKeyPress={handleKeyClick} />
        </BlurWrapper>
      </div>
    </ScreenWrapper>
  );
};

export default Letters;
