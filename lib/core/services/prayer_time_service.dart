import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class PrayerTimeService {
  // مفاتيح التخزين المحلي (Caching)
  static const String _latKey = 'cached_lat';
  static const String _lngKey = 'cached_lng';
  static const String _madhabKey = 'cached_madhab'; // 0 للشافعي/الجمهور، 1 للحنفي

  // 1. 🎯 جلب الموقع (الذاكرة أولاً لتوفير البطارية، أو GPS إذا كانت أول مرة)
  static Future<Position?> getLocation({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // أ. فحص الذاكرة المحلية (Cache) لتجاوز استنزاف الـ GPS والعمل في الأماكن المغلقة
    if (!forceRefresh && prefs.containsKey(_latKey) && prefs.containsKey(_lngKey)) {
      return Position(
        latitude: prefs.getDouble(_latKey)!,
        longitude: prefs.getDouble(_lngKey)!,
        timestamp: DateTime.now(),
        accuracy: 100.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0, headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0,
      );
    }

    // ب. إذا لم يوجد موقع مخزن، نطلب تشغيل الـ GPS لأول مرة
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('يرجى تشغيل زر الـ GPS من إعدادات الهاتف.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('تم رفض صلاحية الوصول للموقع.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // 🎯 إرجاع الخطأ مع علامة خاصة لكي تظهر الشاشة زر (الإعدادات)
      return Future.error('PERMISSION_DENIED_FOREVER');
    }

    Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    
    // 🎯 حفظ الإحداثيات في الذاكرة لتجنب طلبها في المرات القادمة
    await prefs.setDouble(_latKey, position.latitude);
    await prefs.setDouble(_lngKey, position.longitude);
    
    return position;
  }

  // 2. 🎯 الحساب الفلكي الديناميكي (يدعم تغيير المذهب الفقهي لصلاة العصر)
  static Future<PrayerTimes?> getPrayerTimes(Position position, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    
    // قراءة المذهب المحفوظ من إعدادات المستخدم (الافتراضي هو الشافعي/الجمهور)
    final savedMadhabIndex = prefs.getInt(_madhabKey) ?? Madhab.shafi.index;

    final coordinates = Coordinates(position.latitude, position.longitude);
    
    // استخدام طريقة أم القرى كمعيار ممتاز للجزيرة العربية، مع تمرير المذهب الديناميكي
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = savedMadhabIndex == Madhab.hanafi.index ? Madhab.hanafi : Madhab.shafi;
    
    final dateComponents = DateComponents.from(date);
    
    try {
      return PrayerTimes(coordinates, dateComponents, params);
    } catch (e) {
      developer.log("حدث خطأ أثناء حساب الأوقات: $e");
      return null;
    }
  }

  // 3. 🎯 دالة مساعدة لحفظ اختيار المذهب الفقهي
  static Future<void> saveMadhab(Madhab madhab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_madhabKey, madhab.index);
  }
}