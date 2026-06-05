import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
const GoogleCallbackPage = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<boolean>(false);
  const [countdown, setCountdown] = useState<number>(5);

  useEffect(() => {
    // 1. Extract tokens sent from the backend redirect
    const accessToken = searchParams.get("accessToken");
    const refreshToken = searchParams.get("refreshToken");
    const profileImage = searchParams.get("base64Image"); // If passed in URL

    let intervalId: number | undefined;

    if (accessToken && refreshToken) {
      // 2. Save tokens to your global auth state, localStorage, or cookies
      localStorage.setItem("accessToken", accessToken);
      localStorage.setItem("refreshToken", refreshToken);

      if (profileImage) {
        localStorage.setItem("userImage", profileImage);
      }

      // Indicate success and start countdown to redirect to home
      setSuccess(true);
      setCountdown(5);
      intervalId = window.setInterval(() => {
        setCountdown((c) => {
          if (c <= 1) {
            if (intervalId) clearInterval(intervalId);
            navigate("/");
            return 0;
          }
          return c - 1;
        });
      }, 1000) as unknown as number;
    } else {
      // Handle scenario where backend redirected with an error message parameter
      const errorMsg =
        searchParams.get("error") || "فشل تسجيل الدخول باستخدام جوجل";
      setError(errorMsg);
      toast.error(errorMsg);

      // Start countdown to redirect to login page
      setCountdown(5);
      intervalId = window.setInterval(() => {
        setCountdown((c) => {
          if (c <= 1) {
            if (intervalId) clearInterval(intervalId);
            navigate("/login");
            return 0;
          }
          return c - 1;
        });
      }, 1000) as unknown as number;
    }

    return () => {
      if (intervalId) clearInterval(intervalId);
    };
  }, [searchParams, navigate]);

  if (error) {
    return (
      <div style={{ textAlign: "center", marginTop: "50px", color: "red" }}>
        <h3>حدث خطأ أثناء تسجيل الدخول</h3>
        <p>{error}</p>
        <p>إعادة التوجيه إلى صفحة تسجيل الدخول خلال {countdown} ثانية.</p>
        <div style={{ marginTop: 12 }}>
          <button onClick={() => navigate("/login")}>الذهاب الآن</button>
        </div>
      </div>
    );
  }

  if (success) {
    return (
      <div style={{ textAlign: "center", marginTop: "50px", color: "green" }}>
        <h3>تم تسجيل الدخول بنجاح</h3>
        <p>سيتم تحويلك إلى الصفحة الرئيسية خلال {countdown} ثانية.</p>
        <div style={{ marginTop: 12 }}>
          <button onClick={() => navigate("/")}>الذهاب الآن</button>
        </div>
      </div>
    );
  }

  // Display a loading spinner while processing the URL parameters
  return (
    <div style={{ textAlign: "center", marginTop: "50px" }}>
      <h3>جاري التحقق من الحساب...</h3>
      <p>يرجى الانتظار للحظات.</p>
    </div>
  );
};

export default GoogleCallbackPage;
