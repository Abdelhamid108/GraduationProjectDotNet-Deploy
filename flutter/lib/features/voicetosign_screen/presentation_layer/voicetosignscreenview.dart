import 'package:flutter/material.dart';
import 'package:graduationproject/features/voicetosign_screen/presentation_layer/widgets/voicetosignscreenbody.dart';

class VoiceToSignScreenView extends StatelessWidget {
  const VoiceToSignScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: VoiceToSignScreenBody(),
    );
  }
}