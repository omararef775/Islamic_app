import 'dart:math' as math; // 🎯 أضفنا مكتبة الرياضيات لحساب زوايا الدوران
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart'; // 🎯 أضفنا الحزمة لقراءة المجرى (Stream)
import '../manager/qiblah_cubit.dart';
import '../manager/qiblah_state.dart';
import '../../../../core/theme/app_colors.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  
  @override
  void initState() {
    super.initState();
    context.read<QiblaCubit>().checkPermissionsAndInitialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, 
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة', 
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          if (state is QiblaLoading || state is QiblaInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } 
          else if (state is QiblaError) {
            return Center(
              child: Text(
                state.message, 
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          } 
          else if (state is QiblaReady) {
            // 🎯 هنا يبدأ السحر الهندسي: فتح مجرى البيانات المباشر
            return StreamBuilder<QiblahDirection>(
              stream: FlutterQiblah.qiblahStream,
              builder: (context, snapshot) {
                // حالة انتظار أول قراءة من المستشعر
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                // استخراج كائن البيانات الذي يحتوي على زوايا الهاتف
                final qiblahDirection = snapshot.data;
                if (qiblahDirection == null) {
                  return const Center(
                    child: Text(
                      'جاري معايرة المستشعر...', 
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }

                final northAngle = (qiblahDirection.direction * (math.pi / 180) * -1);
                final qiblaAngle = (qiblahDirection.qiblah * (math.pi / 180) * -1);
                
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🖼️ الطبقة السفلية: إطار البوصلة (يشير للشمال)
                      Transform.rotate(
                        angle: northAngle,
                        child: Image.asset(
                          'assets/images/compass_frame.png', 
                          width: 300, 
                          height: 300,
                        ),
                      ),
                      // 🖼️ الطبقة العلوية: مؤشر الكعبة (يشير للقبلة)
                      Transform.rotate(
                        angle: qiblaAngle,
                        child: Image.asset(
                          'assets/images/qibla_pointer.png', 
                          width: 300, 
                          height: 300,
                        ),
                      ),
                    ],
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
}