import 'package:flutter/material.dart';
import 'package:graduationproject/features/account_screen/presentation_layer/widgets/accountscreenbody.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AccountBody(),
    );
  }
}