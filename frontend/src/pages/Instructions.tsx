import HowToUSe from "@/components/custom/HowToUse";
import BlurWrapper from "@/Layouts/BlurWrapper";
import ScreenWrapper from "@/Layouts/ScreenWrapper";

const Instructions = () => {
  return (
    <ScreenWrapper>
      <BlurWrapper>
        <HowToUSe />
      </BlurWrapper>
    </ScreenWrapper>
  );
};

export default Instructions;
