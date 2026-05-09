import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'qiblah_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit() : super(QiblaInitial());

  // المنطق الصحيح: فحص وطلب صلاحيات الموقع التي تعتمد عليها البوصلة
  Future<void> checkPermissionsAndInitialize() async {
    emit(QiblaLoading());
    try {
      // هذه الدالة رسمية في الحزمة وتقوم بتجهيز الموقع والبوصلة معاً
      await FlutterQiblah.requestPermissions();
      
      // بمجرد الانتهاء، نطلق حالة الاستعداد لنبدأ برسم الواجهة والصور
      emit(QiblaReady());
      
    } catch (e) {
      emit(QiblaError('حدث خطأ أثناء تهيئة البوصلة: ${e.toString()}'));
    }
  }
}