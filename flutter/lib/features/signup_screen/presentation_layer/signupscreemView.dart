import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/features/signup_screen/presentation_layer/widgets/signUpScreenBody.dart';


class SignUpScreenView extends StatelessWidget {
  const SignUpScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Padding(
            padding: EdgeInsets.only(top: 34.h),
            child: Text(
              'إنشاء حساب جديد',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xff30BBF9),
              ),
            ),
          ),
        ),
        body: SignUpScreenBody(),
      ),
    );
  }
}