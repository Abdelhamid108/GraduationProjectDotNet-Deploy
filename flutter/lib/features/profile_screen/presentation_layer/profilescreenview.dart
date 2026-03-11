import 'package:flutter/material.dart';
import 'package:graduationproject/features/profile_screen/presentation_layer/widgets/profilescreenbody.dart';

class ProfileScreenView extends StatelessWidget {
  const ProfileScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const ProfileScreenBody(),
    );
  }
}