import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:developer' as developer;
import 'dart:io';

// ==============================================================
// 🎯 معالج إجراءات الإشعار في الخلفية
// CRITICAL: يجب أن تكون دالة خارجية (Top-level) وليست داخل كلاس
// والوسم @pragma ضروري لمنع Dart Compiler من حذفها في Release Mode
// ==============================================================
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final String? actionId = notificationResponse.actionId;
  final int notificationId = notificationResponse.id ?? -1;

  developer.log(
    'تم استقبال إجراء خلفي | action=$actionId | id=$notificationId',
    name: 'AdhanBackground',
  );

  // 🛑 إيقاف الأذان فوراً عند الضغط على زر "إيقاف الأذان" من خارج التطبيق
  if (actionId == 'stop_adhan_action') {
    if (notificationId != -1) {
      FlutterLocalNotificationsPlugin().cancel(id: notificationId);
      developer.log(
        '✅ تم إيقاف الأذان بنجاح من خارج التطبيق (ID: $notificationId)',
        name: 'AdhanBackground',
      );
    }
  }
}

// ==============================================================
// 📢 خدمة الإشعارات المركزية لإدارة أذان الصلوات الخمس
// ==============================================================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🎯 v3: معرف قناة جديد لإجبار أندرويد على إنشاء قناة جديدة
  // بالصوت المخصص المحدد، متجاوزاً كاش القناة القديمة
  static const String _channelId = 'adhan_audio_channel_v3';
  static const String _channelName = 'إشعارات الأذان';
  static const String _channelDescription =
      'قناة مخصصة لتنبيهات أوقات الصلاة بصوت الأذان الحقيقي';

  // ==============================================================
  // 🚀 تهيئة الخدمة في بداية التطبيق
  // ==============================================================
  static Future<void> init() async {
    // 1️⃣ تهيئة قاعدة بيانات المناطق الزمنية
    tz_data.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      developer.log(
        'المنطقة الزمنية: ${timezoneInfo.identifier}',
        name: 'NotificationService',
      );
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      developer.log(
        'تحذير: تعذر تحديد المنطقة الزمنية، يُستخدم Asia/Riyadh كافتراضي',
        name: 'NotificationService',
        error: e,
      );
    }

    // 2️⃣ إعدادات تهيئة أندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // 3️⃣ تهيئة المكتبة مع معالجات الاستجابة (Named parameters في v21)
    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 4️⃣ إنشاء قناة الأذان الصوتية المخصصة مبكراً
    await _createAdhanChannel();

    developer.log(
      '✅ تهيئة خدمة الإشعارات اكتملت بنجاح',
      name: 'NotificationService',
    );
  }

  // ==============================================================
  // 🎵 إنشاء قناة الأذان بالصوت المخصص
  // ==============================================================
  static Future<void> _createAdhanChannel() async {
    if (!Platform.isAndroid) return;

    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      // 🔊 الصوت المخصص: android/app/src/main/res/raw/adhan.mp3
      sound: RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adhanChannel);

    developer.log(
      '✅ تم إنشاء قناة الأذان: $_channelId',
      name: 'NotificationService',
    );
  }

  // ==============================================================
  // 🔔 معالج النقر على الإشعار (التطبيق قيد التشغيل أو في الخلفية)
  // ==============================================================
  static void _onNotificationTap(NotificationResponse response) {
    final String? actionId = response.actionId;
    final int notificationId = response.id ?? -1;

    developer.log(
      'نقر على الإشعار | action=$actionId | id=$notificationId',
      name: 'NotificationService',
    );

    // 🛑 إيقاف صوت الأذان عند الضغط على زر "إيقاف الأذان"
    if (actionId == 'stop_adhan_action') {
      if (notificationId != -1) {
        _notificationsPlugin.cancel(id: notificationId);
        developer.log(
          '✅ تم إيقاف الأذان من داخل التطبيق (ID: $notificationId)',
          name: 'NotificationService',
        );
      }
    }
  }

  // ==============================================================
  // ⏰ جدولة أذان صلاة محددة
  // ==============================================================
  static Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    try {
      // 🛡️ تجاهل الأوقات التي مضت بالفعل
      if (prayerTime.isBefore(DateTime.now())) {
        return;
      }

      // 🎯 اختيار نمط الجدولة بناءً على الصلاحيات المتاحة
      final AndroidScheduleMode scheduleMode =
          await _getOptimalScheduleMode();

      // 🎨 تفاصيل الإشعار مع زر "إيقاف الأذان"
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        enableVibration: true,
        // 🔔 إظهار الإشعار فوق شاشة القفل
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        // 🔕 لا يلغي نفسه تلقائياً لإتاحة الفرصة لإيقاف الصوت
        autoCancel: false,
        // 🎯 زر "إيقاف الأذان" يظهر في الإشعار
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_adhan_action',    // المعرف الفريد للإجراء
            '🔇 إيقاف الأذان',      // النص الذي يراه المستخدم
            cancelNotification: true,  // يلغي الإشعار تلقائياً عند الضغط
            showsUserInterface: false, // لا يفتح التطبيق
          ),
        ],
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(prayerTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'حان وقت أذان $prayerName 🕌',
        body: 'حيَّ على الصلاة، حيَّ على الفلاح',
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: scheduleMode,
      );

      developer.log(
        '⏰ جُدِّل أذان $prayerName في ${prayerTime.toString()} | نمط: ${scheduleMode.name}',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        '❌ فشل جدولة أذان $prayerName',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  // ==============================================================
  // 🧠 تحديد أفضل نمط جدولة بناءً على صلاحيات الجهاز
  // ==============================================================
  static Future<AndroidScheduleMode> _getOptimalScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;

    try {
      final bool? canScheduleExact = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();

      if (canScheduleExact == true) {
        developer.log(
          '✅ استخدام الجدولة الدقيقة (exactAllowWhileIdle)',
          name: 'NotificationService',
        );
        return AndroidScheduleMode.exactAllowWhileIdle;
      } else {
        developer.log(
          '⚠️ الصلاحية الدقيقة غير متاحة، استخدام inexactAllowWhileIdle كـ Fallback',
          name: 'NotificationService',
        );
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (e) {
      developer.log(
        '⚠️ خطأ في فحص الصلاحية، fallback لـ inexactAllowWhileIdle',
        name: 'NotificationService',
        error: e,
      );
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  // ==============================================================
  // 🔕 إلغاء إشعار أذان معين بمعرفه
  // ==============================================================
  static Future<void> cancelAdhan(int notificationId) async {
    await _notificationsPlugin.cancel(id: notificationId);
    developer.log(
      '🔕 تم إلغاء الأذان بالمعرف: $notificationId',
      name: 'NotificationService',
    );
  }

  // ==============================================================
  // 🗑️ إلغاء جميع إشعارات الأذان المجدولة
  // ==============================================================
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    developer.log(
      '🗑️ تم إلغاء جميع إشعارات الأذان',
      name: 'NotificationService',
    );
  }
}