import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/quran_db_helper.dart';
import '../../domain/ayah_model.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit() : super(QuranInitial());

  static const String _bookmarkKey = 'last_read_page';

  // 1. جلب صفحة معينة من قاعدة البيانات
  Future<void> loadPage(int pageNumber) async {
    emit(QuranLoading());
    try {
      final rawVerses = await QuranDatabaseHelper.instance.getVersesByPage(
        pageNumber,
      );
      final List<AyahModel> verses = rawVerses
          .map((v) => AyahModel.fromMap(v))
          .toList();

      // حفظ التقدم بشكل أولي عند فتح الصفحة
      await saveBookmark(pageNumber);

      emit(QuranLoaded(verses: verses, currentPage: pageNumber));
    } catch (e) {
      emit(QuranError('حدث خطأ أثناء تحميل الصفحة: $e'));
    }
  }

  // 2. دالة بدء التطبيق (تجلب آخر صفحة وقف عندها المستخدم)
  Future<void> loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPage = prefs.getInt(_bookmarkKey) ?? 1; // الفاتحة كافتراضي
    await loadPage(lastPage);
  }

  // 🎯 3. الدالة التي كانت ناقصة: حفظ رقم الصفحة في الخلفية عند التمرير
  Future<void> saveBookmark(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bookmarkKey, pageNumber);
  }
}
