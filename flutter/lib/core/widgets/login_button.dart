import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/style/app_fonts.dart';

class LoginButton extends StatelessWidget {
  final String? buttonText;
  final Color? borderColor;
  final Color? buttonColor;
  final double? width;
  final double? height;
  final double? borderradius;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final void Function()? onPress;
  const LoginButton({
    super.key,
    this.buttonText,
    this.borderColor,
    this.buttonColor,
    this.width,
    this.height,
    this.borderradius,
    this.fontSize,
    this.textColor,
    this.fontWeight,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        side: BorderSide(color:borderColor ?? AppColors.primaryColor,width: 2),
        backgroundColor: buttonColor ?? AppColors.thirdColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderradius ?? 35.r),
        ),
        fixedSize: Size(width ?? 284.w, height ?? 59.w),
      ),

      child: Text(
        buttonText ?? "",
        style: TextStyle(color: textColor ?? Color(0xff30BBF9),
         fontSize: fontSize ?? 16.sp,
              fontFamily: AppFonts.mainfontName,
              fontWeight: fontWeight ?? FontWeight.w600,
        
        ),
      ),
    );
  }
}
