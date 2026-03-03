import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants.dart';
import 'bloc/notification_bloc.dart';
import 'bloc/notification_event.dart';
import 'bloc/notification_state.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            final unread = state is NotificationLoaded ? state.unreadCount : 0;
            return Row(
              children: [
                const Text('Notifications'),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationBloc>().add(
                MarkAllNotificationsAsRead(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationBloc>().add(
                      LoadNotifications(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is NotificationLoaded) {
            final notifications = state.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications());
              },
              child: ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: AppColors.success,
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      context.read<NotificationBloc>().add(
                        MarkOneNotificationAsRead(notification.id),
                      );
                    },
                    child: GestureDetector(
                      onTap: notification.isRead
                          ? null
                          : () {
                              context.read<NotificationBloc>().add(
                                MarkOneNotificationAsRead(notification.id),
                              );
                            },
                      child: Container(
                        color: notification.isRead
                            ? Colors.transparent
                            : AppColors.primaryLight,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead
                                ? AppColors.background
                                : AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.notifications,
                              color: notification.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                          title: Text(
                            notification.message,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              timeago.format(notification.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          trailing: notification.isRead
                              ? null
                              : const Icon(
                                  Icons.circle,
                                  color: AppColors.primary,
                                  size: 10,
                                ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
