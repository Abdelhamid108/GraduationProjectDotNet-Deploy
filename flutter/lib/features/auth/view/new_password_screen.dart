import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/features/auth/controller/auth_controller.dart';
import 'package:graduationproject/core/widgets/TextField_button.dart';

class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({super.key});

  final AuthController controller = Get.find<AuthController>();

  final TextEditingController newPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // عشان الكلام يبقى على اليمين
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
       leading: Directionality(
            textDirection: TextDirection.ltr, //  يخلي السهم شمال
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// العنوان + أيقونة
              Row(
                children: const [
                  Icon(Icons.lock, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "إعادة تعيين كلمة المرور",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// New Password
           
              const SizedBox(height: 8),
             CustomTextField(
               label: "كلمة المرور الجديدة",
                controller: newPasswordController,
                hintText: "أدخل كلمة المرور",
              isPassword: true,
               
                
              ),

              const SizedBox(height: 15),

              /// Confirm Password
             
              const SizedBox(height: 8),
              CustomTextField(
                  label: "تأكيد كلمة المرور",
                controller: confirmPasswordController,
                hintText: "أدخل كلمة المرور مرة أخرى",
               obscureText: true
              ),

            
              const SizedBox(height: 30), 
              /// زر إعادة التعيين
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
                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              Get.snackbar(
                                "خطأ",
                                "كلمتا المرور غير متطابقتين",
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            controller.changePassword(
                                newPasswordController.text);
                          },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "إعادة تعيين كلمة المرور",
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