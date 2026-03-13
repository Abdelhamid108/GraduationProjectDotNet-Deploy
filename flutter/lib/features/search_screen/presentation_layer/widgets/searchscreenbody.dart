import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/widgets/primary_button.dart';
import 'package:graduationproject/core/widgets/primary_outlined_button.dart';
import 'package:graduationproject/core/widgets/spacing_widgets.dart';
import 'package:graduationproject/core/widgets/custom_back_button.dart';
import 'package:graduationproject/features/Aboutapp_screen/presentation_layer/AboutAppview.dart';
import 'package:graduationproject/features/Dictionary_screen/presentation_layer/Dictionaryscreenview.dart';
import 'package:graduationproject/features/choice_screen/presentation_layer/choicescreenview.dart';

class Searchscreenbody extends StatelessWidget {
  const Searchscreenbody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          /// Top Image with Back Button
          Stack(
            children: [
              Image.asset(
                AppAssets.Searchscreen,
                width: 408.w,
                height: 269.h,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8.h,
                left: 5.w,
                child: CustomBackButton(),
              ),
            ],
          ),

          HeightSpace(60.h),

          /// Outline Buttons
          SizedBox(
            width: double.infinity,
            height: 260.h,
            child: Stack(
              children: [
                Positioned(
                  top: 0.h,
                  left: 51.w,
                  child: PrimaryOutlinedButton(
                    buttonText: 'كيف يعمل ؟',
                    width: 272.w,
                    fontSize: 20.sp,
                    buttonColor: const Color(0x2630BBF9),
                    textColor: Colors.black,
                    onPress: () {},
                  ),
                ),
                Positioned(
                  top: 86.h,
                  left: 51.w,
                  child: PrimaryOutlinedButton(
                    buttonText: 'عن المشروع',
                    fontSize: 20.sp,
                    textColor: Colors.black,
                    buttonColor: const Color(0x2630BBF9),
                    width: 272.w,
                    onPress: () {
                       Navigator.push(
                     context,
                   MaterialPageRoute(
                builder: (_) => const AboutScreenView(),
                ),
                );
                    },
                  ),
                ),
                Positioned(
                  top: 172.h,
                  left: 51.w,
                  child: PrimaryOutlinedButton(
                    buttonText: 'المعجم الارشادي',
                    fontSize: 20.sp,
                    width: 272.w,
                    buttonColor: const Color(0x2630BBF9),
                    textColor: Colors.black,
                    onPress: () {
                    Navigator.push(
                     context,
                   MaterialPageRoute(
                builder: (_) => const Dictionaryscreenview(),
                ),
                );


                    },
                  ),
                ),
              ],
            ),
          ),

          HeightSpace(50.h),

          /// Main Button
          Center(
            child: PrimaryButton(
              width: 272.w,
              height: 60.h,
              buttonText: 'ابدأ الان',
              fontSize: 18.sp,
              onPress: () {
                Navigator.push(
                     context,
                   MaterialPageRoute(
                builder: (_) => Choicescreenview(),
                ),
                );
              },
            ),
          ),
          HeightSpace(30.h),
        ],
      ),
    );
  }
}