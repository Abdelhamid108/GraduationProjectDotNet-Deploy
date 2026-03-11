import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String? buttonText;
  final Widget? icon;
  final Color? borderColor;
  final Color? buttonColor;
  final double? width;
  final double? height;
  final double? borderradius;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final void Function()? onPress;

  const PrimaryButton({
    super.key,
    this.buttonText,
    this.icon,
    this.borderColor,
    this.buttonColor,
    this.width,
    this.height,
    this.fontWeight,
    this.borderradius,
    this.fontSize,
    this.textColor,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPress,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: borderColor ?? buttonColor ?? AppColors.primaryColor,
          width: 2,
        ),
        backgroundColor: buttonColor ?? AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderradius ?? 35.r),
        ),
        fixedSize: Size(width ?? 315.w, height ?? 60.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[  // ⬅️ الأيقونة الأول (يمين)
            icon!,
            SizedBox(width: 30.w),
          ],
          Text(
            buttonText ?? "",
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize ?? 16.sp,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}