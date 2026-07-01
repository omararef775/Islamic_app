import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';

import '../manager/qiblah_cubit.dart';
import '../manager/qiblah_state.dart';
import '../../../../core/theme/app_colors.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          
          if (state is QiblaLoading || state is QiblaInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } 
          
          else if (state is QiblaNoSensor) {
             return _buildMessageCenter(
               context: context, 
               icon: Icons.compass_calibration_outlined, 
               message: state.message,
             );
          } 
          
          else if (state is QiblaError) {
            // 🎯 إضافة زر فتح الإعدادات في حال كان الخطأ بسبب الصلاحيات أو الـ GPS
            return _buildMessageCenter(
               context: context, 
               icon: Icons.location_off_rounded, 
               message: state.message,
               showSettingsButton: true,
            );
          } 
          
          else if (state is QiblaReady) {
            // 🎯 استخدام StreamBuilder هنا هو الأفضل معمارياً لمنع الـ Cubit من الانفجار بـ 60 حالة/ثانية
            return StreamBuilder<QiblahDirection>(
              stream: FlutterQiblah.qiblahStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final qiblahDirection = snapshot.data;
                if (qiblahDirection == null || qiblahDirection.direction.isNaN) {
                  return _buildMessageCenter(
                    context: context,
                    icon: Icons.explore_off, 
                    message: 'جاري معايرة المستشعر... حرك هاتفك على شكل رقم 8 (∞)'
                  );
                }

                // ==============================================================
                // 🎯 الحسبة الرياضية النظيفة (بدون تراكمات ولا أنيميشن معقد)
                // ==============================================================
                
                // 1. زاوية دوران الإطار (الشمال) بالراديان
                final double compassAngle = (qiblahDirection.direction * -1) * (math.pi / 180);
                
                // 2. زاوية دوران مؤشر مكة بالراديان (المكتبة تعطينا الـ Offset جاهزاً)
                final double qiblaAngle = (qiblahDirection.offset - qiblahDirection.direction ) * (math.pi / 180);

             return Center(
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 🖼️ إطار البوصلة (الشمال المغناطيسي)
                        Transform.rotate(
                          angle: compassAngle,
                          child: Image.asset(
                            'assets/images/compass_frame.png',
                            width: 280,
                            height: 280,
                            fit: BoxFit.contain,
                          ),
                        ),
                        
                        // 🖼️ مؤشر القبلة (نحو مكة المكرمة)
                        Transform.rotate(
                          angle: qiblaAngle,
                          child: Image.asset(
                            'assets/images/qibla_pointer.png',
                            width: 280,
                            height: 280,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // 🎯 واجهة الرسائل المحسنة (تدعم زر الإعدادات التفاعلي)
  Widget _buildMessageCenter({
    required BuildContext context,
    required IconData icon, 
    required String message,
    bool showSettingsButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: Colors.grey.withAlpha(150)),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (showSettingsButton) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await openAppSettings();
                  // 🎯 بعد العودة من الإعدادات، نوقظ العقل المدبر ليفحص مجدداً
                  if (context.mounted) {
                    context.read<QiblaCubit>().checkPermissionsAndInitialize();
                  }
                },
                icon: const Icon(Icons.settings, color: AppColors.background),
                label: const Text(
                  'فتح الإعدادات',
                  style: TextStyle(fontSize: 16, color: AppColors.background, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}