import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
const GoogleCallbackPage = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    // 1. Extract tokens sent from the backend redirect
    const accessToken = searchParams.get("accessToken");
    const refreshToken = searchParams.get("refreshToken");
    const profileImage = searchParams.get("base64Image"); // If passed in URL

    if (accessToken && refreshToken) {
      // 2. Save tokens to your global auth state, localStorage, or cookies
      localStorage.setItem("accessToken", accessToken);
      localStorage.setItem("refreshToken", refreshToken);

      if (profileImage) {
        localStorage.setItem("userImage", profileImage);
      }

      // 3. Send the user to the dashboard or home screen
      navigate("/");
    } else {
      // Handle scenario where backend redirected with an error message parameter
      const errorMsg =
        searchParams.get("error") || "فشل تسجيل الدخول باستخدام جوجل";
      setError(errorMsg);
      toast.error(errorMsg);
    }
  }, [searchParams, navigate]);

  if (error) {
    return (
      <div style={{ textAlign: "center", marginTop: "50px", color: "red" }}>
        <h3>حدث خطأ أثناء تسجيل الدخول</h3>
        <p>{error}</p>
        <button onClick={() => navigate("/login")}>
          العودة لصفحة تسجيل الدخول
        </button>
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
