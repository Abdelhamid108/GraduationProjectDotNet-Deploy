import MainBackground from "@/assets/MainBackground";
import Navbar from "@/components/custom/Navbar";

const ScreenWrapper = ({ children }) => {
  return (
    <>
      <MainBackground />
      <Navbar />
      <div className="w-full flex justify-center">
        <div className="max-w-[1200px]  w-full min-h-screen flex items-center flex-col justify-center">
          {children}
        </div>
      </div>
    </>
  );
};

export default ScreenWrapper;
