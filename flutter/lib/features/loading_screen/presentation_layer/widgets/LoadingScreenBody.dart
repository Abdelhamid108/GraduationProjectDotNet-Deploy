import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/features/splashscreen/presentationlayer/SplashScreenView.dart';

class LoadingScreenBody extends StatefulWidget {
  const LoadingScreenBody({super.key});

  @override
  State<LoadingScreenBody> createState() => _LoadingScreenBodyState();
}

class _LoadingScreenBodyState extends State<LoadingScreenBody> {
  @override
  void initState() {
    super.initState();
    goToNextView();
  }

  void goToNextView() {
    Future.delayed(const Duration(seconds: 3), () {
      Get.to(
        () => const SplashScreenView(),
        transition: Transition.fade,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.logo,
            width:502.w,height:507.h,),
          
          ],
        ),
      ),
    );
  }
}