import 'package:flutter/material.dart';
import 'package:graduationproject/features/splashscreen/presentationlayer/widgets/SplashScreenBody.dart';

class SplashScreenView extends StatelessWidget {
  const SplashScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xffFFFFFF), // استخدم Colors.white بدل كتابة hex
      body: SplashScreenBody()
    );
  }
}