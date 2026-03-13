import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final double? width;
  final double? height;
  final TextInputType? keyboardType;
  final bool isPassword;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.width,
    this.height,
    this.keyboardType,
    this.isPassword = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> obscureNotifier =
        ValueNotifier(isPassword ? true : obscureText);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Label
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.mainfontName,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xff121212),
            ),
          ),

          SizedBox(height: 6.h),

          /// TextField
          SizedBox(
            width: width ?? double.infinity,
            child: ValueListenableBuilder<bool>(
              valueListenable: obscureNotifier,
              builder: (context, isObscure, child) {
                return TextField(
                  controller: controller,
                  obscureText: isObscure,
                  keyboardType: keyboardType,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFonts.mainfontName,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.mainfontName,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    constraints: BoxConstraints(
                      minHeight: height ?? 56.h,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 0,
                    ),

                    /// 👇 هنا بقى العين
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              obscureNotifier.value = !isObscure;
                            },
                          )
                        : suffixIcon,

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35.r),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF30BBF9),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}