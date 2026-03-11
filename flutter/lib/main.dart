import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:graduationproject/features/loading_screen/presentation_layer/LoadingScreenview.dart';
import 'package:graduationproject/features/auth/view/reset_email_screen.dart';
import 'package:graduationproject/features/auth/view/otp_screen.dart';
import 'package:graduationproject/features/auth/view/new_password_screen.dart';
import 'package:graduationproject/features/lognIn_screen/presentation_layer/loginScreenView.dart';
import 'package:graduationproject/features/signup_screen/presentation_layer/signupscreemView.dart';
import 'package:graduationproject/features/main_screen.dart';
import 'package:graduationproject/features/splashscreen/presentationlayer/Splashscreenview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: widget!,
              ),
            );
          },
          home: const LoadingScreen(),
          getPages: [
            GetPage(
              name: '/SplashScreenView',
              page: () => const SplashScreenView(),
            ),
            GetPage(
              name: '/login',
              page: () => const LoginScreenView(),
            ),
            GetPage(
              name: '/signup',
              page: () => const SignUpScreenView(),
            ),
            GetPage(
              name: '/mainscreen',
              page: () => const MainScreen(),
            ),
            GetPage(
              name: '/reset-email',
              page: () => ResetEmailScreen(),
            ),
            GetPage(
              name: '/otp',
              page: () => OtpScreen(),
            ),
            GetPage(
              name: '/new-password',
              page: () => ResetPasswordScreen(),
            ),
          ],
        );
      },
    );
  }
}