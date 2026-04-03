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
      <div className="w-full h-full flex flex-col gap-10  py-[10vh]">
        <BlurWrapper>
          <DisplaySign imageUrl={imageUrl} letter={letter} />
          <Keyboard onKeyPress={handleKeyClick} />
        </BlurWrapper>
      </div>
    </ScreenWrapper>
  );
};

export default Letters;
