import {
  normalizeTokenSession,
  persistAuthSession,
  type TokenResponseDTO,
} from "@/Api/AuthSession";
import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { Loader2, CheckCircle2, AlertCircle } from "lucide-react";

// Custom hook for countdown logic
const useCountdown = (initialCount: number, onComplete: () => void) => {
  const [count, setCount] = useState(initialCount);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setCount((prev) => {
        if (prev <= 1) {
          if (intervalRef.current) clearInterval(intervalRef.current);
          onComplete();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [onComplete]);

  return count;
};

// Loading state component
const LoadingState = () => (
  <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-slate-900 dark:to-slate-800">
    <div className="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-8 max-w-md w-full mx-4">
      <div className="flex justify-center mb-6">
        <Loader2 className="w-12 h-12 text-blue-600 dark:text-blue-400 animate-spin" />
      </div>
      <h2 className="text-center text-xl font-semibold text-gray-900 dark:text-white mb-2">
        جاري التحقق من الحساب
      </h2>
      <p className="text-center text-gray-600 dark:text-gray-300">
        يرجى الانتظار للحظات...
      </p>
    </div>
  </div>
);

// Success state component
const SuccessState = ({
  countdown,
  onNavigate,
}: {
  countdown: number;
  onNavigate: () => void;
}) => (
  <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-green-50 to-emerald-100 dark:from-slate-900 dark:to-slate-800">
    <div className="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-8 max-w-md w-full mx-4 text-center">
      <div className="flex justify-center mb-6">
        <CheckCircle2 className="w-16 h-16 text-green-600 dark:text-green-400" />
      </div>
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
        تم تسجيل الدخول بنجاح
      </h2>
      <p className="text-gray-600 dark:text-gray-300 mb-6">
        سيتم تحويلك إلى الصفحة الرئيسية خلال {countdown}{" "}
        {countdown === 1 ? "ثانية" : "ثوان"}.
      </p>
      <button
        onClick={onNavigate}
        className="w-full px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors duration-200"
      >
        الذهاب الآن
      </button>
    </div>
  </div>
);

// Error state component
const ErrorState = ({
  error,
  countdown,
  onNavigate,
}: {
  error: string;
  countdown: number;
  onNavigate: () => void;
}) => (
  <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-red-50 to-rose-100 dark:from-slate-900 dark:to-slate-800">
    <div className="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-8 max-w-md w-full mx-4 text-center">
      <div className="flex justify-center mb-6">
        <AlertCircle className="w-16 h-16 text-red-600 dark:text-red-400" />
      </div>
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
        حدث خطأ أثناء تسجيل الدخول
      </h2>
      <p className="text-gray-600 dark:text-gray-300 mb-4 break-words">
        {error}
      </p>
      <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">
        إعادة التوجيه إلى صفحة تسجيل الدخول خلال {countdown}{" "}
        {countdown === 1 ? "ثانية" : "ثوان"}.
      </p>
      <button
        onClick={onNavigate}
        className="w-full px-6 py-3 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors duration-200"
      >
        الذهاب الآن
      </button>
    </div>
  </div>
);

// Main component
const GoogleCallbackPage = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [state, setState] = useState<"loading" | "success" | "error">(
    "loading",
  );
  const [error, setError] = useState<string>("");

  // Handle successful login
  const handleSuccess = () => {
    navigate("/");
  };

  // Handle failed login
  const handleError = () => {
    navigate("/login");
  };

  const countdown = useCountdown(
    5,
    state === "success" ? handleSuccess : handleError,
  );

  useEffect(() => {
    // Extract tokens from URL parameters
    const accessToken = searchParams.get("accessToken");
    const refreshToken = searchParams.get("refreshToken");
    const accessTokenExpires = searchParams.get("accessTokenExpires");
    const refreshTokenExpires = searchParams.get("refreshTokenExpires");
    const profileImage = searchParams.get("base64Image");

    // Check for error parameter
    const errorParam = searchParams.get("error");

    if (errorParam) {
      setError(errorParam);
      setState("error");
      toast.error(errorParam);
      return;
    }

    // Validate all required tokens are present
    if (
      !accessToken ||
      !refreshToken ||
      !accessTokenExpires ||
      !refreshTokenExpires
    ) {
      const errorMsg = "فشل الحصول على بيانات المصادقة من الخادم";
      setError(errorMsg);
      setState("error");
      toast.error(errorMsg);
      return;
    }

    try {
      // Process tokens
      const tokenResponse: TokenResponseDTO = {
        accessToken,
        refreshToken,
        accessTokenExpires,
        refreshTokenExpires,
      };

      normalizeTokenSession(tokenResponse);
      persistAuthSession(tokenResponse);

      // Store profile image if provided
      if (profileImage) {
        localStorage.setItem("userImage", profileImage);
      }

      setState("success");
      toast.success("تم تسجيل الدخول بنجاح");
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : "فشل تسجيل الدخول";
      setError(errorMsg);
      setState("error");
      toast.error(errorMsg);
    }
  }, [searchParams]);

  return (
    <>
      {state === "loading" && <LoadingState />}
      {state === "success" && (
        <SuccessState countdown={countdown} onNavigate={handleSuccess} />
      )}
      {state === "error" && (
        <ErrorState
          error={error}
          countdown={countdown}
          onNavigate={handleError}
        />
      )}
    </>
  );
};

export default GoogleCallbackPage;
