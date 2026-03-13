import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/widgets/TextField_button.dart';
import 'package:graduationproject/core/widgets/primary_button.dart';
import 'package:graduationproject/features/auth/controller/auth_controller.dart';
import 'package:graduationproject/features/auth/view/reset_email_screen.dart';
import 'package:graduationproject/features/signup_screen/presentation_layer/signupscreemView.dart';

class LoginScreenBody extends StatefulWidget {
  const LoginScreenBody({super.key});

  @override
  State<LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<LoginScreenBody> {
  final AuthController controller = Get.put(AuthController());

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Top Image
        Positioned(
          top: -40.h,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 240.h,
            width: double.infinity,
            child: Image.asset(
              AppAssets.Signin_image,
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// Form Container
        Positioned(
          top: 200.h,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35.r),
                topRight: Radius.circular(35.r),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'اسم المستخدم',
                    hintText: 'ادخل اسم المستخدم',
                    controller: userNameController,
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 20.h),

                  /// Password مع isPassword بدل obscureText
                  CustomTextField(
                    label: 'كلمة المرور',
                    hintText: 'ادخل كلمة المرور',
                    controller: passwordController,
                    isPassword: true,
                  ),

                  SizedBox(height: 6.h),

                  /// Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetEmailScreen(),
                        ),
                      ),
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15.h),

                  /// Login Button
                  Obx(() => PrimaryButton(
                        buttonText: controller.isLoading.value
                            ? 'جاري التحميل...'
                            : 'تسجيل الدخول',
                        icon: SvgPicture.asset(
                          AppAssets.iconarrow,
                          width: 20.w,
                          height: 20.h,
                        ),
                        onPress: controller.isLoading.value
                            ? () {}
                            : () => controller.login(
                                  userNameController.text.trim(),
                                  passwordController.text.trim(),
                                ),
                      )),

                  SizedBox(height: 24.h),

                  /// Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          'تسجيل الدخول بواسطة',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  /// Google Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => controller.loginWithGoogle(),
                        child: _socialButton(AppAssets.GoogleIcon),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  /// Create Account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ليس لديك حساب؟ ',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreenView(),
                          ),
                        ),
                        child: Text(
                          'أنشئ حساب جديد',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(String image) {
    return Container(
      width: 55.w,
      height: 55.h,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: SvgPicture.asset(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}