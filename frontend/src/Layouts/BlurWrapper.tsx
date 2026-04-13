import { twMerge } from "tailwind-merge";

const BlurWrapper = ({ children, className }) => {
  return (
    <section
      className={twMerge(
        "flex flex-col items-center justify-center w-full gap-10 backdrop-blur-sm rounded-3xl p-16 bg-white/30 mb-16 mt-16",
        className,
      )}
    >
      {children}
    </section>
  );
};

export default BlurWrapper;
