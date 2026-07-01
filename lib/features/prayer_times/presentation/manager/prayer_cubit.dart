import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

import 'prayer_state.dart'; 
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/notification_service.dart';

class PrayerCubit extends Cubit<PrayerState> {
  
  PrayerCubit() : super(PrayerLoading());

  Future<void> fetchPrayerTimesData() async {
    emit(PrayerLoading());
    try {
      Position? position = await PrayerTimeService.getLocation(forceRefresh: false);
      
      if (position != null) {
        PrayerTimes? todayTimes = await PrayerTimeService.getPrayerTimes(position, DateTime.now());
        
        if (todayTimes != null) {
          // 🎯 انطلقنا بالجدولة لـ 30 يوماً كاملة (شهر كامل من الأذان بلا توقف)
          _schedulePrayersForNextDays(position);
          
          emit(PrayerLoaded(todayTimes));
        } else {
          emit(const PrayerError("حدث خطأ أثناء الحساب الفلكي لمواقيت الصلاة."));
        }
      } 
    } catch (error) {
      if (error.toString().contains('PERMISSION_DENIED_FOREVER')) {
        emit(const PrayerError(
          'صلاحية الموقع مرفوضة نهائياً. يرجى تفعيلها من إعدادات الهاتف لحساب أوقات الصلاة.',
          isPermissionError: true, 
        ));
      } else {
        emit(PrayerError(error.toString()));
      }
    }
  }

  // 🎯 الجدولة الآمنة والممتدة للأندرويد
  void _schedulePrayersForNextDays(Position position) async {
    await NotificationService.cancelAll();

    final DateTime now = DateTime.now();

    // 🎯 تم التعديل إلى 30 يوماً
    for (int i = 0; i < 30; i++) {
      DateTime targetDate = now.add(Duration(days: i));
      PrayerTimes? times = await PrayerTimeService.getPrayerTimes(position, targetDate);

      if (times != null) {
        int fajrId = _generateUniqueId(targetDate, 1);
        int dhuhrId = _generateUniqueId(targetDate, 2);
        int asrId = _generateUniqueId(targetDate, 3);
        int maghribId = _generateUniqueId(targetDate, 4);
        int ishaId = _generateUniqueId(targetDate, 5);

        NotificationService.scheduleAdhan(id: fajrId, prayerName: 'الفجر', prayerTime: times.fajr);
        NotificationService.scheduleAdhan(id: dhuhrId, prayerName: 'الظهر', prayerTime: times.dhuhr);
        NotificationService.scheduleAdhan(id: asrId, prayerName: 'العصر', prayerTime: times.asr);
        NotificationService.scheduleAdhan(id: maghribId, prayerName: 'المغرب', prayerTime: times.maghrib);
        NotificationService.scheduleAdhan(id: ishaId, prayerName: 'العشاء', prayerTime: times.isha);
      }
    }
  }

  int _generateUniqueId(DateTime date, int prayerIndex) {
    String idString = '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}$prayerIndex';
    return int.parse(idString);
  }
}