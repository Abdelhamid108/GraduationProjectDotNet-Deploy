import React from "react";

type TabItem = {
  id: string;
  label: string;
  icon: React.ReactNode;
};

type TabComponentProps = {
  tabs?: TabItem[];
  activeTabId: string;
  onTabChange: (tabId: string) => void;
  className?: string;
};

const defaultTabs: TabItem[] = [
  {
    id: "ar-to-sign",
    label: "اللغة العربية إلى إشارة",
    icon: (
      <svg
        viewBox="0 0 32 32"
        className="h-8 w-8"
        fill="none"
        aria-hidden="true"
      >
        <path
          d="M6 17 L14 17 L14 25"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
        <path
          d="M5 12 L16 12 L16 19"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
        <path
          d="M3 7 L19 7"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
        <path
          d="M10 3 L10 8"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
        <path
          d="M16 16 C21 16 24 21 24 26"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
        <path
          d="M19 24 L24 24"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
  {
    id: "sign-to-ar",
    label: "إشارة إلى اللغة العربية",
    icon: (
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M13.997 4C14.3578 3.99999 14.7119 4.09759 15.0217 4.28244C15.3316 4.46729 15.5856 4.73251 15.757 5.05L16.243 5.95C16.4144 6.26749 16.6684 6.53271 16.9783 6.71756C17.2881 6.90241 17.6422 7.00001 18.003 7H20C20.5304 7 21.0391 7.21071 21.4142 7.58579C21.7893 7.96086 22 8.46957 22 9V18C22 18.5304 21.7893 19.0391 21.4142 19.4142C21.0391 19.7893 20.5304 20 20 20H4C3.46957 20 2.96086 19.7893 2.58579 19.4142C2.21071 19.0391 2 18.5304 2 18V9C2 8.46957 2.21071 7.96086 2.58579 7.58579C2.96086 7.21071 3.46957 7 4 7H5.997C6.35742 7.00002 6.71115 6.90264 7.02078 6.71817C7.33041 6.53369 7.58444 6.26897 7.756 5.952L8.245 5.048C8.41656 4.73103 8.67059 4.46631 8.98022 4.28183C9.28985 4.09736 9.64358 3.99998 10.004 4H13.997Z"
          stroke="currentColor"
          stroke-width="3"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M12 16C13.6569 16 15 14.6569 15 13C15 11.3431 13.6569 10 12 10C10.3431 10 9 11.3431 9 13C9 14.6569 10.3431 16 12 16Z"
          stroke="currentColor"
          stroke-width="3"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    ),
  },
];

export function TabComponent({
  tabs = defaultTabs,
  activeTabId,
  onTabChange,
  className = "",
}: TabComponentProps) {
  return (
    <div
      className={[
        "mx-auto flex h-32 w-full  items-center justify-center gap-[208px] rounded-[20px] bg-white p-0 shadow-[0px_10px_10px_rgba(0,0,0,0.25)]",
        className,
      ].join(" ")}
      role="tablist"
      aria-label="Language direction tabs"
    >
      {tabs.map((tab) => {
        const isActive = tab.id === activeTabId;

        return (
          <button
            key={tab.id}
            role="tab"
            aria-selected={isActive}
            onClick={() => onTabChange(tab.id)}
            className={[
              "flex w-[344px] flex-col items-center justify-center rounded-[10px] px-2 text-center font-medium transition-colors",
              isActive
                ? "h-[100px] bg-[#19156C] text-white"
                : "h-[81px] text-[#1B8CC0] hover:bg-[#F2F7FB]",
            ].join(" ")}
          >
            <span className={isActive ? "text-white" : "text-[#1B8CC0]"}>
              {tab.icon}
            </span>
            <span className="font-cairo text-2xl leading-[45px]">
              {tab.label}
            </span>
          </button>
        );
      })}
    </div>
  );
}

export default TabComponent;
