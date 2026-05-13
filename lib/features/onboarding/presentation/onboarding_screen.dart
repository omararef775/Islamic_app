import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../main_navigation/presentation/main_screen.dart';

// 1. كلاس لترتيب محتوى الشاشات الترحيبية
class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({required this.title, required this.description, required this.icon});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // 2. محتوى الشاشات الترحيبية
  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "القرآن الكريم",
      description: "تلاوة القرآن الكريم بالرسم العثماني المطابق لمصحف المدينة مع حفظ تلقائي لتقدمك في القراءة.",
      icon: Icons.menu_book_rounded,
    ),
    OnboardingContent(
      title: "الأذكار ومواقيت الصلاة",
      description: "حافظ على أذكارك اليومية، وتابع مواقيت الصلاة بدقة متناهية بناءً على موقعك الجغرافي.",
      icon: Icons.mosque_rounded,
    ),
    OnboardingContent(
      title: "اتجاه القبلة",
      description: "حدد اتجاه القبلة أينما كنت حول العالم بسهولة وسرعة باستخدام البوصلة الذكية.",
      icon: Icons.explore_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // زر التخطي (Skip)
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  "تخطي",
                  style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16),
                ),
              ),
            ),

            // محرك عرض الصفحات
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _contents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // أيقونة مضيئة بتصميم عصري
                        Container(
                          padding: const EdgeInsets.all(35),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(25), // خلفية شفافة بلون ذهبي
                            border: Border.all(color: AppColors.primary.withAlpha(100), width: 2),
                          ),
                          child: Icon(
                            _contents[index].icon,
                            size: 100,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 50),
                        
                        // العنوان
                        Text(
                          _contents[index].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontFamily: 'Uthmanic',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // الوصف
                        Text(
                          _contents[index].description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // الفوتر: المؤشر والأزرار
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // مؤشر الصفحات
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _contents.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.primary.withAlpha(76),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),

                  // الزر التفاعلي (التالي / ابدأ الآن)
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex == _contents.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentIndex == _contents.length - 1 ? "ابدأ الآن" : "التالي",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}