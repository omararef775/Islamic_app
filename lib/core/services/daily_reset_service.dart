import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../../features/adhkar/data/database_helper.dart';

// ==============================================================
// 🔄 خدمة التصفير اليومي لعدادات الأذكار
//
// 🎯 آلية العمل:
// - تُستدعى من main() عند تشغيل التطبيق
// - تُستدعى من AppLifecycleObserver عند استئناف التطبيق من الخلفية
// - تقارن تاريخ اليوم مع آخر تاريخ تصفير محفوظ
// - إذا اختلفا → تُصفِّر عدادات الصباح والمساء والأذكار المخصصة
// ==============================================================
class DailyResetService {
  static const String _lastResetDateKey = 'last_reset_date';

  // ==============================================================
  // ✅ الدالة الرئيسية: تفحص وتُصفِّر إذا كان اليوم جديداً
  // ==============================================================
  static Future<void> checkAndResetIfNewDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastDateStr = prefs.getString(_lastResetDateKey);

      // استخدام DateFormat لضمان صيغة ثابتة دائماً (YYYY-MM-DD)
      final DateTime now = DateTime.now();
      final String currentDateStr = DateFormat('yyyy-MM-dd').format(now);

      if (lastDateStr != currentDateStr) {
        // 🎯 يوم جديد: صفّر العدادات واحفظ التاريخ
        await DatabaseHelper.instance.resetAllCounters();
        await prefs.setString(_lastResetDateKey, currentDateStr);

        developer.log(
          '✅ تم تصفير عدادات الأذكار ليوم: $currentDateStr (آخر تصفير: ${lastDateStr ?? "أول مرة"})',
          name: 'DailyResetService',
        );
      } else {
        developer.log(
          '⏭️ لا حاجة للتصفير - التاريخ الحالي: $currentDateStr',
          name: 'DailyResetService',
        );
      }
    } catch (e) {
      developer.log(
        '❌ فشل فحص/تصفير العدادات اليومية',
        name: 'DailyResetService',
        error: e,
      );
    }
  }
}