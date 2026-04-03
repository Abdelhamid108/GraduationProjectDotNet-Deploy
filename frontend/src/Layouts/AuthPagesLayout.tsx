import type { ReactNode } from "react";
import AuthBackground from "../assets/AuthBackground";
import boyKidImg from "../assets/boy kid.jpg";

type AuthPagesLayoutProps = {
  children: ReactNode;
  title?: string;
  img?: string;
};

const AuthPagesLayout = ({
  children,
  title = "نرافقك في رحلتك لتتجاوز الحواجز",
  img = boyKidImg,
}: AuthPagesLayoutProps) => {
  return (
    <>
      <AuthBackground />
      <div className="grid grid-cols-2  w-full p-12 gap-6 h-full box-border">
        {/* Left component - auth form content */}
        <div className="flex items-center justify-center min-h-0  z-10">
          {children}
        </div>

        {/* Right component - glassmorphism wrapper fills whole right area */}
        <div className="h-full flex items-center justify-center">
          <div className="h-3/4 min-h-0 flex overflow-hidden w-full">
            <div className="w-full h-full min-h-0 p-18 rounded-3xl border border-white/30 backdrop-blur-[13px] bg-white/8 flex flex-col gap-8 overflow-hidden box-border">
              <h2 className="m-0 text-white text-4xl font-bold leading-snug text-right shrink-0">
                <span className="block">{title}</span>
              </h2>
              <div className="flex-1 min-h-0 rounded-4xl overflow-hidden ">
                <img
                  src={img}
                  alt=""
                  className="w-full h-full object-cover object-bottom"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default AuthPagesLayout;
