import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

class PrayerTimeService {
  
  // 1. دالة جلب الموقع الجغرافي الفعلي من شريحة الـ GPS
  static Future<Position?> getCurrentLocation() async {
    try {
      // نطلب من الشريحة إعطاءنا الموقع بدقة عالية باستخدام الهيكل الجديد
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print("حدث خطأ أثناء جلب الموقع: $e");
      return null;
    }
  }

  // 2. دالة حساب أوقات الصلاة بناءً على الإحداثيات
  static PrayerTimes? getPrayerTimes(Position position) {
    // تجهيز خطوط الطول والعرض
    final coordinates = Coordinates(position.latitude, position.longitude);
    
    // ضبط إعدادات الحساب الفلكية
    // نستخدم تقويم "أم القرى" لأنه المعيار الأدق المعتمد في شبه الجزيرة العربية واليمن
    final params = CalculationMethod.umm_al_qura.getParameters();
    
    // ضبط المذهب الشافعي (وهو السائد في المنطقة) لحساب وقت صلاة العصر بدقة
    params.madhab = Madhab.shafi; 

    // جلب تاريخ اليوم
    final date = DateComponents.from(DateTime.now());

    // إدخال المعطيات في محرك الحساب واستخراج الأوقات
    try {
      final prayerTimes = PrayerTimes(coordinates, date, params);
      return prayerTimes;
    } catch (e) {
      print("حدث خطأ أثناء حساب الأوقات: $e");
      return null;
    }
  }
}