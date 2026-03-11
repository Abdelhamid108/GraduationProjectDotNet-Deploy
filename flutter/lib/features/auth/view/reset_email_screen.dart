import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/features/auth/controller/auth_controller.dart';
import 'package:graduationproject/core/widgets/TextField_button.dart';
import 'package:graduationproject/core/widgets/custom_back_button.dart';
class ResetEmailScreen extends StatelessWidget {
  ResetEmailScreen({super.key});

  final AuthController controller = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,

         automaticallyImplyLeading: false, // مهم
actions: const [
    CustomBackButton(),
  ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// العنوان الرئيسي
            const Text(
              "إعادة تعيين كلمة المرور",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            /// النص التوضيحي
            const Text(
              "أدخل بريدك الإلكتروني لإرسال كود التحقق",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            /// حقل الإدخال
            CustomTextField(
              controller: emailController,
              label: "البريد الإلكتروني",
              hintText: "ادخل بريدك الإلكتروني",
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 30),

            /// زر المتابعة
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff30BBF9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.sendEmail(emailController.text),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "متابعة",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
