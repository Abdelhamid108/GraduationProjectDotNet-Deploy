import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/widgets/primary_button.dart';
import 'package:graduationproject/core/widgets/spacing_widgets.dart';
import 'package:graduationproject/features/search_screen/presentation_layer/searchscreenview.dart';

class Homescreenbody extends StatelessWidget {
  const Homescreenbody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Top image
            Stack(
              children: [
                Image.asset(
                  AppAssets.Homescreen,
                  width: double.infinity,
                  height: 261.h,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            HeightSpace(5.h),

            /// English text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Welcome to Our App!\n'
                'Our app makes communication between deaf and hearing people easier than ever.\n'
                'With it, you can convert sign language into text or voice,\n'
                'and also turn speech or text into sign language quickly and effortlessly.\n'
                'Start now and experience a whole new way to connect.',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
                textAlign: TextAlign.left,
              ),
            ),

            HeightSpace(3.h),

            /// Arabic text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'أهلاً بيك في تطبيقنا!\n'
                'تطبيقنا بيسهّل التواصل بين الصم وغير الصم،'
                'تقدر من خلاله تحوّل لغة الإشارة إلى نص أو صوت،'
                'وكمان تحوّل الكلام أو النص إلى إشارة بسرعة وسهولة\n'
                'ابدأ دلوقتي واكتشف تجربة تواصل مختلفة تمامًا\n',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: 'Noto Sans Gujarati',
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

            HeightSpace(10.h),

            /// Button with icon on the right
            Directionality(
              textDirection: TextDirection.rtl,
              child: PrimaryButton(
                width: 304.w,
                height: 70.h,
                buttonText: 'استمر',
                onPress: () {
                  Navigator.pushReplacement(  // ⬅️ غيرت من push لـ pushReplacement
                    context,
                    MaterialPageRoute(
                      builder: (context) => Searchscreenview(),
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  AppAssets.iconarrow,
                  width: 20.w,
                  height: 20.h,
                ),
              ),
            ),
            
            HeightSpace(20.h),  // ⬅️ مساحة في الآخر
          ],  // ⬅️ قفلت children
        ),
      ),
    );
  }
}
