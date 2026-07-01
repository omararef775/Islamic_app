import 'package:equatable/equatable.dart';
import '../../domain/adhkar_model.dart';

abstract class AdhkarState extends Equatable {
  const AdhkarState();

  @override
  List<Object?> get props => [];
}

class AdhkarInitial extends AdhkarState {}

class AdhkarLoading extends AdhkarState {}

class AdhkarLoaded extends AdhkarState {
  final List<AdhkarModel> adhkar;
  final String currentCategory;

  const AdhkarLoaded(this.adhkar, this.currentCategory);

  @override
  List<Object?> get props => [adhkar, currentCategory];
}

class AdhkarError extends AdhkarState {
  final String message;

  const AdhkarError(this.message);

  @override
  List<Object?> get props => [message];
}