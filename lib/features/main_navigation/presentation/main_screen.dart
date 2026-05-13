import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/utils/permission_manager.dart';

// استدعاء الشاشات
import 'package:islamic_app/features/prayer_times/presentation/prayer_screen.dart';
import '../../qibla/presentation/pages/qibla_screen.dart';
import '../../adhkar/presentation/pages/adhkar_screen.dart';
import '../../../core/services/notification_service.dart';
// استدعاء العقول المدبرة
import '../../qibla/presentation/manager/qiblah_cubit.dart';
import '../../adhkar/presentation/manager/adhkar_cubit.dart';
import 'package:islamic_app/features/prayer_times/presentation/manager/prayer_cubit.dart';
import 'package:islamic_app/features/quran/presentation/manager/quran_cubit.dart';
import 'package:islamic_app/features/quran/presentation/pages/quran_screen.dart';
import 'package:flutter/services.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  Future<void> _requestAppPermissions() async {
    await PermissionManager.requestLocationPermission();
    await PermissionManager.requestNotificationPermission();
  }

  @override
  void initState() {
    super.initState();
    _requestAppPermissions();
    HardwareKeyboard.instance.addHandler(_handleVolumeButton);
  }
  // 🎯 دالة الاستماع لأزرار الصوت
  bool _handleVolumeButton(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown || 
          event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeMute) {
        
        // بمجرد الضغط على أي زر صوت، نلغي الإشعارات فيسكت الأذان فوراً
        NotificationService.cancelAll();
        
        // إرجاع false لكي نسمح للنظام بتخفيض الصوت فعلياً بالإضافة لإلغاء الإشعار
        return false; 
      }
    }
    return false;
  }

  @override
  void dispose() {
    // 🎯 إزالة المراقب عند إغلاق التطبيق لمنع تسريب الذاكرة
    HardwareKeyboard.instance.removeHandler(_handleVolumeButton);
    super.dispose();
  }

  // 🎯 أزلنا دالة switch case المدمرة للشاشات

  @override
  Widget build(BuildContext context) {
    // 🎯 1. MultiBlocProvider: تهيئة كل العقول مرة واحدة فقط لتعمل باستقرار
    // return MultiBlocProvider(
    //   providers: [
    //     BlocProvider(create: (context) => AdhkarCubit()),
    //     BlocProvider(create: (context) => PrayerCubit()..fetchPrayerTimesData()),
    //     BlocProvider(create: (context) => QiblaCubit()),
    //     BlocProvider(create: (context) => QuranCubit()..loadBookmark()),
    //   ],
      return Scaffold(
        backgroundColor: AppColors.background,
        // 🎯 2. IndexedStack: يحتفظ بجميع الشاشات حية في الخلفية
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            QuranScreen(),
            AdhkarScreen(), // الشاشات الآن نظيفة تماماً ولا تحتوي على BlocProvider
            PrayerScreen(),
            QiblaScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'المصحف'),
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'الاذكار'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'الصلاة'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'القبلة'),
          ],
        ),
      );
    
  }
}