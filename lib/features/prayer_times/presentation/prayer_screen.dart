import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart'; // ضروري لمعرفة الصلاة القادمة
import 'package:permission_handler/permission_handler.dart'; // لفتح الإعدادات

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
        title: const Text('مواقيت الصلاة', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<PrayerCubit, PrayerState>(
        builder: (context, state) {
          if (state is PrayerLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } 
          
          else if (state is PrayerError) {
            // 🎯 1. معالجة ذكية للأخطاء مع زر تفاعلي
            return _buildErrorView(context, state);
          } 
          
          else if (state is PrayerLoaded) {
            final times = state.prayerTimes;
            final currentPrayer = times.currentPrayer();
            final nextPrayer = times.nextPrayer();
            final nextPrayerTime = times.timeForPrayer(nextPrayer);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(), 
              children: [
                // 🎯 2. بطاقة المؤقت التنازلي المعزولة بذكاء لعدم استنزاف الأداء
                if (nextPrayer != Prayer.none && nextPrayerTime != null)
                  _NextPrayerCountdown(
                    nextPrayerName: _getPrayerNameInArabic(nextPrayer),
                    nextPrayerTime: nextPrayerTime,
                  ),
                
                const SizedBox(height: 24),

                // 🎯 3. رسم البطاقات مع تمييز الصلاة القادمة
                _buildPrayerCard('الفجر', times.fajr, isNext: nextPrayer == Prayer.fajr),
                _buildPrayerCard('الظهر', times.dhuhr, isNext: nextPrayer == Prayer.dhuhr),
                _buildPrayerCard('العصر', times.asr, isNext: nextPrayer == Prayer.asr),
                _buildPrayerCard('المغرب', times.maghrib, isNext: nextPrayer == Prayer.maghrib),
                _buildPrayerCard('العشاء', times.isha, isNext: nextPrayer == Prayer.isha),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ==============================================================
  // 🧩 دوال بناء الواجهة المساعدة (Helper Methods)
  // ==============================================================

  Widget _buildPrayerCard(String prayerName, DateTime time, {bool isNext = false}) {
    String formattedTime = DateFormat('hh:mm a', 'ar').format(time);
    
    return Card(
      // 🎯 إذا كانت الصلاة هي القادمة، نجعل لون البطاقة بارزاً قليلاً
      color: isNext ? AppColors.primary.withAlpha(25) : AppColors.cards, 
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // 🎯 إطار ذهبي سميك للصلاة القادمة، وخفيف للبقية
        side: BorderSide(color: AppColors.primary.withAlpha(isNext ? 200 : 30), width: isNext ? 2 : 1), 
      ),
      elevation: 0, 
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(prayerName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(formattedTime, style: TextStyle(color: isNext ? AppColors.primary : AppColors.textSecondary, fontSize: 22, fontWeight: FontWeight.bold)),
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
            const Icon(Icons.location_off_rounded, size: 70, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              state.message, 
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.5), 
              textAlign: TextAlign.center,
            ),
            // 🎯 إظهار الزر فقط إذا كان الخطأ بسبب الصلاحيات
            if (state.isPermissionError) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await openAppSettings();
                  if (context.mounted) {
                    context.read<PrayerCubit>().fetchPrayerTimesData();
                  }
                },
                icon: const Icon(Icons.settings, color: AppColors.background),
                label: const Text('فتح الإعدادات', style: TextStyle(fontSize: 16, color: AppColors.background, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  String _getPrayerNameInArabic(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.sunrise: return 'الشروق';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      case Prayer.none: return '';
    }
  }
}

// ==============================================================
// 🎯 الوجت المعزول للمؤقت التنازلي (حماية للأداء والبطارية)
// ==============================================================
class _NextPrayerCountdown extends StatelessWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;

  const _NextPrayerCountdown({
    required this.nextPrayerName,
    required this.nextPrayerTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(200), AppColors.primary.withAlpha(100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('باقي على أذان $nextPrayerName', style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 10),
          // 🎯 StreamBuilder لتحديث النص فقط كل ثانية بدون إعادة رسم الشاشة كلها
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final duration = nextPrayerTime.difference(DateTime.now());
              
              if (duration.isNegative) {
                return const Text('حان وقت الصلاة', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold));
              }

              String hours = duration.inHours.toString().padLeft(2, '0');
              String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
              String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

              return Text(
                '$hours:$minutes:$seconds',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
              );
            },
          ),
        ],
      ),
    );
  }
}