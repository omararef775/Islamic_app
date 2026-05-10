import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'manager/prayer_cubit.dart';
import 'manager/prayer_state.dart';
import 'package:intl/intl.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎯 أزلنا الـ BlocProvider من هنا لتنظيف الشاشة
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F24),
      appBar: AppBar(
        title: const Text('مواقيت الصلاة', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<PrayerCubit, PrayerState>(
        builder: (context, state) {
          if (state is PrayerLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          } else if (state is PrayerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(state.message, style: const TextStyle(color: Colors.redAccent, fontSize: 18), textAlign: TextAlign.center),
              ),
            );
          } else if (state is PrayerLoaded) {
            final times = state.prayerTimes;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildPrayerCard('الفجر', times.fajr),
                _buildPrayerCard('الظهر', times.dhuhr),
                _buildPrayerCard('العصر', times.asr),
                _buildPrayerCard('المغرب', times.maghrib),
                _buildPrayerCard('العشاء', times.isha),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPrayerCard(String prayerName, DateTime time) {
    String formattedTime = DateFormat('hh:mm a', 'ar').format(time);
    return Card(
      color: const Color(0xFF1C2641),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(prayerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(formattedTime, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}