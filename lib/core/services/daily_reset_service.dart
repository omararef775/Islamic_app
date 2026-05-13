import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer; // 🎯 المكتبة الاحترافية لتسجيل الأحداث
import '../../features/adhkar/data/database_helper.dart'; 

class DailyResetService {
  static const String _lastOpenedDateKey = 'last_opened_date';

  static Future<void> checkAndResetIfNewDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? lastDateStr = prefs.getString(_lastOpenedDateKey);
      final DateTime now = DateTime.now();
      final String currentDateStr = "${now.year}-${now.month}-${now.day}";

      if (lastDateStr != currentDateStr) {
        // تصفير جميع العدادات في قاعدة البيانات
        await DatabaseHelper.instance.resetAllCounters();
        
        // حفظ تاريخ اليوم في الذاكرة
        await prefs.setString(_lastOpenedDateKey, currentDateStr);
        
        // 🎯 تسجيل الحدث باحترافية (يظهر لك فقط أثناء التطوير ولا يؤثر على تطبيق المتجر)
        developer.log(
          'Counters resetted for the new day: $currentDateStr', 
          name: 'DailyResetService',
        );
      }
    } catch (e) {
      // 🎯 تسجيل الأخطاء بصمت دون إزعاج المستخدم أو التسبب في انهيار التطبيق
      developer.log(
        'Failed to check and reset daily counters', 
        name: 'DailyResetService', 
        error: e,
      );
    }
  }
}