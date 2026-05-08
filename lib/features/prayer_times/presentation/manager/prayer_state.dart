import 'package:equatable/equatable.dart';
import 'package:adhan/adhan.dart'; // نحتاجها للتعرف على كائن PrayerTimes

// 1. الفئة الأم (القالب الأساسي للحالة)
abstract class PrayerState extends Equatable {
  const PrayerState();

  // هذا السطر يخص مكتبة equatable لتعرف كيف تقارن الحالات ببعضها
  @override
  List<Object> get props => [];
}

// 2. حالة "جاري التحميل" (عندما ندور الدائرة بانتظار الـ GPS)
class PrayerLoading extends PrayerState {}

// 3. حالة "النجاح" (عندما نحصل على الأوقات)
class PrayerLoaded extends PrayerState {
  final PrayerTimes prayerTimes; // هذه الحالة تحمل بداخلها أوقات الصلاة لتعطيها للشاشة

  const PrayerLoaded(this.prayerTimes);

  @override
  List<Object> get props => [prayerTimes]; // نخبر equatable أن يقارن بناءً على الأوقات
}

// 4. حالة "الخطأ" (عندما يفشل الـ GPS أو يحدث خطأ)
class PrayerError extends PrayerState {
  final String message; // هذه الحالة تحمل بداخلها رسالة الخطأ لتعرضها للمستخدم

  const PrayerError(this.message);

  @override
  List<Object> get props => [message];
}