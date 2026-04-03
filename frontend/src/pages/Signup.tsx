import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import { FormInput } from "@/components/auth/FormInput";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
import girlKidImg from "@/assets/girl kid X.jpg";
import { registerUser } from "@/Api/APICalls";
import { toast } from "sonner";

const Signup = () => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    const formValues = new FormData(e.currentTarget);
    const Password = String(formValues.get("password") ?? "");
    const confirmPassword = String(formValues.get("confirm_password") ?? "");

    if (Password !== confirmPassword) {
      return;
    }

    setIsSubmitting(true);

    try {
      await registerUser({
        Email: String(formValues.get("email") ?? ""),
        FullName: String(formValues.get("fullName") ?? ""),
        UserName: String(formValues.get("username") ?? ""),
        Password,
        PhoneNumber: String(formValues.get("phone") ?? ""),
        UserImage: (formValues.get("userImage") as File) || undefined,
      });

      toast.success("تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.");

      navigate("/login");
    } catch (error: any) {
      console.error("Error registering user:", error);

      toast.error(error?.message || "حدث خطأ أثناء إنشاء المستخدم");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AuthPagesLayout img={girlKidImg}>
      <AuthFormCard
        title="انشئ حساب جديد"
        submitLabel={isSubmitting ? "جاري إنشاء الحساب..." : "انشئ حساب جديد"}
        onSubmit={handleSubmit}
        footer={
          <>
            <div className="flex flex-row justify-between items-center gap-1.5 w-[123px]">
              <div className="w-[50px] h-px bg-[#D9D9D9] border border-[#D9D9D9]" />
              <span className="font-['Poppins'] font-medium text-[11px] leading-4 text-[#ACA6A6]">
                or
              </span>
              <div className="w-[49px] h-px bg-[#D9D9D9] border border-[#D9D9D9]" />
            </div>
            <div className="flex flex-row justify-center items-center gap-2 w-full">
              <span className="font-['Cairo'] font-normal text-xs leading-[22px] text-[#757373]">
                لديك حساب بالفعل؟
              </span>
              <Link
                to="/login"
                className="font-['Cairo'] font-bold text-base leading-[30px] text-[#1A156C] hover:underline"
              >
                تسجيل الدخول
              </Link>
            </div>
          </>
        }
      >
        <FormInput
          label="الاسم الكامل"
          placeholder="ادخل الاسم الكامل"
          name="fullName"
        />

        <FormInput
          label="اسم المستخدم"
          placeholder="ادخل اسم المستخدم"
          name="username"
        />

        <FormInput
          label="رقم الهاتف"
          placeholder="ادخل رقم الهاتف"
          name="phone"
        />

        <FormInput
          label="البريد الإلكتروني"
          placeholder="ادخل البريد الإلكتروني"
          name="email"
        />

        <FormInput
          label="الصورة الشخصية (اختياري)"
          type="file"
          name="userImage"
        />

        <div className="flex flex-col items-end gap-4 w-full">
          <FormInput
            label="كلمة المرور"
            type="password"
            placeholder="ادخل كلمة المرور"
            name="password"
          />
          <FormInput
            label="تأكيد كلمة المرور"
            type="password"
            placeholder="ادخل تأكيد كلمة المرور"
            name="confirm_password"
          />
        </div>
      </AuthFormCard>
    </AuthPagesLayout>
  );
};

export default Signup;
