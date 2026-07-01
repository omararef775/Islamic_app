import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer; 
import 'package:intl/intl.dart'; // 🎯 استدعاء مكتبة التنسيق
import '../../features/adhkar/data/database_helper.dart';

class DailyResetService {
  static const String _lastOpenedDateKey = 'last_opened_date';

  static Future<void> checkAndResetIfNewDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastDateStr = prefs.getString(_lastOpenedDateKey);
      
      // 🎯 هندسة التواريخ: استخدام DateFormat يضمن صيغة ثابتة دائماً (YYYY-MM-DD)
      final DateTime now = DateTime.now();
      final String currentDateStr = DateFormat('yyyy-MM-dd').format(now);

      if (lastDateStr != currentDateStr) {
        await DatabaseHelper.instance.resetAllCounters();
        await prefs.setString(_lastOpenedDateKey, currentDateStr);
        
        developer.log('Counters resetted for the new day: $currentDateStr', name: 'DailyResetService');
      }
    } catch (e) {
      developer.log('Failed to check and reset daily counters', name: 'DailyResetService', error: e);
    }
  }
}