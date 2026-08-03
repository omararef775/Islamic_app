import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import '../../domain/adhkar_model.dart';
import 'adhkar_state.dart';

class AdhkarCubit extends Cubit<AdhkarState> {
  AdhkarCubit() : super(AdhkarInitial());

  final dbHelper = DatabaseHelper.instance;

  Future<void> loadAdhkar(String category) async {
    emit(AdhkarLoading());
    try {
      final List<Map<String, dynamic>> maps = await dbHelper.getAdhkarByCategory(category);
      final List<AdhkarModel> adhkarList = maps.map((map) => AdhkarModel.fromMap(map)).toList();
      emit(AdhkarLoaded(adhkarList, category));
    } catch (e) {
      emit(AdhkarError("حدث خطأ أثناء جلب الأذكار: ${e.toString()}"));
    }
  }

  // 🎯 هندسة متقدمة: التحديث البصري الفوري مع الحماية الخلفية
  Future<void> decrementDhikr(AdhkarModel dhikr, String currentCategory) async {
    if (state is AdhkarLoaded) {
      final currentState = state as AdhkarLoaded;
      
      if (dhikr.currentCount > 0 && dhikr.id != null) {
        final newCount = dhikr.currentCount - 1;

        // 1. التحديث البصري السريع (Optimistic UI Update)
        final updatedList = currentState.adhkar.map((item) {
          return item.id == dhikr.id ? item.copyWith(currentCount: newCount) : item;
        }).toList();
        
        emit(AdhkarLoaded(updatedList, currentCategory));

        // 2. تحديث قاعدة البيانات بشكل آمن ومحمي
        try {
          await dbHelper.updateCurrentCount(dhikr.id!, newCount);
        } catch (e) {
          // 3. استرجاع الحالة السابقة (Rollback) إذا فشل الحفظ في الـ Database
          emit(AdhkarLoaded(currentState.adhkar, currentCategory));
          emit(const AdhkarError("عذراً، فشل مزامنة العداد مع قاعدة البيانات."));
        }
      }
    }
  }

  Future<void> addCustomDhikr(String text, int targetCount, String category) async {
    // 🎯 يدعم الإضافة لأي قسم: morning / evening / custom
    final newDhikr = AdhkarModel(
      text: text,
      category: category,
      targetCount: targetCount,
      currentCount: targetCount,
      isCustom: true,
    );

    try {
      await dbHelper.insertDhikr(newDhikr.toMap());
      // ⬅️ إعادة تحميل نفس القسم الذي أضفنا إليه الذكر
      await loadAdhkar(category);
    } catch (e) {
      emit(AdhkarError("فشل في إضافة الذكر: ${e.toString()}"));
    }
  }

  Future<void> updateCustomDhikr(int id, String newText, int newTarget, String category) async {
    await dbHelper.updateCustomDhikr(id, newText, newTarget);
    // ⬅️ إعادة تحميل القسم الصحيح بعد التعديل
    await loadAdhkar(category);
  }

  Future<void> deleteCustomDhikr(int id, String category) async {
    await dbHelper.deleteDhikr(id);
    // ⬅️ إعادة تحميل القسم الصحيح بعد الحذف
    await loadAdhkar(category);
  }
}