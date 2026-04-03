import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import { FormInput } from "@/components/auth/FormInput";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
import girlKidImg from "@/assets/gril kid.jpg";
import { loginUser } from "@/Api/APICalls";
import {
  clearAuthSession,
  hasUsableRefreshToken,
  persistAuthSession,
  type TokenResponseDTO,
} from "@/Api/AuthSession";
import { toast } from "sonner";

const Login = () => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const navigate = useNavigate();
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    const formData = new FormData(e.currentTarget);
    const username = String(formData.get("username") ?? "").trim();
    const password = String(formData.get("password") ?? "");

    if (!username || !password) {
      setErrorMessage("يرجى إدخال اسم المستخدم وكلمة المرور.");
      return;
    }

    setErrorMessage(null);

    try {
      setIsSubmitting(true);

      const response = await loginUser({ userName: username, password });

      if (!response?.success || !response?.data) {
        clearAuthSession();
        setErrorMessage(
          response?.errorMessage || "فشل تسجيل الدخول. حاول مرة أخرى.",
        );
        return;
      }

      if (!persistAuthSession(response.data as TokenResponseDTO)) {
        clearAuthSession();
        setErrorMessage("استجابة تسجيل الدخول غير مكتملة.");
        return;
      }

      if (!hasUsableRefreshToken()) {
        clearAuthSession();
        setErrorMessage("انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.");
        return;
      }

      toast.success("تم تسجيل الدخول بنجاح!");

      navigate("/");
      // TODO: navigate user to dashboard after successful authentication.
    } catch {
      clearAuthSession();
      setErrorMessage("حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AuthPagesLayout img={girlKidImg}>
      <AuthFormCard
        title="تسجيل الدخول"
        submitLabel={isSubmitting ? "جارِ تسجيل الدخول..." : "تسجيل الدخول"}
        onSubmit={handleSubmit}
        footer={
          <>
            {/* Or divider */}
            <div className="flex flex-row justify-between items-center gap-1.5 w-[123px]">
              <div className="w-[50px] h-px bg-[#D9D9D9] border border-[#D9D9D9]" />
              <span className="font-['Poppins'] font-medium text-[11px] leading-4 text-[#ACA6A6]">
                or
              </span>
              <div className="w-[49px] h-px bg-[#D9D9D9] border border-[#D9D9D9]" />
            </div>
            {/* Sign up link */}
            <div className="flex flex-row justify-center items-center gap-2 w-full">
              <span className="font-['Cairo'] font-normal text-xs leading-[22px] text-[#757373]">
                ليس لديك حساب؟
              </span>
              <Link
                to="/signup"
                className="font-['Cairo'] font-bold text-base leading-[30px] text-[#1A156C] hover:underline"
              >
                أنشئ حساب جديد
              </Link>
            </div>
          </>
        }
      >
        <FormInput
          label="اسم المستخدم"
          placeholder="ادخل اسم المستخدم"
          name="username"
        />
        <div className="flex flex-col items-end gap-4 w-full">
          <FormInput
            label="كلمة المرور"
            type="password"
            placeholder="ادخل كلمة المرور"
            name="password"
          />
          <a
            href="#"
            className="w-full text-right font-['El Messiri'] font-normal text-sm leading-[22px] text-[#93A494] underline"
          >
            نسيت كلمة المرور
          </a>
        </div>
        {errorMessage ? (
          <p className="w-full text-right text-sm text-red-600">
            {errorMessage}
          </p>
        ) : null}
      </AuthFormCard>
    </AuthPagesLayout>
  );
};

export default Login;
