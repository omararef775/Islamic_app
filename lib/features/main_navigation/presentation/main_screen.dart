import 'package:flutter/material.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/utils/permission_manager.dart';
import 'package:islamic_app/features/prayer_times/presentation/prayer_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
  const Center(child: Text('شاشة المصحف', style: TextStyle(color: Colors.white, fontSize: 24))),
  const Center(child: Text('شاشة الأذكار', style: TextStyle(color: Colors.white, fontSize: 24))),
  const PrayerScreen(),
  const Center(child: Text('شاشة القبلة', style: TextStyle(color: Colors.white, fontSize: 24))),
];

Future<void> _requestAppPermissions() async {
  //طلب اذن الموقع اولا
  bool locationGranted = await PermissionManager.requestLocationPermission();
  bool notificationGranted = await PermissionManager.requestNotificationPermission();

}
@override
  void initState() {
    super.initState();
    // استدعاء دالة الصلاحيات بمجرد فتح الشاشة
    _requestAppPermissions();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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
      body: _pages[_selectedIndex],
    );
  }
}