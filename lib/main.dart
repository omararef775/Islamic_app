import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_library/quran_library.dart';

// 🎯 استدعاءات الثيم الأساسي
import 'package:islamic_app/core/theme/app_colors.dart';

// 🎯 استدعاءات الخدمات المركزية
import 'package:islamic_app/core/services/notification_service.dart';
import 'package:islamic_app/core/services/daily_reset_service.dart';

// 🎯 استدعاءات العقول المدبرة (Cubits)
import 'package:islamic_app/features/adhkar/presentation/manager/adhkar_cubit.dart';
import 'package:islamic_app/features/prayer_times/presentation/manager/prayer_cubit.dart';
import 'package:islamic_app/features/qibla/presentation/manager/qiblah_cubit.dart';
import 'package:islamic_app/features/quran/presentation/manager/quran_cubit.dart';

// 🎯 استدعاء شاشة البداية
import 'package:islamic_app/features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  // 1. ضمان تهيئة محرك فلاتر قبل تشغيل أي كود
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة مكتبة القرآن الكريم
  await QuranLibrary.init();

  // 3. تهيئة التواريخ باللغة العربية (ضروري لمواقيت الصلاة)
  await initializeDateFormatting('ar', null);

  // 4. تهيئة خدمة الإشعارات (الأذان)
  await NotificationService.init();

  // 5. فحص وتصفير الأذكار اليومية عند الإطلاق
  await DailyResetService.checkAndResetIfNewDay();

  // 6. الانطلاق
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<QuranCubit>(
          create: (context) => QuranCubit()..loadSettings(),
        ),
        BlocProvider<AdhkarCubit>(create: (context) => AdhkarCubit()),
        BlocProvider<PrayerCubit>(create: (context) => PrayerCubit()),
        BlocProvider<QiblaCubit>(create: (context) => QiblaCubit()),
      ],
      child: MaterialApp(
        title: 'رفيق المسلم',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.background,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          fontFamily: 'Tajawal',
        ),
        // 🎯 استخدام AppLifecycleWrapper لفحص التصفير عند العودة للتطبيق
        home: const AppLifecycleWrapper(child: SplashScreen()),
      ),
    );
  }
}

// ==============================================================
// 🔄 مراقب دورة حياة التطبيق لتصفير الأذكار عند الاستئناف
//
// 🎯 يحل المشكلة الحرجة:
// إذا أبقى المستخدم التطبيق مفتوحاً طوال الليل وعاد إليه صباحاً
// بدون إغلاقه، هذا الـ Observer يفحص التاريخ فور استئناف التطبيق
// ويُصفِّر العدادات إذا كان يوماً جديداً.
// ==============================================================
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // تسجيل هذا الـ Widget كمراقب لدورة حياة التطبيق
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🎯 عند استئناف التطبيق من الخلفية أو شاشة القفل
    if (state == AppLifecycleState.resumed) {
      DailyResetService.checkAndResetIfNewDay();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
