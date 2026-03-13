import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final Widget? suffixIcon;
  final double? width;
  final double? height;
  final double? borderradius;
  final bool? isPassword;
  final bool? isPhonenumber;
  const CustomTextField({
    super.key,
    this.hintText,
    this.suffixIcon,
    this.width,
    this.height,
    this.borderradius,
    this.isPassword,
    this.isPhonenumber,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 315,
      height: height ?? 81,
      child: TextField(
        autofocus: false,
        obscureText: isPassword ?? false,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          hintText: hintText ?? "",
          hintStyle: TextStyle(
            fontSize: 15.sp,
            color: const Color(0xffD9D9D9),
            fontWeight: FontWeight.w400,
          ),
          contentPadding: EdgeInsets.symmetric(),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: BorderSide(color: const Color(0xff8C8C8C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
