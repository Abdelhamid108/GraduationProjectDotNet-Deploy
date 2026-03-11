import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final String? buttonText;
  final Color? buttonColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final void Function()? onPress;

  const CustomButton({
    super.key,
    this.buttonText,
    this.buttonColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: width ?? 66.w,
        height: height ?? 57.h,
        decoration: ShapeDecoration(
          color: buttonColor ?? const Color(0xFF5DBBFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 0.r),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          buttonText ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: fontSize ?? 12.sp,
            fontFamily: 'Poppins',
            fontWeight: fontWeight ?? FontWeight.w600,
          ),
        ),
      ),
    );
  }
}