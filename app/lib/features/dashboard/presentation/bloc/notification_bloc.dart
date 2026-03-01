import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc({required this.repository}) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<MarkOneNotificationAsRead>(_onMarkOneNotificationAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final (notifications, unreadCount) = await repository.getNotifications();
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      try {
        await repository.markAllRead();
        add(LoadNotifications());
      } catch (e) {
        emit(NotificationError(message: e.toString()));
      }
    }
  }

  Future<void> _onMarkOneNotificationAsRead(
    MarkOneNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await repository.markOneRead(event.notificationId);
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }
}
