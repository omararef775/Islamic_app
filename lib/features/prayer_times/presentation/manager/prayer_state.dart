import 'package:equatable/equatable.dart';
import 'package:adhan/adhan.dart';

abstract class PrayerState extends Equatable {
  const PrayerState();

  @override
  List<Object> get props => [];
}

class PrayerLoading extends PrayerState {}

class PrayerLoaded extends PrayerState {
  final PrayerTimes prayerTimes;

  const PrayerLoaded(this.prayerTimes);

  @override
  List<Object> get props => [prayerTimes];
}

class PrayerError extends PrayerState {
  final String message;
  final bool isPermissionError; // 🎯 للتحكم بظهور زر "فتح الإعدادات" في الواجهة

  const PrayerError(this.message, {this.isPermissionError = false});

  @override
  List<Object> get props => [message, isPermissionError];
}