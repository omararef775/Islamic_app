import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // ✅ التعديل الأول: تمرير الإعدادات باسمها الإجباري (settings:)
    await _notificationsPlugin.initialize(
      settings: settings,
    );
  }

  static Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    
    // 1. المعالجة الذكية للزمن: إذا مضى وقت الصلاة اليوم، اجدوله للغد
    DateTime timeToSchedule = prayerTime;
    if (timeToSchedule.isBefore(DateTime.now())) {
      timeToSchedule = timeToSchedule.add(const Duration(days: 1));
    }

   // 🚨 غيرنا الـ ID إلى 'adhan_audio_channel' لكي يجبر النظام على نسيان القناة القديمة الصامتة
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'adhan_audio_channel', 
      'إشعارات الأذان',
      channelDescription: 'قناة مخصصة لتنبيهات أوقات الصلاة بصوت الأذان',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // 👇 هذا هو السطر الذي سيقوم باستدعاء ملفك الصوتي (لاحظ أننا نكتب الاسم بدون .mp3)
      sound: RawResourceAndroidNotificationSound('adhan'), 
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 2. استخدمنا الوقت المعالج (timeToSchedule) بدلاً من الوقت القديم
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(timeToSchedule, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: 'حان الآن موعد صلاة $prayerName',
      body: 'حي على الصلاة، حي على الفلاح',
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  // دالة لإلغاء جميع الإشعارات (لإيقاف صوت الأذان فوراً)
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}