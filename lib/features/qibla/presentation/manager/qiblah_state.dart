abstract class QiblaState {}

class QiblaInitial extends QiblaState {}

class QiblaLoading extends QiblaState {}

// عندما يتم التأكد من الصلاحيات والبوصلة جاهزة للعمل
class QiblaReady extends QiblaState {}

class QiblaError extends QiblaState {
  final String message;
  QiblaError(this.message);
}