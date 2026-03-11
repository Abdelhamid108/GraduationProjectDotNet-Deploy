import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/style/app_fonts.dart';

class PrimaryOutlinedButton extends StatelessWidget {
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
  const PrimaryOutlinedButton({
    super.key,
    this.buttonText,
    this.icon,
    this.borderColor,
    this.buttonColor,
    this.width,
    this.height,
    this.borderradius,
    this.fontSize,
    this.textColor,
    this.onPress,
    this.fontWeight
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPress,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: buttonColor ?? AppColors.primaryColor,
          width: 2,
        ),
        backgroundColor: buttonColor ?? AppColors.thirdColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderradius ?? 35.r),
        ),
        fixedSize: Size(width ?? 272.w, height ?? 60.w),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            buttonText ?? "",
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize ?? 16.sp,
              fontFamily: AppFonts.mainfontName,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
          if (icon != null) ...[SizedBox(width: 25.w), icon!],
        ],
      ),
    );
  }
}
