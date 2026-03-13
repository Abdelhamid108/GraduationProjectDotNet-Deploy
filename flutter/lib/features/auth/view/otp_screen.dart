import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/features/auth/controller/auth_controller.dart';

class OtpScreen extends StatelessWidget {
  OtpScreen({super.key});

  final AuthController controller = Get.find<AuthController>();

  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // الأرقام من الشمال لليمين
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 20),

              /// العنوان
              const Text(
                     "كود التحقق",
                  textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              /// الوصف
              const Text(
                "أدخل كود التحقق المكوّن من 6 أرقام الذي تم إرساله إلى بريدك الإلكتروني",
                  textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              /// OTP BOXES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 37,
                    height: 37,
                    child: TextField(
                      controller: otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF30BBF9)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              /// إعادة الإرسال + العداد
              Obx(() {
                return Row(
                   textDirection: TextDirection.rtl,
                  children: [
                    const Text(
                      "لم يصلك الكود؟",
                      style: TextStyle(color: Colors.grey),
                    ),
                    controller.canResend.value
                        ? TextButton(
                            onPressed: controller.resendOtp,
                            child: const Text(
                              "إعادة الإرسال",
                              style:
                                  TextStyle(color: Color(0xFF30BBF9)),
                            ),
                          )
                        : Text(
                            "  إعادة الإرسال خلال ${controller.resendSeconds.value} ثانية",
                            style:
                                const TextStyle(color: Colors.grey),
                          ),
                  ],
                );
              }),

              const SizedBox(height: 20),

              /// زر التأكيد
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF30BBF9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            final otp = otpControllers
                                .map((c) => c.text)
                                .join();
                            controller.verifyOtp(otp);
                          },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "تأكيد",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}