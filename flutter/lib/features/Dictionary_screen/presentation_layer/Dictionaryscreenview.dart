import 'package:flutter/material.dart';
import 'package:graduationproject/features/Dictionary_screen/presentation_layer/widgets/Dictionaryscreenbody.dart';

class Dictionaryscreenview extends StatelessWidget {
  const Dictionaryscreenview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: const Dictionaryscreenbody(),
      ),
    );
  }
}