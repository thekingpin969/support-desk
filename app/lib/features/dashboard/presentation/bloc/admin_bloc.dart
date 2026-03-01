import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/admin_repository.dart';

// EVENTS
abstract class AdminEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AdminEvent {}

// STATES
abstract class AdminState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final Map<String, dynamic> analytics;

  AdminLoaded(this.analytics);

  @override
  List<Object?> get props => [analytics];
}

class AdminError extends AdminState {
  final String message;

  AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  AdminBloc({required this.repository}) : super(AdminInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = await repository.fetchAnalytics();
      emit(AdminLoaded(data));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
