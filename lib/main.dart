import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/features/main_navigation/presentation/main_screen.dart';
import 'package:islamic_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:islamic_app/core/services/notification_service.dart';
import 'features/adhkar/data/database_helper.dart';
import 'package:intl/date_symbol_data_local.dart';

// استدعاءات العقول المدبرة
import 'package:islamic_app/features/adhkar/presentation/manager/adhkar_cubit.dart';
import 'package:islamic_app/features/prayer_times/presentation/manager/prayer_cubit.dart';
import 'package:islamic_app/features/qibla/presentation/manager/qiblah_cubit.dart';
import 'package:islamic_app/features/quran/presentation/manager/quran_cubit.dart';
import 'core/services/daily_reset_service.dart';
// 🎯 استدعاء شاشة البداية
import 'package:islamic_app/features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await NotificationService.init();
  await DatabaseHelper.instance.database;
  // 🎯 2. السحر هنا: فحص وتصفير الأذكار إذا بدأ يوم جديد قبل أن تفتح الواجهة
  await DailyResetService.checkAndResetIfNewDay();
  
  // 🎯 أزلنا أكواد SharedPreferences من هنا لتسريع فتح التطبيق

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
   // 🎯 أزلنا متغير showOnboarding لأن شاشة Splash ستتولى المهمة
   const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AdhkarCubit()),
        BlocProvider(create: (context) => PrayerCubit()..fetchPrayerTimesData()),
        BlocProvider(create: (context) => QiblaCubit()),
        BlocProvider(create: (context) => QuranCubit()..loadBookmark()), 
      ],
      child: MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
        ),
        // 🎯 التعديل الأهم: جعلنا التطبيق يفتح دائماً على شاشة الـ Splash
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}