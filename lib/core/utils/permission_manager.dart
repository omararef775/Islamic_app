import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

// ==============================================================
// 🛡️ مدير الصلاحيات المركزي للتطبيق
// يتعامل مع أندرويد 12+ و 13+ و 14+ بطريقة متوافقة مع Google Play
// ==============================================================
class PermissionManager {

  // ==============================================================
  // 📍 صلاحية الموقع الجغرافي (لحساب أوقات الصلاة واتجاه القبلة)
  // ==============================================================
  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      developer.log(
        '⚠️ صلاحية الموقع مرفوضة نهائياً، إرسال المستخدم للإعدادات',
        name: 'PermissionManager',
      );
      await openAppSettings();
      return false;
    }

    final bool granted = status.isGranted;
    developer.log(
      'صلاحية الموقع: ${granted ? "✅ ممنوحة" : "❌ مرفوضة"}',
      name: 'PermissionManager',
    );
    return granted;
  }

  // ==============================================================
  // 🔔 صلاحية الإشعارات (ضرورية على أندرويد 13+)
  // ==============================================================
  static Future<bool> requestNotificationPermission() async {
    // على أندرويد 12 وما دون الإشعارات لا تحتاج إذن
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.notification.status;

      if (status.isDenied) {
        status = await Permission.notification.request();
      }

      if (status.isPermanentlyDenied) {
        developer.log(
          '⚠️ صلاحية الإشعارات مرفوضة نهائياً، إرسال المستخدم للإعدادات',
          name: 'PermissionManager',
        );
        await openAppSettings();
        return false;
      }

      final bool granted = status.isGranted;
      developer.log(
        'صلاحية الإشعارات: ${granted ? "✅ ممنوحة" : "❌ مرفوضة"}',
        name: 'PermissionManager',
      );
      return granted;
    }

    return true; // iOS لا تحتاج هذا الإذن بنفس الطريقة
  }

  // ==============================================================
  // ⏰ صلاحية المنبه الدقيق (أندرويد 12+)
  //
  // 🎯 السلوك الذكي:
  // - نطلب الصلاحية برفق دون إرسال المستخدم للإعدادات تلقائياً
  // - إذا رُفضت، يعمل التطبيق بالجدولة التقريبية كبديل تلقائي
  // - هذا التصميم متوافق مع متجر Google Play (لأننا نستخدم SCHEDULE_EXACT_ALARM)
  // ==============================================================
  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      PermissionStatus status = await Permission.scheduleExactAlarm.status;

      developer.log(
        'حالة صلاحية المنبه الدقيق: ${status.name}',
        name: 'PermissionManager',
      );

      // 🟡 مرفوضة أو غير محددة: نطلبها برفق
      if (status.isDenied) {
        status = await Permission.scheduleExactAlarm.request();
        developer.log(
          'بعد الطلب: ${status.name}',
          name: 'PermissionManager',
        );
      }

      // ⚠️ مرفوضة نهائياً: لا نُرسل المستخدم للإعدادات قسراً
      // بدلاً من ذلك، نُعلم التطبيق أنه سيعمل بوضع الجدولة التقريبية
      if (status.isPermanentlyDenied) {
        developer.log(
          '⚠️ المنبه الدقيق مرفوض. سيعمل التطبيق بالجدولة التقريبية (Fallback)',
          name: 'PermissionManager',
        );
        return false; // يمر بسلاسة: NotificationService سيستخدم inexactAllowWhileIdle
      }

      final bool granted = status.isGranted;
      developer.log(
        'صلاحية المنبه الدقيق: ${granted ? "✅ ممنوحة - جدولة دقيقة" : "🔄 مرفوضة - جدولة تقريبية"}',
        name: 'PermissionManager',
      );
      return granted;

    } catch (e) {
      // 🛡️ أي خطأ غير متوقع لا يوقف التطبيق
      developer.log(
        '⚠️ خطأ في فحص صلاحية المنبه الدقيق',
        name: 'PermissionManager',
        error: e,
      );
      return false;
    }
  }
}
