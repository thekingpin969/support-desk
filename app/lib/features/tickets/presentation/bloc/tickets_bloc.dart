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
  final List<String>? imagePaths;

  CreateTicket(
    this.title,
    this.description,
    this.categoryId,
    this.priority, {
    this.imagePaths,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    categoryId,
    priority,
    imagePaths,
  ];
}

class CreateResponse extends TicketsEvent {
  final String ticketId;
  final String content;
  final List<String>? imagePaths;
  final bool saveDraft;

  CreateResponse({
    required this.ticketId,
    required this.content,
    this.imagePaths,
    this.saveDraft = false,
  });

  @override
  List<Object?> get props => [ticketId, content, imagePaths, saveDraft];
}

class ApproveResponse extends TicketsEvent {
  final String ticketId;
  final String responseId;

  ApproveResponse(this.ticketId, this.responseId);

  @override
  List<Object?> get props => [ticketId, responseId];
}

class RejectResponse extends TicketsEvent {
  final String ticketId;
  final String responseId;
  final String? feedback;

  RejectResponse(this.ticketId, this.responseId, {this.feedback});

  @override
  List<Object?> get props => [ticketId, responseId, feedback];
}

class ReassignTicket extends TicketsEvent {
  final String ticketId;
  final String employeeId;

  ReassignTicket(this.ticketId, this.employeeId);

  @override
  List<Object?> get props => [ticketId, employeeId];
}

class EscalateTicket extends TicketsEvent {
  final String ticketId;

  EscalateTicket(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class RateTicket extends TicketsEvent {
  final String ticketId;
  final int rating;
  final String comment;

  RateTicket(this.ticketId, this.rating, this.comment);

  @override
  List<Object?> get props => [ticketId, rating, comment];
}

class ReopenTicket extends TicketsEvent {
  final String ticketId;

  ReopenTicket(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
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
    on<CreateResponse>(_onCreateResponse);
    on<ApproveResponse>(_onApproveResponse);
    on<RejectResponse>(_onRejectResponse);
    on<ReassignTicket>(_onReassignTicket);
    on<EscalateTicket>(_onEscalateTicket);
    on<RateTicket>(_onRateTicket);
    on<ReopenTicket>(_onReopenTicket);
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
      List<Map<String, String>> uploadedImages = [];
      if (event.imagePaths != null && event.imagePaths!.isNotEmpty) {
        final uploadFutures = event.imagePaths!.map(
          (path) => repository.uploadImageObj(path),
        );
        uploadedImages = await Future.wait(uploadFutures);
      }

      await repository.createTicket(
        event.title,
        event.description,
        event.categoryId,
        event.priority,
        images: uploadedImages.isNotEmpty ? uploadedImages : null,
      );

      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets)); // Revert
      }
    }
  }

  Future<void> _onCreateResponse(
    CreateResponse event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      // createResponse now handles image uploads internally with correct context
      await repository.createResponse(
        event.ticketId,
        event.content,
        imagePaths: event.imagePaths,
        status: event.saveDraft ? 'draft' : 'pending_review',
      );
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }

  Future<void> _onApproveResponse(
    ApproveResponse event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      await repository.approveResponse(event.ticketId, event.responseId);
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }

  Future<void> _onRejectResponse(
    RejectResponse event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      await repository.rejectResponse(
        event.ticketId,
        event.responseId,
        feedback: event.feedback,
      );
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }

  Future<void> _onReassignTicket(
    ReassignTicket event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      await repository.reassignTicket(event.ticketId, event.employeeId);
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }

  Future<void> _onEscalateTicket(
    EscalateTicket event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      await repository.escalateTicket(event.ticketId);
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }

  Future<void> _onRateTicket(
    RateTicket event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      await repository.rateTicket(event.ticketId, event.rating, event.comment);
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }

  Future<void> _onReopenTicket(
    ReopenTicket event,
    Emitter<TicketsState> emit,
  ) async {
    final currentState = state;
    emit(TicketsLoading());
    try {
      await repository.reopenTicket(event.ticketId);
      add(LoadTickets());
    } catch (e) {
      emit(TicketsError(e.toString()));
      if (currentState is TicketsLoaded) {
        emit(TicketsLoaded(currentState.tickets));
      }
    }
  }
}
