import '../../domain/ayah_model.dart';

abstract class QuranState {}

class QuranInitial extends QuranState {}

class QuranLoading extends QuranState {}

class QuranLoaded extends QuranState {
  final List<AyahModel> verses;
  final int currentPage;

  QuranLoaded({required this.verses, required this.currentPage});
}

class QuranError extends QuranState {
  final String message;
  QuranError(this.message);
}