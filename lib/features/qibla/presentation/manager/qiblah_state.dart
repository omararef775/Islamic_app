import 'package:equatable/equatable.dart';

abstract class QiblaState extends Equatable {
  const QiblaState();
  @override
  List<Object?> get props => [];
}

class QiblaInitial extends QiblaState {}

class QiblaLoading extends QiblaState {}

// الواجهة بمجرد أن تتلقى هذه الحالة ستفتح الـ StreamBuilder الخاص بها
class QiblaReady extends QiblaState {}

class QiblaNoSensor extends QiblaState {
  final String message;
  const QiblaNoSensor(this.message);

  @override
  List<Object?> get props => [message];
}

class QiblaError extends QiblaState {
  final String message;
  // 🎯 المتغير الذي سيخبر الشاشة متى تظهر زر "الإعدادات"
  final bool isPermissionError; 

  const QiblaError(this.message, {this.isPermissionError = false});

  @override
  List<Object?> get props => [message, isPermissionError];
}