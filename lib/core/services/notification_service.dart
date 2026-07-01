import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🎯 معرف القناة كثابت مركزي لاستخدامه في الجدولة أيضاً
  static const String _channelId = 'adhan_audio_channel_v2';

  static Future<void> init() async {
    // تهيئة قاعدة بيانات المناطق الزمنية
    tz_data.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      // الاحتياط بالتوقيت السعودي كافتراضي
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }

    // إعدادات الأندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings: settings);

    // 🚀 الإصلاح الحاسم: إنشاء قناة الأذان برمجياً وتسجيلها لدى نظام أندرويد
    // عند إنشاء القناة بشكل صريح ومبكر، يتم تثبيت الصوت المخصص (adhan.mp3)
    // على القناة قبل أن ينشئها النظام بنفسه بصوت افتراضي مختلف.
    // ملاحظة: الأندرويد يمنع تعديل صوت قناة موجودة من قبل، لذا المعرف الجديد (_v2)
    // يضمن حذف أي قناة قديمة تم إنشاؤها بالصوت الافتراضي.
    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      _channelId,
      'إشعارات الأذان',
      description: 'قناة مخصصة لتنبيهات أوقات الصلاة بصوت الأذان',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adhanChannel);

    developer.log(
      'تم تهيئة خدمة الإشعارات وتسجيل قناة الأذان بنجاح',
      name: 'NotificationService',
    );
  }

  static Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    try {
      // تجاهل الأوقات التي مضت بالفعل
      if (prayerTime.isBefore(DateTime.now())) {
        return;
      }

      // 🎯 ربط إعدادات الإشعار بنفس معرف القناة المُسجَّلة في init()
      // هذا هو الرابط الحيوي الذي يضمن تشغيل الصوت المخصص (adhan.mp3)
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId, // ← نفس معرف القناة المسجلة أعلاه
        'إشعارات الأذان',
        channelDescription:
            'قناة مخصصة لتنبيهات أوقات الصلاة بصوت الأذان',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        enableVibration: true,
        // 🎯 ضمان ظهور الإشعار بوضوح حتى أثناء وضع عدم الإزعاج
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(prayerTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'حان الآن موعد صلاة $prayerName',
        body: 'حي على الصلاة، حي على الفلاح',
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      developer.log(
        'تمت جدولة أذان $prayerName في ${prayerTime.toString()}',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'فشل في جدولة أذان $prayerName',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    developer.log('تم إلغاء جميع إشعارات الأذان', name: 'NotificationService');
  }
}