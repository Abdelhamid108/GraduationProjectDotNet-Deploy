import SignToText from "@/components/custom/SignToText";
import TabComponent from "@/components/custom/TabComponent";
import TextToSign from "@/components/custom/TextToSign";
import { useState } from "react";
import BlurWrapper from "./BlurWrapper";

const MainLayout = () => {
  const [activeTab, setActiveTab] = useState("ar-to-sign");
  return (
    <>
      <div className="relative w-full   flex flex-col items-center justify-center pt-[100px]">
        <h1 className="text-6xl text-[#19156C] mt-4 mb-4">
          لوحة مفاتيح لغة الاشارة العربية
        </h1>
        <h2 className="text-3xl text-[#A9A9A9] mb-4">
          انقر علي الحرف لعرض الاشارة
        </h2>

        <TabComponent activeTabId={activeTab} onTabChange={setActiveTab} />
        <BlurWrapper>
          {activeTab == "ar-to-sign" ? <TextToSign /> : <SignToText />}
        </BlurWrapper>
      </div>
    </>
  );
};

export default MainLayout;
