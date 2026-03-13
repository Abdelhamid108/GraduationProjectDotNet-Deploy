import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_assets.dart';

import 'package:graduationproject/features/Aboutapp_screen/presentation_layer/widgets/AboutAppbody.dart';

class AboutScreenView extends StatelessWidget {
  const AboutScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          Positioned.fill(
            top: 183.h,
            left:0.w,
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.fill, // ⬅️ fill يملي الشاشة كلها
            ),
          ),

          /// التحكم في الإضاءة
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.8), // ⬅️ غير الرقم من 0.0 لـ 1.0
            ),
          ),

          /// Content
          const Positioned.fill(
            child: AboutScreenBody(),
          ),
        ],
      ),
    );
  }
}