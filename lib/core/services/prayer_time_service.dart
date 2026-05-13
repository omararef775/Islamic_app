import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'dart:developer' as developer;

class PrayerTimeService {
  
  // 1. دالة جلب الموقع الجغرافي الفعلي الذكية
  static Future<Position?> getCurrentLocation() async {
    try {
      // أ. فحص الهاردوير: هل المستخدم قام بتشغيل زر الـ GPS من الستارة العلوية للهاتف؟
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('خدمة الـ GPS مغلقة في الهاتف.');
        // إرجاع خطأ صريح ليلتقطه الـ Cubit
        return Future.error('يرجى تشغيل زر الـ GPS من إعدادات الهاتف.');
      }

      // ب. فحص الصلاحيات: هل التطبيق مسموح له بالوصول للموقع؟
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('تم رفض صلاحية الموقع.');
          return Future.error('تم رفض صلاحية الوصول للموقع.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('الصلاحية مرفوضة نهائياً.');
        return Future.error('صلاحية الموقع مرفوضة نهائياً، يرجى تفعيلها من إعدادات التطبيق.');
      }

      // ج. جلب الموقع بدقة عالية بعد التأكد من كل شيء
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      developer.log("حدث خطأ غير متوقع أثناء جلب الموقع: $e", error: e);
      return Future.error('تعذر تحديد الموقع، تأكد من اتصالك بالشبكة.');
    }
  }

  // 2. دالة حساب أوقات الصلاة بناءً على الإحداثيات (تبقى كما هي)
  static PrayerTimes? getPrayerTimes(Position position) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    final date = DateComponents.from(DateTime.now());
    
    try {
      final prayerTimes = PrayerTimes(coordinates, date, params);
      return prayerTimes;
    } catch (e) {
      developer.log("حدث خطأ أثناء حساب الأوقات: $e");
      return null;
    }
  }
}