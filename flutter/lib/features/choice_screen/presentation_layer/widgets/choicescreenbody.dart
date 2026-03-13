import 'package:flutter/material.dart';
import 'package:graduationproject/core/widgets/custom_button.dart';
import 'package:graduationproject/features/signtotext_screen/presentation_layer/widgets/signtotextscreenbody.dart';
import 'package:graduationproject/features/texttosign_screen/presentation_layer/texttosignscreenview.dart';

class Choicescreenbody extends StatelessWidget {
  const Choicescreenbody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// -------- Background Image ----------
          Positioned.fill(
              child: Image.asset(
                'assets/images/choice_screen.png',
                fit: BoxFit.cover,
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
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
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

                      const SizedBox(height: 40),

                      CustomButton(
                        text: "إشارة إلى نص",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Signtotextscreenview(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      CustomButton(
                        text: "نص إلى إشارة",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TextToSignScreenView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}