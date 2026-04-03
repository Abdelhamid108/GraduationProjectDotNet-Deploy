import girlKid from "@/assets/gril kid.jpg";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import { FormInput } from "@/components/auth/FormInput";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
const Signup = () => {
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // Handle login
  };

  return (
    <AuthPagesLayout img={girlKid}>
      <AuthFormCard
        title="إعادة تعيين كلمة المرور"
        submitLabel="إعادة تعيين كلمة المرور"
        onSubmit={handleSubmit}
      >
        <FormInput
          label="البريد الإلكتروني"
          placeholder="ادخل البريد الإلكتروني"
          name="email"
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
