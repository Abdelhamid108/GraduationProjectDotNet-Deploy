import 'package:flutter/material.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/style/app_fonts.dart';
import 'package:graduationproject/core/style/app_style.dart';

class AppThe {
  static final LightTheme = ThemeData(
    primaryColor:Color(0xffFFFFFF),
    scaffoldBackgroundColor: AppColors.thirdColor,
    fontFamily: AppFonts.mainfontName,
    textTheme: TextTheme(
      titleLarge: AppStyle.TextButtonStyle,
      titleMedium: AppStyle.dataLineStyle,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor:AppColors.primaryColor,
    )
  );
}
