import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  // 1. دالة طلب إذن الموقع الجغرافي
  static Future<bool> requestLocationPermission() async {
    // التحقق من الحالة الحالية للصلاحية في نظام التشغيل
    PermissionStatus status = await Permission.location.status;
    // إذا كانت الصلاحية مرفوضة (أو لم تُطلب من قبل)
    if (status.isDenied) {
      // إظهار الرسالة المنبثقة للمستخدم لطلب الصلاحية
      status = await Permission.location.request();
    }

    // إذا قام المستخدم بالرفض النهائي (في الأندرويد، لا يمكن إظهار الرسالة مرة أخرى)
    if (status.isPermanentlyDenied) {
      // سنقوم لاحقاً ببرمجة توجيه المستخدم لإعدادات الهاتف يدوياً
      await openAppSettings();
      return false;
    }

    // إرجاع (صح) إذا وافق، و (خطأ) إذا رفض
    return status.isGranted;
  }

  // 2. دالة طلب إذن الإشعارات (للأذان والتنبيهات)
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
}