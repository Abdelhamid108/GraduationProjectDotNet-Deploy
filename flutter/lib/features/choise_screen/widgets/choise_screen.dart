import 'package:flutter/material.dart';
import 'package:graduationproject/core/widgets/custom_back_button.dart';
import 'package:graduationproject/core/widgets/custom_button.dart';
import 'package:graduationproject/features/main_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 👇 هنا حطي ال Widget بتاع الـ BottomNav
      bottomNavigationBar: const MainScreen(), 
      // مثال:
      // bottomNavigationBar: CustomBottomNav(),

      body: Stack(
        children: [
          /// -------- Background Image ----------
          Positioned.fill(
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                "assets/images/woman-home.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// -------- Main Content ----------
          SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  /// Back Arrow
                   Align(
           alignment: Alignment.topRight,
            child:CustomBackButton(),
          ),

                  const Spacer(),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "إيماءة...لغة مشتركة للمجتمع",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      CustomButton(
                        text: "إشارة إلى نص",
                        onPressed: () {
                          print("Pressed");
                        },
                      ),
                      CustomButton(
                        text: "نص إلى إشارة",
                        onPressed: () {
                          print("Pressed");
                        },
                      ),

                      CustomButton(
                        text: "لوحة مفاتيح",
                        onPressed: () {
                          print("Pressed");
                        },
                      ),
                     
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}