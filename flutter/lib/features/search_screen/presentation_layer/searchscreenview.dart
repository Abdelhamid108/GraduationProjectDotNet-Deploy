import 'package:flutter/material.dart';
import 'package:graduationproject/features/search_screen/presentation_layer/widgets/searchscreenbody.dart';

class Searchscreenview extends StatelessWidget {
  const Searchscreenview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Searchscreenbody(),
    );
  }
}
