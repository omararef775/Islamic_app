import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// استدعاء ملفات الـ Cubit التي صنعناها
import 'manager/prayer_cubit.dart';
import 'manager/prayer_state.dart';
import 'package:intl/intl.dart';

// 1. الشاشة أصبحت StatelessWidget لأنها لم تعد تدير أي حالة بنفسها!
class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. BlocProvider: هو "الحاضنة" التي توفر الـ Cubit للشاشة
    return BlocProvider(
      // 3. create: هنا نولد الـ Cubit، وعلامتي (..) تعني "قم بإنشائه وشغل دالة الجلب فوراً"
      create: (context) => PrayerCubit()..fetchPrayerTimesData(),
      
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F24), // لون الخلفية الروحاني
        appBar: AppBar(
          title: const Text('مواقيت الصلاة', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        
        // 4. BlocBuilder: هذا هو "المستمع" الذكي الذي يراقب الـ Cubit
        body: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, state) {
            
            // 5. الحالة الأولى: إذا كان الـ Cubit في حالة "تحميل"
            if (state is PrayerLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              );
            } 
            
            // 6. الحالة الثانية: إذا واجه الـ Cubit "خطأ" (مثل إغلاق الـ GPS)
            else if (state is PrayerError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    state.message, // الرسالة التي أرسلناها من الـ Cubit
                    style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } 
            
            // 7. الحالة الثالثة: إذا "نجح" الـ Cubit وجلب الأوقات
            else if (state is PrayerLoaded) {
              final times = state.prayerTimes; // نستخرج الأوقات من الحالة
              
              // 8. نرسم الواجهة بكل بساطة ونمرر لها الأوقات
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
            
            // 9. حالة احتياطية (لن يصل إليها الكود عادةً)
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // 10. دالة مساعدة لرسم البطاقات (فصلناها ليبقى كود الـ build نظيفاً)
  Widget _buildPrayerCard(String prayerName, DateTime time) {
    // 💡 السطر السحري: استخدام DateFormat لتحويل الوقت لنظام 12 ساعة مع AM/PM
    // 'hh:mm a' تعني: ساعات (12)، دقائق، ثم رمز (صباحاً/مساءً)
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
            Text(
              prayerName, 
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
            ),
            Text(
              formattedTime, 
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}