import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🎯 ضروري: استدعاء مكتبة Bloc
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/utils/permission_manager.dart';
import 'package:islamic_app/features/prayer_times/presentation/prayer_screen.dart';
import '../../qibla/presentation/pages/qibla_screen.dart';
import '../../qibla/presentation/manager/qiblah_cubit.dart'; // 🎯 ضروري: استدعاء العقل المدبر

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  Future<void> _requestAppPermissions() async {
    // طلب اذن الموقع اولا
    bool locationGranted = await PermissionManager.requestLocationPermission();
    bool notificationGranted = await PermissionManager.requestNotificationPermission();
  }

  @override
  void initState() {
    super.initState();
    // استدعاء دالة الصلاحيات بمجرد فتح الشاشة
    _requestAppPermissions();
  }

  // 🎯 التعديل الجذري: دالة تبني الشاشات ديناميكياً لتفادي أخطاء الـ State
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text('شاشة المصحف', style: TextStyle(color: Colors.white, fontSize: 24)));
      case 1:
        return const Center(child: Text('شاشة الأذكار', style: TextStyle(color: Colors.white, fontSize: 24)));
      case 2:
        return const PrayerScreen();
      case 3:
        // 🎯 السحر هنا: قمنا بتغليف الشاشة بـ BlocProvider لربطها بالعقل المدبر
        return BlocProvider(
          create: (context) => QiblaCubit(),
          child: const QiblaScreen(),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'المصحف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque),
            label: 'الاذكار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'الصلاة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'القبلة',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      // 🎯 التعديل: استدعاء الدالة بدلاً من القائمة الثابتة
      body: _buildBody(), 
    );
  }
}