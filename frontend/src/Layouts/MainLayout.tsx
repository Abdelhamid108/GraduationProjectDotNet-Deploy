import SignToText from "@/components/custom/SignToText";
import TabComponent from "@/components/custom/TabComponent";
import TextToSign from "@/components/custom/TextToSign";
import { useState } from "react";
import BlurWrapper from "./BlurWrapper";

const MainLayout = ({
  header = (
    <h1 className="text-6xl text-white mt-4 mb-4">
      اهلا بكم في إيماءة{" "}
      <span className="text-[#FFCC00] text-[40px]">(صوت لمن لا صوت له)</span>
    </h1>
  ),
}) => {
  const [activeTab, setActiveTab] = useState("ar-to-sign");
  return (
    <>
      <div className="relative w-full   flex flex-col items-center justify-center pt-[100px]">
        {header}

        <TabComponent activeTabId={activeTab} onTabChange={setActiveTab} />
        <BlurWrapper>
          {activeTab == "ar-to-sign" ? <TextToSign /> : <SignToText />}
        </BlurWrapper>
      </div>
    </>
  );
};

export default MainLayout;
