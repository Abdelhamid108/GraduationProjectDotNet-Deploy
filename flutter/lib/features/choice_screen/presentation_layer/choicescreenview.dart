import 'package:flutter/material.dart';
import 'package:graduationproject/features/choice_screen/presentation_layer/widgets/choicescreenbody.dart';

class Choicescreenview extends StatelessWidget {
  const Choicescreenview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:  Choicescreenbody(),
      ),
    );
  }
}