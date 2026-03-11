import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/style/app_fonts.dart';

class CustomRoundButton extends StatelessWidget {
  final String buttonText;
  final Color? borderColor;
  final Color? buttonColor;
  final double? width;
  final double? height;
  final double? borderradius;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final void Function()? onPress;
  final Widget? icon;

  const CustomRoundButton({
    super.key,
    required this.buttonText,
    this.borderColor,
    this.borderradius,
    this.buttonColor,
    this.fontSize,
    this.fontWeight,
    this.height,
    this.textColor,
    this.onPress,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        side: BorderSide(
          color: borderColor ?? AppColors.primaryColor,
          width: 2,
        ),
        backgroundColor: buttonColor ?? AppColors.thirdColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderradius ?? 35.r),
        ),
        fixedSize: Size(width ?? 197.w, height ?? 24.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Text(
              buttonText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor ?? const Color(0xFF30BBF9),
                fontSize: fontSize ?? 16.sp,
                fontFamily: AppFonts.mainfontName,
                fontWeight: fontWeight ?? FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}