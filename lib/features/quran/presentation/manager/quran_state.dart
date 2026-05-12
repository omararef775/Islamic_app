abstract class QuranState {}

// 1. الحالة الابتدائية
class QuranInitial extends QuranState {}

// 2. حالة جلب العلامة المرجعية من الذاكرة
class QuranLoading extends QuranState {}

// 3. حالة النجاح (تحمل معها رقم آخر صفحة قرأها المستخدم)
class QuranLoaded extends QuranState {
  final int lastReadPage;

  QuranLoaded({required this.lastReadPage});
}