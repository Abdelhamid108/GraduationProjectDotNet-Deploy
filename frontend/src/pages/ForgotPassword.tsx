import boykid from "@/assets/boy kid.jpg";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import { FormInput } from "@/components/auth/FormInput";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
const ForgotPassword = () => {
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // Handle login
  };

  return (
    <AuthPagesLayout img={boykid}>
      <AuthFormCard
        title="نسيت كلمة المرور"
        submitLabel="ادخل البريد الإلكتروني"
        onSubmit={handleSubmit}
      >
        <FormInput
          label="البريد الإلكتروني"
          placeholder="ادخل البريد الإلكتروني"
          name="username"
        />
      </AuthFormCard>
    </AuthPagesLayout>
  );
};

export default ForgotPassword;
