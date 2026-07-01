import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // تهيئة قاعدة بيانات المناطق الزمنية
    tz_data.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier; 

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }

    // إعدادات الأندرويد
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // 🎯 التصحيح القطعي هنا: استخدام المتغير settings كما يطلب الكومبايلر
    await _notificationsPlugin.initialize(
      settings: settings, 
    );
  }

  static Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    try {
      // تجاهل الأوقات التي مضت بالفعل لليوم الحالي
      if (prayerTime.isBefore(DateTime.now())) {
        return; 
      }

      // إعدادات قناة الإشعارات
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'adhan_audio_channel',
        'إشعارات الأذان',
        channelDescription: 'قناة مخصصة لتنبيهات أوقات الصلاة بصوت الأذان',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'), 
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(prayerTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'حان الآن موعد صلاة $prayerName',
        body: 'حي على الصلاة، حي على الفلاح',
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      );
    } catch (e) {
      developer.log(
        "فشل في جدولة أذان $prayerName",
        name: 'NotificationService',
        error: e,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}