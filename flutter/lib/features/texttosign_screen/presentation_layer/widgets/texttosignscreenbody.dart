import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/style/app_colors.dart';
import 'package:graduationproject/core/widgets/custom_round_button.dart';
import 'package:graduationproject/core/widgets/primary_button.dart';
import 'package:graduationproject/core/widgets/word_signcard.dart';
import 'package:graduationproject/features/voicetosign_screen/presentation_layer/voicetosignscreenview.dart';

class TextToSignScreenBody extends StatefulWidget {
  const TextToSignScreenBody({super.key});

  @override
  State<TextToSignScreenBody> createState() => _TextToSignScreenBodyState();
}

class _TextToSignScreenBodyState extends State<TextToSignScreenBody> {
  final TextEditingController _controller = TextEditingController();

  final List<String> bismiImages = [
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ب',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=س',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=م',
  ];

  final List<String> allahImages = [
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ا',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ل',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ل',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Text(
                'تحويل النص الى لغة الاشارة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Text Input
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                width: double.infinity,
                height: 110.h,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9).withOpacity(0.42),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF5DBBFF),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'اكتب.....',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(
                      color: const Color(0xFFA9A9A9),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.h),

            // Buttons Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  // ✅ زرار تسجيل صوتي
                  Expanded(
                    child: CustomRoundButton(
                      buttonText: 'تسجيل صوتي',
                      icon: SvgPicture.asset(
                        AppAssets.MicLine,
                        width: 18.w,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      textColor: Colors.white,
                      buttonColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                      height: 48.h,
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VoiceToSignScreenView(),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // ✅ زرار تحويل النص
                  Expanded(
                    child: CustomRoundButton(
                      buttonText: 'تحويل النص',
                      icon: SvgPicture.asset(
                        AppAssets.Texticone,
                        width: 18.w,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      textColor: Colors.white,
                      buttonColor: const Color(0xFF276C8A),
                      borderColor: const Color(0xFF44BCF0),
                      height: 48.h,
                      onPress: () {
                        // TODO: اضيفي هنا logic التحويل
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Results - scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    WordSignCard(
                      wordLabel: 'كلمة : بسم',
                      imageUrls: bismiImages,
                    ),
                    SizedBox(height: 12.h),
                    WordSignCard(
                      wordLabel: 'كلمة : الله',
                      imageUrls: allahImages,
                    ),
                    SizedBox(height: 25.h),

                    // زرار الرجوع
                    PrimaryButton(
                      buttonText: 'الرجوع',
                      buttonColor: AppColors.primaryColor,
                      onPress: () => Navigator.pop(context),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}