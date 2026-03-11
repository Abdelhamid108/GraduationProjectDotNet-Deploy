import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/widgets/spacing_widgets.dart';
import 'package:graduationproject/core/widgets/login_button.dart';
import 'package:graduationproject/core/widgets/primary_outlined_button.dart';
import 'package:graduationproject/features/lognIn_screen/presentation_layer/loginScreenView.dart';
import 'package:graduationproject/features/signup_screen/presentation_layer/signupscreemView.dart';

class SplashScreenBody extends StatelessWidget {
  const SplashScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background image
          Column(
            children: [
              HeightSpace(50.h),
              Image.asset(
                AppAssets.LoginImage,
                width: 375.w,
                height: 240.h,
                fit: BoxFit.fill,
              ),
            ],
          ),

          /// SVG Shape
          Positioned(
            top: 430.h,
            left: -20.w,
            child: SizedBox(
              width: double.infinity,
              height: 470.h,
              child: SvgPicture.asset(
                'assets/icons/my_shape.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Tagline Text
          Positioned(
            top: 390.h,
            left: 80.w,
            right: 60.w,
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '«',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.primaryColor,
                      ),
                    ),
                    TextSpan(
                      text: 'تعلم لغة الإشارة العربية بسهولة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.primaryColor,
                      ),
                    ),
                    TextSpan(
                      text: ' » ',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Buttons
          Positioned(
            top: 601.h,
            left: 47.w,
            child: Column(
              children: [
                /// Log in Button
                LoginButton(
                  buttonText: 'Log in',
                  width: 304.w,
                  height: 76.h,
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreenView(),
                      ),
                    );
                  },
                ),

                HeightSpace(15.h),

                /// Sign Up Button
                PrimaryOutlinedButton(
                  buttonText: 'Sign Up',
                  width: 304.w,
                  height: 76.h,
                  textColor: AppColors.primaryColor,
                  buttonColor: AppColors.thirdColor,
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreenView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}