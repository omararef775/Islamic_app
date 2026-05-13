import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

import 'prayer_state.dart'; // نستدعي ملف الحالات الذي صنعناه للتو
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/notification_service.dart';

// 1. إنشاء الـ Cubit وإخباره أنه سيتعامل فقط مع الفئة الأم PrayerState
class PrayerCubit extends Cubit<PrayerState> {
  
  // 2. المُنشئ (Constructor): أول ما يشتغل الـ Cubit، نأمره بالبدء بحالة "التحميل" فوراً
  PrayerCubit() : super(PrayerLoading());

  // 3. دالة جلب الأوقات (نفس الدالة التي كانت في الشاشة، نقلناها هنا)
  Future<void> fetchPrayerTimesData() async {
    // نبث حالة التحميل (لكي تدور الدائرة في الشاشة)
    emit(PrayerLoading());

    try {
      // إذا كان الـ GPS مغلقاً أو لا توجد صلاحيات، ستقوم هذه الدالة برمي Exception
      Position? position = await PrayerTimeService.getCurrentLocation();
      
      if (position != null) {
        PrayerTimes? times = PrayerTimeService.getPrayerTimes(position);
        if (times != null) {
          _scheduleAllPrayers(times);
          emit(PrayerLoaded(times));
        } else {
          emit(const PrayerError("حدث خطأ أثناء الحساب الفلكي لمواقيت الصلاة."));
        }
      } 
    } catch (error) {
      // 🎯 التقاط الخطأ الحقيقي القادم من السيرفيس وعرضه للمستخدم
      emit(PrayerError(error.toString()));
    }
  }

  // 4. دالة الجدولة (نقلناها كما هي من الشاشة)
  void _scheduleAllPrayers(PrayerTimes times) {
    // الجدولة الحقيقية
    NotificationService.scheduleAdhan(id: 1, prayerName: 'الفجر', prayerTime: times.fajr);
    NotificationService.scheduleAdhan(id: 2, prayerName: 'الظهر', prayerTime: times.dhuhr);
    NotificationService.scheduleAdhan(id: 3, prayerName: 'العصر', prayerTime: times.asr);
    NotificationService.scheduleAdhan(id: 4, prayerName: 'المغرب', prayerTime: times.maghrib);
    NotificationService.scheduleAdhan(id: 5, prayerName: 'العشاء', prayerTime: times.isha);
  }
}