import '../../domain/adhkar_model.dart';

abstract class AdhkarState {}

// 1. الحالة الابتدائية (عند فتح التطبيق)
class AdhkarInitial extends AdhkarState {}

// 2. حالة التحميل (دوران مؤشر التحميل بينما نجلب البيانات من SQLite)
class AdhkarLoading extends AdhkarState {}

// 3. حالة النجاح (البيانات جاهزة للعرض)
class AdhkarLoaded extends AdhkarState {
  final List<AdhkarModel> adhkar;
  final String currentCategory; // لمعرفة هل نحن في الصباح أم المساء أم المخصص

  AdhkarLoaded(this.adhkar, this.currentCategory);
}

// 4. حالة الخطأ (في حال فشل قاعدة البيانات)
class AdhkarError extends AdhkarState {
  final String message;

  AdhkarError(this.message);
}