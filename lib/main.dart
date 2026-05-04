import 'package:flutter/material.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/features/main_navigation/presentation/main_screen.dart';
import 'package:islamic_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(  MyApp(showOnboarding:onboardingCompleted));
}

class MyApp extends StatelessWidget {
   final bool showOnboarding;
   const MyApp ({super.key,required this.showOnboarding});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
      ),

      home: showOnboarding ? MainScreen() : OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


