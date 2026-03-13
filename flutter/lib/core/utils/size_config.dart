
import 'package:flutter/widgets.dart';

class SizeConfig {
  static double? screenWidth;
  static double? screenHeight;
  static double? blockWidth;
  static double? blockHeight;

  static const double designWidth = 375; // العرض اللي صممت عليه
  static const double designHeight = 812; // الطول اللي صممت عليه

  void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // نسبة الوحدة لكل بكسل من التصميم الأصلي
    blockWidth = screenWidth! / designWidth;
    blockHeight = screenHeight! / designHeight;
  }

  // دوال مساعدة لتحويل أي رقم ثابت لنسبة ديناميكية
  static double getWidth(double width) => width * blockWidth!;
  static double getHeight(double height) => height * blockHeight!;
}



