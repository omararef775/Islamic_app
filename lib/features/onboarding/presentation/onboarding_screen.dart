import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../main_navigation/presentation/main_screen.dart';

// ══════════════════════════════════════════════════════════════
// نموذج بيانات كل صفحة ترحيبية
// ══════════════════════════════════════════════════════════════
class _OnboardPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

// ══════════════════════════════════════════════════════════════
// شاشة الترحيب الاحترافية
// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;

  int _currentIndex = 0;

  // ── قائمة الميزات الخمس ──────────────────────────────────
  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      title: 'القرآن الكريم',
      subtitle: 'بالرسم العثماني مع التفسير الكامل',
      description:
          'اقرأ القرآن الكريم بالرسم العثماني المطابق لمصحف المدينة المنورة، مع التفسير الميسّر لكل آية. يحفظ التطبيق موضع قراءتك تلقائياً ويعيدك إليه في كل مرة.',
      icon: Icons.menu_book_rounded,
    ),
    _OnboardPage(
      title: 'مواقيت الصلاة',
      subtitle: 'دقة متناهية بحسب موقعك الجغرافي',
      description:
          'مواقيت الصلاة الخمس بدقة عالية وفق طريقة أم القرى، مع عداد تنازلي مباشر لكل صلاة قادمة وبطاقة تفاعلية تُبرز الصلاة الحالية.',
      icon: Icons.access_time_rounded,
    ),
    _OnboardPage(
      title: 'الأذان التلقائي',
      subtitle: 'يُطلق حتى عند إغلاق التطبيق',
      description:
          'يُجدول التطبيق الأذان لكل صلاة لمدة 30 يوماً مسبقاً بصوت أذان مميز، يعمل تلقائياً حتى لو أُغلق التطبيق أو أُعيد تشغيل الهاتف.',
      icon: Icons.notifications_active_rounded,
    ),
    _OnboardPage(
      title: 'الأذكار اليومية',
      subtitle: 'أذكار الصباح والمساء وما بينهما',
      description:
          'مجموعة شاملة من أذكار الصباح والمساء وأذكار النوم والاستيقاظ، مع عداد لكل ذكر يتصفّر تلقائياً مع بداية كل يوم جديد.',
      icon: Icons.mosque_rounded,
    ),
    _OnboardPage(
      title: 'اتجاه القبلة',
      subtitle: 'بوصلة ذكية تعمل في كل مكان بالعالم',
      description:
          'حدّد اتجاه القبلة أينما كنت بدقة عالية باستخدام مستشعرات هاتفك، مع بوصلة ذهبية سلسة الحركة بدون اهتزاز.',
      icon: Icons.explore_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // أنيميشن دخول الصفحة
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    // أنيميشن نبض الأيقونة
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _entryController
      ..reset()
      ..forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLast = _currentIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── خلفية زخرفية دوارة ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => CustomPaint(
                painter: _BgPainter(t: _pulseController.value),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ─── شريط أعلى: رقم الصفحة + تخطي ───────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // عداد الصفحات
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(70)),
                        ),
                        child: Text(
                          '${_currentIndex + 1} من ${_pages.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // زر التخطي
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Row(
                          children: [
                            Text(
                              'تخطي',
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.skip_next_rounded,
                                color: Colors.white.withAlpha(120), size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── صفحات السلايدر ───────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) =>
                        _buildPageContent(_pages[i], size),
                  ),
                ),

                // ─── الفوتر ───────────────────────────────────────
                _buildFooter(isLast),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── محتوى كل صفحة ──────────────────────────────────────────
  Widget _buildPageContent(_OnboardPage page, Size size) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (_, child) => Opacity(
        opacity: _fadeIn.value,
        child: Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة الرئيسية
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Transform.scale(
                scale: _pulse.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // هالة خارجية
                    Container(
                      width: size.width * 0.55,
                      height: size.width * 0.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(7),
                        border: Border.all(
                            color: AppColors.primary.withAlpha(25),
                            width: 1),
                      ),
                    ),
                    // الدائرة الوسطى المضيئة
                    Container(
                      width: size.width * 0.42,
                      height: size.width * 0.42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(18),
                        border: Border.all(
                            color: AppColors.primary.withAlpha(90),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(55),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        page.icon,
                        size: size.width * 0.18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: size.height * 0.048),

            // العنوان
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontFamily: 'Uthmanic',
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // الوسم الفرعي
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // الوصف
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 15,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── الفوتر ──────────────────────────────────────────────────
  Widget _buildFooter(bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          // مؤشر الصفحات
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.primary.withAlpha(60),
              dotHeight: 7,
              dotWidth: 7,
              expansionFactor: 3.5,
              spacing: 5,
            ),
          ),

          const SizedBox(height: 24),

          // أزرار التنقل
          Row(
            children: [
              // زر السابق
              if (_currentIndex > 0) ...[
                _NavButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // زر التالي / ابدأ الآن
              Expanded(
                child: _PrimaryButton(
                  label: isLast ? 'ابدأ الآن 🚀' : 'التالي',
                  icon: isLast
                      ? Icons.check_circle_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  onTap: isLast
                      ? _completeOnboarding
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// زر التنقل الدائري (السابق)
// ══════════════════════════════════════════════════════════════
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1C2641),
          border:
              Border.all(color: AppColors.primary.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// الزر الرئيسي (التالي / ابدأ الآن)
// ══════════════════════════════════════════════════════════════
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(110),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: AppColors.background, size: 17),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// رسام الخلفية الزخرفية المتحركة
// ══════════════════════════════════════════════════════════════
class _BgPainter extends CustomPainter {
  final double t; // قيمة من 0.0 إلى 1.0

  const _BgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // دوائر شفافة نابضة
    final radii = [size.width * 0.45, size.width * 0.58, size.width * 0.72];
    for (int i = 0; i < radii.length; i++) {
      final alpha = (8 + i * 4 + t * 6).clamp(0, 30).toInt();
      strokePaint.color = AppColors.primary.withAlpha(alpha);
      canvas.drawCircle(Offset(cx, cy), radii[i], strokePaint);
    }

    // نقاط ذهبية دوارة (حلقة خارجية)
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withAlpha(28);

    const dotCount = 10;
    final r = size.width * 0.46;
    final baseAngle = t * 2 * math.pi;

    for (int i = 0; i < dotCount; i++) {
      final angle = baseAngle + i * (2 * math.pi / dotCount);
      canvas.drawCircle(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        2.8,
        dotPaint,
      );
    }

    // نقاط عكسية (حلقة داخلية)
    final dotPaint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withAlpha(16);

    final r2 = size.width * 0.35;
    for (int i = 0; i < 6; i++) {
      final angle = -baseAngle + i * (2 * math.pi / 6) + math.pi / 6;
      canvas.drawCircle(
        Offset(cx + r2 * math.cos(angle), cy + r2 * math.sin(angle)),
        2.0,
        dotPaint2,
      );
    }

    // نقاط ثابتة في الأركان
    final cornerDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withAlpha(22);

    final cornerDots = [
      Offset(size.width * 0.08, size.height * 0.06),
      Offset(size.width * 0.14, size.height * 0.06),
      Offset(size.width * 0.92, size.height * 0.94),
      Offset(size.width * 0.86, size.height * 0.94),
      Offset(size.width * 0.92, size.height * 0.06),
      Offset(size.width * 0.08, size.height * 0.94),
    ];
    for (final dot in cornerDots) {
      canvas.drawCircle(dot, 2.5, cornerDotPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
