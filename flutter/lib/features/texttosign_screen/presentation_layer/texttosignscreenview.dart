import 'package:flutter/material.dart';
import 'package:graduationproject/features/texttosign_screen/presentation_layer/widgets/texttosignscreenbody.dart';

class TextToSignScreenView extends StatelessWidget {
  const TextToSignScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: TextToSignScreenBody(),
    );
  }
}