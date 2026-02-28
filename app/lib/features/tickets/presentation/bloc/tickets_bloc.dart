import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/ticket_repository.dart';
import '../../domain/ticket_model.dart';

// EVENTS
abstract class TicketsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTickets extends TicketsEvent {}

class CreateTicket extends TicketsEvent {
  final String title;
  final String description;
  final String categoryId;
  final String priority;
  final String? imagePath;

  CreateTicket(
    this.title,
    this.description,
    this.categoryId,
    this.priority, {
    this.imagePath,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    categoryId,
    priority,
    imagePath,
  ];
}

// STATES
abstract class TicketsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TicketsInitial extends TicketsState {}

class TicketsLoading extends TicketsState {}

class TicketsLoaded extends TicketsState {
  final List<TicketModel> tickets;
  TicketsLoaded(this.tickets);
  @override
  List<Object?> get props => [tickets];
}

class TicketsError extends TicketsState {
  final String message;
  TicketsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  final TicketRepository repository;

  TicketsBloc({required this.repository}) : super(TicketsInitial()) {
    on<LoadTickets>(_onLoadTickets);
    on<CreateTicket>(_onCreateTicket);
  }

  Future<void> _onLoadTickets(
    LoadTickets event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());
    try {
      final tickets = await repository.fetchTickets();
      emit(TicketsLoaded(tickets));
    } catch (e) {
      emit(TicketsError(e.toString()));
    }
  }

  Future<void> _onCreateTicket(
    CreateTicket event,
    Emitter<TicketsState> emit,
  ) async {
    // Maybe we just reload after create? Or optimistically add to the list?
    // In a real app we might have a separate UI flow for creation.
    // For now we will just emit loading, tell repo to create, then load again.
    final currentState = state;
    emit(TicketsLoading());
    try {
      final ticket = await repository.createTicket(
        event.title,
        event.description,
        event.categoryId,
        event.priority,
      );

      if (event.imagePath != null) {
        await repository.uploadImage(ticket.id, event.imagePath!);
      }

      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets)); // Revert
      }
    }
  }
}
