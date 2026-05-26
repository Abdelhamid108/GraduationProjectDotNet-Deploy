import { useState } from "react";
import girlKid from "@/assets/gril kid.jpg";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import { FormInput } from "@/components/auth/FormInput";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
import { changePassword } from "@/Api/APICalls"; // Update this path to where changePassword is located
import { toast } from "sonner";

const ChangePassword = () => {
  const [formData, setFormData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setSuccess(false);

    // 1. Client-side validation: Check if new passwords match
    if (formData.newPassword !== formData.confirmPassword) {
      setError("كلمة المرور الجديدة وتأكيدها غير متطابقين.");
      return;
    }

    // 2. Client-side validation: Ensure fields aren't empty
    if (!formData.currentPassword || !formData.newPassword) {
      setError("برجاء ملء جميع الحقول.");
      return;
    }

    try {
      setLoading(true);

      // Match the DTO structure expected by your changePassword function
      const response = await changePassword({
        currentPassword: formData.currentPassword,
        newPassword: formData.newPassword,
      });

      if (response.success) {
        // Adjust 'success' based on your actual APIResponseDTO structure
        setSuccess(true);
        setFormData({
          currentPassword: "",
          newPassword: "",
          confirmPassword: "",
        });
        toast.success("تم تغيير كلمة المرور بنجاح!");
      } else {
        setError(response.message || "حدث خطأ ما أثناء تغيير كلمة المرور.");
      }
    } catch (err: any) {
      setError(err?.message || "فشل الاتصال بالخادم. حاول مرة أخرى.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthPagesLayout img={girlKid}>
      <AuthFormCard
        title="تغيير كلمة المرور"
        submitLabel={loading ? "جاري الحفظ..." : "تحديث كلمة المرور"}
        onSubmit={handleSubmit}
        disabled={loading}
      >
        {/* Error Message Display */}
        {error && (
          <div
            className="w-full text-right text-red-500 text-sm font-medium mb-2"
            dir="rtl"
          >
            {error}
          </div>
        )}

        {/* Success Message Display */}
        {success && (
          <div
            className="w-full text-right text-green-600 text-sm font-medium mb-2"
            dir="rtl"
          >
            تم تغيير كلمة المرور بنجاح!
          </div>
        )}

        <div className="flex flex-col items-end gap-4 w-full" dir="rtl">
          <FormInput
            label="كلمة المرور الحالية"
            type="password"
            placeholder="ادخل كلمة المرور الحالية"
            name="currentPassword"
            value={formData.currentPassword}
            onChange={handleChange}
          />

          <FormInput
            label="كلمة المرور الجديدة"
            type="password"
            placeholder="ادخل كلمة المرور الجديدة"
            name="newPassword"
            value={formData.newPassword}
            onChange={handleChange}
          />

          <FormInput
            label="تأكيد كلمة المرور الجديدة"
            type="password"
            placeholder="أعد كتابة كلمة المرور الجديدة"
            name="confirmPassword"
            value={formData.confirmPassword}
            onChange={handleChange}
          />
        </div>
      </AuthFormCard>
    </AuthPagesLayout>
  );
};

export default ChangePassword;
