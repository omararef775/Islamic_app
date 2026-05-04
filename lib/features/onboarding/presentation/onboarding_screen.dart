import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/features/main_navigation/presentation/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  // 1. تعريف المتحكم
  late PageController pagecontroller;
  // 2. تهيئة المتحكم في الذاكرة
  @override
  void initState() {
    super.initState();
    pagecontroller = PageController();
  }
  // 3. تدمير المتحكم لتحرير الذاكرة
  @override
  void dispose() {
    pagecontroller.dispose(); 
    super.dispose();
  }
  Future<void> _saveonboardingState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    print("تم حفظ الشاشة بنجاح");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 4. الطبقة السفلية (محرك الصفحات)
          PageView(
            controller: pagecontroller,
            children: const [
              Center(
                child: Text(
                  "مواقيت الصلاة",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "الأذكار",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "اتجاه القبلة",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // 5. الطبقة العلوية (المؤشر والزر)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 6. مؤشر الصفحات
                  SmoothPageIndicator(
                    controller: pagecontroller,
                    count: 3,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.cards,
                      dotHeight: 10,
                      dotWidth: 10,
                      spacing: 8,
                    ),
                  ),
                  
                  const SizedBox(height: 30), // مسافة فاصلة
                  
                  // 7. زر الانتقال
                  ElevatedButton(
                    onPressed: () async {
                     await _saveonboardingState();
                     if (!context.mounted) return;
                     
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // لون الزر الذهبي
                      foregroundColor: AppColors.background, // لون النص داخل الزر
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // حواف دائرية للزر
                      ),
                    ),
                    child: const Text(
                      "التالي",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}