import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  
  // 2. تهيئة التواريخ باللغة العربية (ضروري لمواقيت الصلاة)
  await initializeDateFormatting('ar', null);
  
  // 3. تهيئة خدمة الإشعارات (الأذان)
  await NotificationService.init();

  // 4. 🎯 تشغيل خدمة فحص وتصفير الأذكار اليومية قبل فتح الشاشات
  await DailyResetService.checkAndResetIfNewDay();

  // 5. الانطلاق
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎯 توفير جميع العقول المدبرة (Cubits) لجميع شاشات التطبيق من نقطة واحدة
    return MultiBlocProvider(
      providers: [
        BlocProvider<QuranCubit>(create: (context) => QuranCubit()),
        BlocProvider<AdhkarCubit>(create: (context) => AdhkarCubit()),
        BlocProvider<PrayerCubit>(create: (context) => PrayerCubit()),
        BlocProvider<QiblaCubit>(create: (context) => QiblaCubit()),
      ],
      child: MaterialApp(
        title: 'Omar Codes Islamic App', // اسم التطبيق البرمجي
        debugShowCheckedModeBanner: false, // إخفاء شريط الـ Debug
        
        // 🎯 ضبط الثيم العالمي لـ Spiritual Dark Mode
        theme: ThemeData(
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
          fontFamily: 'Tajawal', // أو أي خط عربي رئيسي تستخدمه للواجهات
        ),
        
        // 🎯 توجيه المستخدم دائماً لشاشة التهيئة (Splash) أولاً
        home: const SplashScreen(),
      ),
    );
  }
}