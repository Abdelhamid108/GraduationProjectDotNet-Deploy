import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graduationproject/core/widgets/custom_back_button.dart';
import 'package:graduationproject/features/search_screen/presentation_layer/searchscreenview.dart';

class AboutScreenBody extends StatelessWidget {
  const AboutScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),

            /// Back Button فوق على الشمال
            Align(
              alignment: Alignment.centerLeft,
              child: CustomBackButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Searchscreenview(),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 3.h),

            /// العنوان
            Text(
              'ايماءة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF248DBC),
                fontSize: 36.sp,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 20.h),

            /// النص
            Text(
              'هو أكثر من مجرد تطبيق؛ إنه منصة قوية تعتمد على الذكاء الاصطناعي لترجمة لغة الإشارة إلى نص منطوق أو مكتوب في الوقت الفعلي، والعكس صحيح. نموذج الذكاء الاصطناعي المتطور لدينا، الذي تم تطويره باستخدام أحدث تقنيات التعلم الآلي، يتعرف بدقة على لغات الإشارة المختلفة، مما يجعل المحادثات أكثر سلاسة وشمولية من أي وقت مضى.\n\nالميزات الرئيسية لإيماءة:\n\n- الترجمة في الوقت الفعلي: يحول إيماءات لغة الإشارة على الفور إلى مخرجات مفهومة.\n\n- التواصل ثنائي الاتجاه: يسهل المحادثات في الاتجاهين بين مستخدمي لغة الإشارة وغير المتحدثين بها.\n\n- إمكانية الوصول: يعزز الوصول إلى التعليم والرعاية الصحية والتوظيف والتفاعلات الاجتماعية.\n\n- التمكين: يمنح صوتًا لأولئك الذين يتواصلون من خلال الإشارات، مما يعزز الاستقلالية والإدماج بشكل أكبر.\n\nنحن فخورون للغاية بالتأثير الذي سيحدثه "إيماءة". انضموا إلينا في بناء عالم أكثر شمولاً وترابطًا!',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}