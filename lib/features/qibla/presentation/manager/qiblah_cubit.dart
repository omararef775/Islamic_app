import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart'; // ضروري لجلب LocationPermission
import 'qiblah_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit() : super(QiblaInitial());

  // 🎯 دالة التهيئة (البواب الأمني للبوصلة)
  Future<void> checkPermissionsAndInitialize() async {
    emit(QiblaLoading());
    try {
      // 1. فحص العتاد: هل الهاتف يحتوي أصلاً على مستشعر مغناطيسي؟
      if (Platform.isAndroid) {
        final bool hasSensor = await FlutterQiblah.androidDeviceSensorSupport() ?? true;
        if (!hasSensor) {
          emit(const QiblaNoSensor('عذراً، هاتفك لا يحتوي على مستشعر البوصلة (Magnetometer).'));
          return;
        }
      }

      // 2. فحص الصلاحيات و الـ GPS بذكاء (حل العيب المنطقي في التقرير)
      final locationStatus = await FlutterQiblah.checkLocationStatus();
      
      // أ. إذا كان زر الـ GPS في الهاتف مغلقاً
      if (!locationStatus.enabled) {
        emit(const QiblaError(
          'الرجاء تفعيل خدمة الموقع (GPS) من ستارة إعدادات الهاتف لتشغيل البوصلة.',
          isPermissionError: false, // لا نحتاج لفتح إعدادات التطبيق هنا
        ));
        return;
      }
      
      // ب. إذا كانت صلاحية الموقع مسحوبة أو مرفوضة من المستخدم
      if (locationStatus.status == LocationPermission.denied || 
          locationStatus.status == LocationPermission.deniedForever) {
        emit(const QiblaError(
          'تطبيقك يحتاج لصلاحية الموقع لتحديد اتجاه القبلة بدقة. الرجاء الموافقة عليها.', 
          isPermissionError: true, // 🎯 هذه ستفعل زر "فتح الإعدادات" في الشاشة
        ));
        return;
      }

      // 3. الخط الأخير: كل شيء سليم، نعطي الضوء الأخضر للشاشة لتبدأ عرض البوصلة
      emit(QiblaReady());
      
    } catch (e) {
      emit(QiblaError('حدث خطأ أثناء تهيئة البوصلة: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    // 🎯 الحل الجذري لثغرة (التجمد عند الفتح للمرة الثانية)
    // هذه الدالة تمسح مجرى البيانات من ذاكرة المكتبة لتبدأ نظيفة في كل مرة تفتح فيها الشاشة
    FlutterQiblah().dispose();
    return super.close();
  }
}