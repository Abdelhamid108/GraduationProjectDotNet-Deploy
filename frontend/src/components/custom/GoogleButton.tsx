import { twMerge } from "tailwind-merge";

const GoogleButton = ({ onClick, className }) => {
  return (
    <button
      onClick={onClick}
      className={twMerge(
        // Layout & Size (Frame 181 / Button)
        "relative flex items-center justify-center w-[50px] h-[50px] p-0 gap-[15px] flex-none cursor-pointer",
        // Background & Shadow (Rectangle 642)
        "bg-white rounded-[10px] shadow-[0px_0px_5px_3px_rgba(105,105,105,0.1)]",
        // Drop Shadow (Filter)
        "drop-shadow-[0px_6px_10px_rgba(0,0,0,0.25)]",
        // Hover effect for better UX
        "hover:bg-gray-50 transition-colors",
        className,
      )}
      type="button"
    >
      {/* Icon Container (icons8-google-240) */}
      <div className="relative w-[27.27px] h-[27.27px]">
        <svg
          viewBox="0 0 24 24"
          className="w-full h-full"
          xmlns="http://w3.org"
        >
          {/* Simplified Google paths based on your vector colors */}
          <path
            d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
            fill="#1976D2"
          />
          <path
            d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
            fill="#4CAF50"
          />
          <path
            d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
            fill="#FFC107"
          />
          <path
            d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
            fill="#FF3D00"
          />
        </svg>
      </div>
    </button>
  );
};

export default GoogleButton;
