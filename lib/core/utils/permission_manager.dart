import 'dart:io'; // 🎯 التعديل 1: استدعاء مكتبة io لمعرفة نوع نظام التشغيل
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  // 1. دالة طلب إذن الموقع الجغرافي (مواقيت الصلاة والقبلة)
  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // 2. دالة طلب إذن الإشعارات (لإطلاق صوت الأذان والتنبيهات في أندرويد 13+)
  static Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // 3. 🎯 الدالة المثالية لطلب إذن المنبه الدقيق (محمية معمارياً)
  static Future<bool> requestExactAlarmPermission() async {
    // التعديل 2: نطلب الإذن فقط إذا كان الهاتف أندرويد
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.scheduleExactAlarm.status;

      if (status.isDenied) {
        status = await Permission.scheduleExactAlarm.request();
      }

      // التعديل 3: في أندرويد 14، يجب نقل المستخدم للإعدادات لتفعيلها يدوياً
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    }

    // التعديل 4: إذا كان الهاتف iOS، نرجع (صح) فوراً لكي يكمل التطبيق عمله بدون مشاكل
    return true;
  }
}
