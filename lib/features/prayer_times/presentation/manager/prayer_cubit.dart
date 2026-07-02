import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'dart:developer' as developer;

import 'prayer_state.dart';
import '../../../../core/services/prayer_time_service.dart';
import '../../../../core/services/notification_service.dart';

class PrayerCubit extends Cubit<PrayerState> {
  PrayerCubit() : super(PrayerLoading());

  Future<void> fetchPrayerTimesData() async {
    emit(PrayerLoading());
    try {
      Position? position = await PrayerTimeService.getLocation(
        forceRefresh: false,
      );

      if (position != null) {
        PrayerTimes? todayTimes = await PrayerTimeService.getPrayerTimes(
          position,
          DateTime.now(),
        );

        if (todayTimes != null) {
          // 🎯 جدولة الأذان للأيام القادمة في الخلفية
          _schedulePrayersForNextDays(position);

          emit(PrayerLoaded(todayTimes));
        } else {
          emit(
            const PrayerError("حدث خطأ أثناء الحساب الفلكي لمواقيت الصلاة."),
          );
        }
      }
    } catch (error) {
      if (error.toString().contains('PERMISSION_DENIED_FOREVER')) {
        emit(
          const PrayerError(
            'صلاحية الموقع مرفوضة نهائياً. يرجى تفعيلها من إعدادات الهاتف لحساب أوقات الصلاة.',
            isPermissionError: true,
          ),
        );
      } else {
        emit(PrayerError(error.toString()));
      }
    }
  }

  // ==============================================================
  // ⏰ جدولة الأذان للأيام القادمة
  //
  // 🎯 تحسينات معمارية مهمة:
  // 1. تقليص من 30 يوماً إلى 7 أيام فقط لتجنب تجاوز حد أندرويد
  //    (بعض أجهزة أندرويد تقتصر على 500 إشعار مجدول كحد أقصى)
  //    5 صلوات × 7 أيام = 35 إشعاراً فقط (آمن تماماً)
  //
  // 2. استخدام "await" لكل جدولة لضمان الترتيب وتجنب التسابق (Race Condition)
  //
  // 3. إضافة سجل شامل لتشخيص المشاكل مستقبلاً
  // ==============================================================
  void _schedulePrayersForNextDays(Position position) async {
    developer.log(
      '🚀 بدء جدولة إشعارات الأذان للأيام السبعة القادمة',
      name: 'PrayerCubit',
    );

    // إلغاء جميع الإشعارات المجدولة سابقاً لبدء جدولة نظيفة
    await NotificationService.cancelAll();

    final DateTime now = DateTime.now();
    int scheduledCount = 0;
    int skippedCount = 0;

    // 🎯 7 أيام = 35 إشعاراً (آمن ومحافظ على حدود أندرويد)
    for (int i = 0; i < 7; i++) {
      DateTime targetDate = now.add(Duration(days: i));
      PrayerTimes? times = await PrayerTimeService.getPrayerTimes(
        position,
        targetDate,
      );

      if (times == null) {
        developer.log(
          '⚠️ تعذر حساب أوقات اليوم ${i + 1}، تم التخطي',
          name: 'PrayerCubit',
        );
        continue;
      }

      // إنشاء معرفات فريدة لكل صلاة في كل يوم
      final int fajrId    = _generateUniqueId(targetDate, 1);
      final int dhuhrId   = _generateUniqueId(targetDate, 2);
      final int asrId     = _generateUniqueId(targetDate, 3);
      final int maghribId = _generateUniqueId(targetDate, 4);
      final int ishaId    = _generateUniqueId(targetDate, 5);

      // 🎯 جدولة الصلوات الخمس للبوم المحدد
      // نستخدم await لضمان الترتيب الصحيح لكل طلب
      final Map<String, dynamic> prayers = {
        'الفجر':   {'id': fajrId,    'time': times.fajr},
        'الظهر':   {'id': dhuhrId,   'time': times.dhuhr},
        'العصر':   {'id': asrId,     'time': times.asr},
        'المغرب':  {'id': maghribId, 'time': times.maghrib},
        'العشاء':  {'id': ishaId,    'time': times.isha},
      };

      for (final entry in prayers.entries) {
        final DateTime prayerTime = entry.value['time'] as DateTime;

        // تخطي الصلوات التي مضى وقتها
        if (prayerTime.isBefore(now)) {
          skippedCount++;
          continue;
        }

        await NotificationService.scheduleAdhan(
          id: entry.value['id'] as int,
          prayerName: entry.key,
          prayerTime: prayerTime,
        );
        scheduledCount++;
      }
    }

    developer.log(
      '✅ اكتملت الجدولة: $scheduledCount إشعاراً مجدولاً، $skippedCount تم تخطيه (مضى وقته)',
      name: 'PrayerCubit',
    );
  }

  // ==============================================================
  // 🔑 توليد معرف فريد لكل صلاة في كل يوم
  // التنسيق: MMDD + رقم الصلاة (1-5)
  // مثال: صلاة الفجر يوم 02-15 = 021501
  // ==============================================================
  int _generateUniqueId(DateTime date, int prayerIndex) {
    final String idString =
        '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}$prayerIndex';
    return int.parse(idString);
  }
}
