import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// 🎯 تأكد من صحة هذه المسارات بناءً على هيكلة مشروعك
import '../../../../core/theme/app_colors.dart';
import '../../main_navigation/presentation/main_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد الأنيميشن بسلاسة تليق بتطبيق إسلامي
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _startAppLogic();
  }

  Future<void> _startAppLogic() async {
    // 1. الانتظار لـ 3.5 ثانية لعرض اللوجو والأنيميشن
    await Future.delayed(const Duration(milliseconds: 3500));

    // 2. التحقق من الذاكرة (هنا يحدث انتظار جديد await)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // 🎯 الحماية المعمارية: الفحص يجب أن يكون هنا، بعد كل عمليات الـ await وقبل استخدام الـ context
    if (!mounted) return;

    Widget nextScreen = onboardingCompleted
        ? const MainScreen()
        : const OnboardingScreen();

    // 3. الانتقال السلس (Fade Transition) للشاشة التالية
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎯 استخدام خلفية التطبيق الإسلامية الثابتة
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        // يمكنك تفعيل التدرج اللوني إذا أردت، أو الاكتفاء باللون الموحد
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.background.withAlpha(200), // تدرج خفيف جداً
            ],
          ),
        ),
        child: Stack(
          children: [
            // ==========================================
            // 🌟 منتصف الشاشة: اللوجو والهوية
            // ==========================================
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // اللوجو الخاص بك
                      Image.asset(
                        'assets/images/logo.png',
                        width: 200,
                        fit: BoxFit.contain,
                        // في حال عدم وجود الصورة، نظهر أيقونة مسجد فخمة
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.mosque_rounded,
                              size: 120,
                              color: AppColors.primary, // اللون الذهبي للتطبيق
                            ),
                      ),
                      const SizedBox(height: 24),
                      // الاسم التجاري
                      const Text(
                        'Omar Codes',
                        style: TextStyle(
                          fontSize: 32,
                          fontFamily:
                              'Uthmanic', // لمسة إسلامية للخط الإنجليزي أو يمكنك تركه عادي
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppColors.primary, // ذهبي
                        ),
                      ),
                      const SizedBox(height: 8),
                      // وصف قصير (اختياري)
                      Text(
                        'رفيقك المسلم',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Uthmanic',
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // 👇 أسفل الشاشة: الحقوق والمؤشر
            // ==========================================
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // مؤشر التحميل (بلون التطبيق الذهبي)
                    const SizedBox(
                      width: 35,
                      height: 35,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'تم التصميم والتطوير بواسطة',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(150),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'المهندس / عمر',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Omar Codes © 2026',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary, // ذهبي
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
