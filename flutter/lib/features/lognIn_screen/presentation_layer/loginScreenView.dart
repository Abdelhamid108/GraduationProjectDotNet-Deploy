import 'package:flutter/material.dart';
import 'package:graduationproject/features/lognIn_screen/presentation_layer/widgets/loginScreenBody.dart';


class LoginScreenView extends StatelessWidget {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: LoginScreenBody(),
      ),
    );
  }
}