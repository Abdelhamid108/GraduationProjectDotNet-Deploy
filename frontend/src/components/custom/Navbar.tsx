import logo from "@/assets/logo.png";
import { useEffect, useState } from "react";
import LoginButton from "../auth/LoginButton";
import ProfileWidget from "./ProfileWidget";
import { NavLink } from "react-router-dom";
import { getAccessToken } from "@/api/AuthSession";
import { userProfile, type UserProfileDTO } from "@/api/APICalls";

// ─── Extracted exact values from Frame_218.svg ───────────────────────────────
// Canvas: 1280 × 120px
// White card: 0,0 → 1280,90  border-radius bottom: 10px
// Logo rect: x=100, w=92, h=100  (with drop-shadow dy=6 blur=5)
// Nav text colors: active=#19156C  inactive=#28353D
// Avatar circle: cx=1135, cy=50, r=45  (drop-shadow dy=6 blur=5)
// Bottom dark shadow band visible under the card
// ─────────────────────────────────────────────────────────────────────────────

export default function Navbar() {
  const [active, setActive] = useState("الرئيسية");
  const [profileWidgetIsOpen, setProfileWidgetIsOpen] = useState(false);
  const [profile, setProfile] = useState<UserProfileDTO | null>(null);
  const [imageFailed, setImageFailed] = useState(false);

  const isLoggedIn = !!getAccessToken();

  useEffect(() => {
    if (!isLoggedIn) {
      setProfile(null);
      return;
    }

    const loadProfile = async () => {
      try {
        const response = await userProfile();
        setProfile(response.data ?? null);
      } catch (error) {
        console.error("Error loading user profile:", error);
        setProfile(null);
      }
    };

    void loadProfile();
  }, [isLoggedIn]);

  const links = [
    { id: "instructions", label: "الارشادات" },
    { id: "letters", label: "الحروف" },
    { id: "", label: "الرئيسية" },
  ];

  const handleClick = () => {
    if (!isLoggedIn) return;
    setProfileWidgetIsOpen((prev) => !prev);
  };

  const displayName =
    profile?.fullName?.trim() || profile?.userName?.trim() || "المستخدم";

  const initialLetter = displayName.trim().charAt(0).toUpperCase();

  const hasProfileImage = !!profile?.userBase64Image && !imageFailed;

  return (
    <header
      className="fixed top-0 flex h-[100px] w-full justify-center overflow-visible rounded-b-[10px] bg-white p-4 px-[50px] shadow-[0_10px_20px_rgba(0,0,0,0.25),0_4px_6px_rgba(0,0,0,0.10)]"
      style={{ zIndex: 2 }}
    >
      <div className="relative flex w-full max-w-[1200px] items-center justify-between">
        <div className="flex h-full shrink-0 items-center justify-center filter-[drop-shadow(0_10px_10px_rgba(0,0,0,0.25))]">
          <img
            src={logo}
            alt="EMA2A"
            className="h-full w-full object-contain"
          />
        </div>

        <nav className="flex flex-1 items-center justify-center gap-[60px]">
          {links.map(({ id, label }) => {
            const isActive = active === label;

            return (
              <NavLink
                to={`/${id}`}
                key={id}
                role="button"
                tabIndex={0}
                onClick={() => setActive(label)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") setActive(label);
                }}
                className={`relative cursor-pointer select-none whitespace-nowrap tracking-[0.01em] transition-colors duration-150 hover:text-[#19156C] ${
                  isActive
                    ? "text-[22px] font-black text-[#19156C]"
                    : "text-lg font-normal text-[#28353D]"
                }`}
              >
                {label}
              </NavLink>
            );
          })}
        </nav>

        {isLoggedIn ? (
          <>
            <button
              onClick={handleClick}
              className="aspect-square h-full shrink-0 cursor-pointer overflow-hidden rounded-full filter-[drop-shadow(0_6px_10px_rgba(0,0,0,0.25))]"
              aria-label={displayName}
              type="button"
            >
              {hasProfileImage ? (
                <img
                  src={`data:image/*;base64,${profile?.userBase64Image}`}
                  alt={displayName}
                  className="h-full w-full object-cover"
                  onError={() => setImageFailed(true)}
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center bg-[#e8d5c4] text-xl font-bold text-[#19156C]">
                  {initialLetter}
                </div>
              )}
            </button>

            {profileWidgetIsOpen && (
              <ProfileWidget close={() => setProfileWidgetIsOpen(false)} />
            )}
          </>
        ) : (
          <LoginButton />
        )}
      </div>
    </header>
  );
}
