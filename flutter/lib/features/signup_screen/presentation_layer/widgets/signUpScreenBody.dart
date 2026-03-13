import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/widgets/TextField_button.dart';
import 'package:graduationproject/core/widgets/primary_button.dart';
import 'package:graduationproject/features/auth/controller/auth_controller.dart';

class SignUpScreenBody extends StatefulWidget {
  const SignUpScreenBody({super.key});

  @override
  State<SignUpScreenBody> createState() => _SignUpScreenBodyState();
}

class _SignUpScreenBodyState extends State<SignUpScreenBody> {
  final AuthController controller = Get.put(AuthController());
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    // ✅ تحقق من الحقول الفاضية
    if (fullNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        userNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar('خطأ', 'ادخل كل البيانات',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ تحقق من الباسورد
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&]).{6,}$')
        .hasMatch(passwordController.text)) {
      Get.snackbar(
        'خطأ',
        'كلمة المرور لازم تحتوي على:\n• حرف كبير\n• حرف صغير\n• رقم\n• رمز خاص مثل: Sherine@123',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // ✅ تحقق من تطابق كلمة المرور
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar('خطأ', 'كلمتا المرور غير متطابقتين',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ ابعت الطلب
    controller.register(
      email: emailController.text.trim(),
      fullName: fullNameController.text.trim(),
      userName: userNameController.text.trim(),
      password: passwordController.text.trim(),
      confirmPassword: confirmPasswordController.text.trim(),
      phoneNumber: phoneController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(13.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'الاسم',
              hintText: 'ادخل اسمك',
              controller: fullNameController,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              label: 'رقم الموبايل',
              hintText: 'ادخل رقم الموبايل',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              label: 'اسم المستخدم',
              hintText: 'ادخل اسم المستخدم',
              controller: userNameController,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              label: 'البريد الإلكتروني',
              hintText: 'ادخل البريد الإلكتروني',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              label: 'كلمة المرور',
              hintText: 'مثال: Sherine@123',
              controller: passwordController,
              obscureText: true,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              label: 'تأكيد كلمة المرور',
              hintText: 'ادخل كلمة المرور مرة أخرى',
              controller: confirmPasswordController,
              obscureText: true,
            ),
            SizedBox(height: 32.h),

            /// زر التسجيل
            Obx(() => PrimaryButton(
                  buttonText: controller.isLoading.value
                      ? 'جاري التحميل...'
                      : 'إنشاء حساب',
                  icon: SvgPicture.asset(
                    AppAssets.iconarrow,
                    width: 20.w,
                    height: 20.h,
                  ),
                  onPress: controller.isLoading.value
                      ? () {}
                      : _onRegisterPressed,
                )),

            SizedBox(height: 16.h),

            /// تسجيل دخول
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'بالفعل لديك حساب؟ ',
                  style: TextStyle(fontSize: 12.sp),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'تسجيل دخول',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}