import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import '../../domain/adhkar_model.dart';
import 'adhkar_state.dart';

class AdhkarCubit extends Cubit<AdhkarState> {
  AdhkarCubit() : super(AdhkarInitial());

  // نسخة من مدير قاعدة البيانات لنتواصل معه
  final dbHelper = DatabaseHelper.instance;

  // 1. جلب الأذكار حسب الفئة (صباح، مساء، مخصص)
  Future<void> loadAdhkar(String category) async {
    emit(AdhkarLoading()); // إخبار الشاشة بعرض مؤشر التحميل
    try {
      // جلب البيانات الخام من SQLite
      final List<Map<String, dynamic>> maps = await dbHelper.getAdhkarByCategory(category);
      
      // تحويل البيانات الخام إلى كائنات Model منظمة
      final List<AdhkarModel> adhkarList = maps.map((map) => AdhkarModel.fromMap(map)).toList();
      
      emit(AdhkarLoaded(adhkarList, category)); // إرسال البيانات الجاهزة للشاشة
    } catch (e) {
      emit(AdhkarError("حدث خطأ أثناء جلب الأذكار: ${e.toString()}"));
    }
  }

  // التعديل الجديد لدالة إنقاص العداد (سلسة وبدون إعادة بناء القائمة بالكامل)
  Future<void> decrementDhikr(AdhkarModel dhikr, String currentCategory) async {
    // 1. التأكد من أن الحالة الحالية هي AdhkarLoaded لكي نتمكن من تعديل القائمة
    if (state is AdhkarLoaded) {
      final currentState = state as AdhkarLoaded;
      
      if (dhikr.currentCount > 0) {
        final newCount = dhikr.currentCount - 1;

        // 2. تحديث قاعدة البيانات في الخلفية (بدون انتظار await لسرعة الاستجابة البصرية)
        dbHelper.updateCurrentCount(dhikr.id!, newCount);

        // 3. السحر هنا: تحديث القائمة الموجودة في الذاكرة فقط
        final updatedList = currentState.adhkar.map((item) {
          return item.id == dhikr.id 
              ? item.copyWith(currentCount: newCount) // نحدث فقط الذكر الذي ضغطنا عليه
              : item; // باقي الأذكار تبقى كما هي
        }).toList();

        // 4. بث الحالة الجديدة فوراً بنفس القائمة المحدثة
        // فلاتر سيقوم بتحديث "الرقم" فقط داخل البطاقة دون إعادة بناء الـ ListView بالكامل
        emit(AdhkarLoaded(updatedList, currentCategory));
      }
    }
  }

  // 3. إضافة ذكر مخصص جديد
  Future<void> addCustomDhikr(String text, int targetCount) async {
    final newDhikr = {
      'text': text,
      'category': 'custom',
      'target_count': targetCount,
      'current_count': targetCount,
      'is_custom': 1, // 1 يعني مخصص
    };
    
    await dbHelper.insertDhikr(newDhikr);
    await loadAdhkar('custom'); // تحديث شاشة الأذكار المخصصة فوراً
  }

  // 4. تعديل ذكر مخصص
  Future<void> updateCustomDhikr(int id, String newText, int newTarget) async {
    await dbHelper.updateCustomDhikr(id, newText, newTarget);
    await loadAdhkar('custom'); // تحديث الشاشة
  }

  // 5. حذف ذكر مخصص
  Future<void> deleteCustomDhikr(int id) async {
    await dbHelper.deleteDhikr(id);
    await loadAdhkar('custom'); // تحديث الشاشة
  }
}