import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit() : super(QuranInitial());

  // مفتاح التخزين في الذاكرة
  static const String _bookmarkKey = 'last_read_page';

  // 1. دالة جلب آخر صفحة مقروءة (تعمل عند فتح شاشة القرآن)
  Future<void> loadBookmark() async {
    emit(QuranLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      // إذا لم يجد صفحة محفوظة (أول مرة يفتح التطبيق)، سيبدأ من الصفحة 1 (الفاتحة)
      final lastPage = prefs.getInt(_bookmarkKey) ?? 1; 
      
      emit(QuranLoaded(lastReadPage: lastPage));
    } catch (e) {
      // في حال حدوث أي خطأ في الذاكرة، نفتح الصفحة الأولى كإجراء احتياطي
      emit(QuranLoaded(lastReadPage: 1));
    }
  }

  // 2. دالة حفظ الصفحة (تعمل كلما قلب المستخدم صفحة جديدة)
  Future<void> saveBookmark(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bookmarkKey, pageNumber);
    
    // نُحدث الحالة بالرقم الجديد لكي تتحدث الواجهة إن لزم الأمر
    emit(QuranLoaded(lastReadPage: pageNumber));
  }
}