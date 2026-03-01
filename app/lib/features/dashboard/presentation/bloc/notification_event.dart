import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class MarkOneNotificationAsRead extends NotificationEvent {
  final String notificationId;
  const MarkOneNotificationAsRead(this.notificationId);
  @override
  List<Object> get props => [notificationId];
}
