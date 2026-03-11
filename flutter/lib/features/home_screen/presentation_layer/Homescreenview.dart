import 'package:flutter/material.dart';
import 'package:graduationproject/features/home_screen/presentation_layer/widgets/homescreenbody.dart';

class Homescreenview extends StatelessWidget{
  const Homescreenview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xffFFFFFF), // استخدم Colors.white بدل كتابة hex
      body: Homescreenbody(),
    );
  }
}