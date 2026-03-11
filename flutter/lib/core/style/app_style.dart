import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/style/app_fonts.dart';

class AppStyle {
  static TextStyle dataLineStyle = TextStyle(
    fontFamily: AppFonts.mainfontName,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,color:AppColors.secondaryColor
  );
  static TextStyle TextButtonStyle = TextStyle(
    fontFamily: AppFonts.mainfontName,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,color:AppColors.thirdColor
  );
  static TextStyle SubTextStyle = TextStyle(
    fontFamily: AppFonts.mainfontName,
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,color:AppColors.SubTextColor
  );
}
