import 'package:flutter/material.dart';
import 'package:graduationproject/features/history_screen/presentation_layer/widgets/historyscreenbody.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF30BBF9),
      ),
      body: const HistoryBody(),
    );
  }
}