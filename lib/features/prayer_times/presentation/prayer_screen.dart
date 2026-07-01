import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:permission_handler/permission_handler.dart';

import 'manager/prayer_cubit.dart';
import 'manager/prayer_state.dart';
import '../../../../core/theme/app_colors.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'مواقيت الصلاة',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<PrayerCubit, PrayerState>(
        builder: (context, state) {
          if (state is PrayerLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is PrayerError) {
            return _buildErrorView(context, state);
          }

          if (state is PrayerLoaded) {
            final times = state.prayerTimes;

            // 🎯 الإصلاح الرئيسي: تجاوز "الشروق" لأنه ليس صلاة مفروضة
            // نستخدم دالة مساعدة لتحديد الصلاة الفريضة التالية فعلياً
            final Prayer nextObligatoryPrayer = _getNextObligatoryPrayer(times);
            final DateTime? nextPrayerTime =
                nextObligatoryPrayer != Prayer.none
                    ? times.timeForPrayer(nextObligatoryPrayer)
                    : null;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              children: [
                // 🎯 بطاقة العداد التنازلي الذكية المعزولة
                if (nextObligatoryPrayer != Prayer.none && nextPrayerTime != null)
                  _NextPrayerCountdown(
                    nextPrayerName: _getPrayerNameInArabic(nextObligatoryPrayer),
                    nextPrayerTime: nextPrayerTime,
                    onTimeElapsed: () {
                      // 🎯 الإصلاح: إعادة جلب البيانات تلقائياً عند انتهاء وقت الصلاة
                      // لتحديث العداد للصلاة التالية بدون الحاجة للمستخدم
                      context.read<PrayerCubit>().fetchPrayerTimesData();
                    },
                  ),

                const SizedBox(height: 24),

                // 🎯 بطاقات الصلوات الخمس مع تمييز الصلاة التالية بشكل صحيح
                _buildPrayerCard(
                  'الفجر',
                  times.fajr,
                  isNext: nextObligatoryPrayer == Prayer.fajr,
                ),
                _buildPrayerCard(
                  'الظهر',
                  times.dhuhr,
                  isNext: nextObligatoryPrayer == Prayer.dhuhr,
                ),
                _buildPrayerCard(
                  'العصر',
                  times.asr,
                  isNext: nextObligatoryPrayer == Prayer.asr,
                ),
                _buildPrayerCard(
                  'المغرب',
                  times.maghrib,
                  isNext: nextObligatoryPrayer == Prayer.maghrib,
                ),
                _buildPrayerCard(
                  'العشاء',
                  times.isha,
                  isNext: nextObligatoryPrayer == Prayer.isha,
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ==============================================================
  // 🎯 الإصلاح الأساسي: دالة تحدد الصلاة المفروضة التالية بتجاوز الشروق
  // ==============================================================
  Prayer _getNextObligatoryPrayer(PrayerTimes times) {
    Prayer next = times.nextPrayer();

    // إذا كانت الصلاة "التالية" هي الشروق، نتخطاها ونتوجه للظهر مباشرة
    // لأن الشروق وقت نهي وليس صلاة مفروضة
    if (next == Prayer.sunrise) {
      return Prayer.dhuhr;
    }

    return next;
  }

  // ==============================================================
  // 🧩 دوال بناء الواجهة المساعدة
  // ==============================================================

  Widget _buildPrayerCard(String prayerName, DateTime time,
      {bool isNext = false}) {
    String formattedTime = DateFormat('hh:mm a', 'ar').format(time);

    return Card(
      color: isNext ? AppColors.primary.withAlpha(25) : AppColors.cards,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: AppColors.primary.withAlpha(isNext ? 200 : 30),
          width: isNext ? 2 : 1,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prayerName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formattedTime,
              style: TextStyle(
                color: isNext ? AppColors.primary : AppColors.textSecondary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, PrayerError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 70, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              state.message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.isPermissionError) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await openAppSettings();
                  if (context.mounted) {
                    context.read<PrayerCubit>().fetchPrayerTimesData();
                  }
                },
                icon: const Icon(Icons.settings, color: AppColors.background),
                label: const Text(
                  'فتح الإعدادات',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  String _getPrayerNameInArabic(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
        return '';
    }
  }
}

// ==============================================================
// 🎯 الوجت المعزول للعداد التنازلي مع دعم التحديث التلقائي
// ==============================================================
class _NextPrayerCountdown extends StatefulWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final VoidCallback onTimeElapsed; // 🎯 callback لإعلام الشاشة بانتهاء الوقت

  const _NextPrayerCountdown({
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.onTimeElapsed,
  });

  @override
  State<_NextPrayerCountdown> createState() => _NextPrayerCountdownState();
}

class _NextPrayerCountdownState extends State<_NextPrayerCountdown> {
  late Timer _timer;
  bool _hasNotified = false; // 🛡️ حماية من استدعاء الـ callback أكثر من مرة

  @override
  void initState() {
    super.initState();
    // 🎯 استخدام Timer دوري بدلاً من StreamBuilder لأداء أفضل وتحكم أدق
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final remaining = widget.nextPrayerTime.difference(DateTime.now());

      // إذا انتهى وقت الصلاة، ننبه الشاشة الأب مرة واحدة فقط
      if (remaining.isNegative && !_hasNotified) {
        _hasNotified = true;
        // تأخير بسيط لضمان انتهاء عملية الـ build الحالية قبل الاستدعاء
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onTimeElapsed();
          }
        });
      }

      setState(() {}); // تحديث بسيط كل ثانية لإعادة رسم العداد فقط
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // 🛡️ وقف الـ Timer بعد إغلاق الوجت لحماية البطارية
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.nextPrayerTime.difference(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(200),
            AppColors.primary.withAlpha(100),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'باقي على أذان ${widget.nextPrayerName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          if (duration.isNegative)
            // 🎯 رسالة احترافية تظهر بينما يتم تحديث البيانات تلقائياً
            const Column(
              children: [
                Text(
                  'حان وقت الصلاة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            )
          else
            Text(
              '${duration.inHours.toString().padLeft(2, '0')}:'
              '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
              '${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
        ],
      ),
    );
  }
}