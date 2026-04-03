import { useNavigate } from "react-router-dom";

export default function LoginButton() {
  const navigate = useNavigate();
  return (
    <button
      type="button"
      className="mx-auto flex h-14 w-[282px] flex-row items-center justify-center gap-2 rounded-[35px] bg-[#19156C] px-0 py-0 text-[20px] font-semibold leading-[37px] text-white shadow-[0px_6px_10px_rgba(0,0,0,0.25)]"
      style={{ fontFamily: "Cairo" }}
      onClick={() => navigate("/login")}
    >
      <span aria-hidden="true" className="hidden h-6 w-6" />
      <span>تسجيل الدخول</span>
    </button>
  );
}
