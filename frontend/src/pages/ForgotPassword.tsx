import { useState } from "react";
import boykid from "@/assets/boy kid.jpg";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import { FormInput } from "@/components/auth/FormInput";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
import { getResetPasswordToken, resetPassword } from "@/Api/APICalls"; // Adjust import path as needed
import { useNavigate } from "react-router-dom";

type FlowStep = "REQUEST_TOKEN" | "RESET_PASSWORD";

const ForgotPassword = () => {
  const [step, setStep] = useState<FlowStep>("REQUEST_TOKEN");
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [newPassword, setNewPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const navigate = useNavigate();
  // Step 1: Request the OTP Token
  const handleRequestToken = async () => {
    if (!email) {
      setError("البريد الإلكتروني مطلوب");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await getResetPasswordToken({ Email: email });
      if (response.success && response.data) {
        setSuccessMessage("تم إرسال رمز التحقق إلى بريدك الإلكتروني.");
        setStep("RESET_PASSWORD"); // Move to next step
      } else {
        setError(
          response.errorMessage || "حدث خطأ ما. يرجى المحاولة مرة أخرى.",
        );
      }
    } catch (err) {
      setError("فشل الاتصال بالخادم. يرجى التحقق من الشبكة.");
    } finally {
      setLoading(false);
    }
  };

  // Step 2: Submit OTP and New Password
  const handleResetPassword = async () => {
    if (!otp || !newPassword) {
      setError("جميع الحقول مطلوبة");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await resetPassword({
        OTP: otp,
        NewPassword: newPassword,
      });
      if (response.success && response.data) {
        setSuccessMessage(
          "تم تغيير كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول.",
        );
        navigate("/login");
        // Optional: Redirect to login page here after a brief timeout
      } else {
        setError(
          response.errorMessage || "رمز التحقق غير صحيح أو منتهي الصلاحية.",
        );
      }
    } catch (err) {
      setError("فشل الاتصال بالخادم.");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (step === "REQUEST_TOKEN") {
      handleRequestToken();
    } else {
      handleResetPassword();
    }
  };

  return (
    <AuthPagesLayout img={boykid}>
      {step === "REQUEST_TOKEN" ? (
        <AuthFormCard
          title="نسيت كلمة المرور"
          submitLabel={loading ? "جاري الإرسال..." : "ادخل البريد الإلكتروني"}
          onSubmit={handleSubmit}
        >
          {error && (
            <div style={{ color: "red", marginBottom: "10px" }}>{error}</div>
          )}

          <FormInput
            label="البريد الإلكتروني"
            placeholder="example@mail.com"
            name="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={loading}
          />
        </AuthFormCard>
      ) : (
        <AuthFormCard
          title="إعادة تعيين كلمة المرور"
          submitLabel={loading ? "جاري الحفظ..." : "تغيير كلمة المرور"}
          onSubmit={handleSubmit}
        >
          {successMessage && (
            <div style={{ color: "green", marginBottom: "10px" }}>
              {successMessage}
            </div>
          )}
          {error && (
            <div style={{ color: "red", marginBottom: "10px" }}>{error}</div>
          )}

          <FormInput
            label="رمز التحقق (OTP)"
            placeholder="ادخل الرمز المكون من 6 أرقام"
            name="otp"
            type="text"
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
            disabled={loading}
          />

          <FormInput
            label="كلمة المرور الجديدة"
            placeholder="ادخل كلمة المرور الجديدة"
            name="newPassword"
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            disabled={loading}
          />
        </AuthFormCard>
      )}
    </AuthPagesLayout>
  );
};

export default ForgotPassword;
