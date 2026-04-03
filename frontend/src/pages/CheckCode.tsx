import girlKid from "@/assets/gril kid.jpg";
import { AuthFormCard } from "@/components/auth/AuthFormCard";
import {
  InputOTP,
  InputOTPGroup,
  InputOTPSeparator,
  InputOTPSlot,
} from "@/components/ui/input-otp";
import AuthPagesLayout from "@/Layouts/AuthPagesLayout";
const CheckCode = () => {
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // Handle login
  };

  return (
    <AuthPagesLayout img={girlKid}>
      <AuthFormCard
        title="الرمز المكون من 6 أرقام"
        submitLabel="تحقق"
        onSubmit={handleSubmit}
      >
        <InputOTP maxLength={6}>
          <InputOTPGroup>
            <InputOTPSlot index={0} />
            <InputOTPSeparator />
            <InputOTPSlot index={1} />
            <InputOTPSeparator />
            <InputOTPSlot index={2} />
            <InputOTPSeparator />
            <InputOTPSlot index={3} />
            <InputOTPSeparator />
            <InputOTPSlot index={4} />
            <InputOTPSeparator />
            <InputOTPSlot index={5} />
          </InputOTPGroup>
        </InputOTP>
      </AuthFormCard>
    </AuthPagesLayout>
  );
};

export default CheckCode;
