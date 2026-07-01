import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/utils/permission_manager.dart';
import '../../../core/services/notification_service.dart';

// 🎯 تم تنظيف الاستدعاءات (Imports) غير المستخدمة لـ QuranCubit و AdhkarCubit
import 'package:islamic_app/features/prayer_times/presentation/prayer_screen.dart';
import '../../qibla/presentation/pages/qibla_screen.dart';
import '../../adhkar/presentation/pages/adhkar_screen.dart';
import 'package:islamic_app/features/quran/presentation/pages/quran_screen.dart';
import '../../qibla/presentation/manager/qiblah_cubit.dart';
import 'package:islamic_app/features/prayer_times/presentation/manager/prayer_cubit.dart';

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
    await PermissionManager.requestExactAlarmPermission(); 

    if (mounted) {
      context.read<PrayerCubit>().fetchPrayerTimesData();
      context.read<QiblaCubit>().checkPermissionsAndInitialize();
    }
  }

  @override
  void initState() {
    super.initState();
    _requestAppPermissions();
    HardwareKeyboard.instance.addHandler(_handleVolumeButton);
  }

  bool _handleVolumeButton(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeMute) {
        NotificationService.cancelAll();
        return false;
      }
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleVolumeButton);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const QuranScreen(),   // تبقى حية في الخلفية لتحتفظ بمكان القراءة
          const AdhkarScreen(),  // تبقى حية في الخلفية لتسريع التنقل
          const PrayerScreen(),  // تبقى حية في الخلفية (شاشة خفيفة جداً)
          
          // 🎯 الحيلة الهندسية: إذا لم نكن في تبويب القبلة، ندمر الشاشة لإيقاف المستشعر
          _selectedIndex == 3 ? const QiblaScreen() : const SizedBox.shrink(),
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