import type { ReactNode } from "react";

import { Button } from "@/components/ui/button";
import logoImg from "@/assets/logo.png";

type AuthFormCardProps = {
  title: string;
  submitLabel: string;
  onSubmit: (e: React.FormEvent<HTMLFormElement>) => void;
  children: ReactNode;
  footer?: ReactNode;
};

const AuthFormCard = ({
  title,
  submitLabel,
  onSubmit,
  children,
  footer,
}: AuthFormCardProps) => {
  return (
    <div className="flex flex-row justify-center items-center p-9 max-w-[471px] gap-2.5 w-full bg-white shadow-[0px_10px_20px_rgba(0,0,0,0.25)] rounded-[20px]">
      <form
        onSubmit={onSubmit}
        className="flex flex-col items-center gap-[11px] w-full "
      >
        {/* Logo */}
        <div className="flex flex-col items-center gap-0 w-full ">
          <img
            src={logoImg}
            alt="EMA2A"
            className="w-2/5 object-contain drop-shadow-[0px_6px_10px_rgba(0,0,0,0.25)] shrink-0 mb-10"
          />
          {/* Form content */}
          <div className="flex flex-col justify-center items-end gap-[29px] w-full mt-0">
            <div className="flex flex-col justify-center items-end gap-8 w-full">
              {/* Title */}
              <h2 className="w-full text-right font-normal text-xl leading-[37px] text-black font-[Cairo]">
                {title}
              </h2>
              {/* Form inputs (children) */}
              <div className="flex flex-col items-end gap-4 w-full">
                {children}
              </div>
            </div>
            {/* Submit button */}
            <Button type="submit" className="w-full" variant="submit">
              {submitLabel}
            </Button>
          </div>
        </div>
        {footer && (
          <div className="flex flex-col items-center gap-4 w-full mt-4">
            {footer}
          </div>
        )}
      </form>
    </div>
  );
};

export { AuthFormCard };
