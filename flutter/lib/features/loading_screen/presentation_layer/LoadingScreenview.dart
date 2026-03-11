import 'package:flutter/material.dart';
import 'package:graduationproject/features/loading_screen/presentation_layer/widgets/LoadingScreenBody.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: LoadingScreenBody(),
    );
  }
  
}