import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import 'notification_model.dart';

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  /// Returns (notifications, unreadCount)
  Future<(List<NotificationModel>, int)> getNotifications() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.notifications);
      final List<dynamic> jsonList = response.data['notifications'] ?? [];
      final int unreadCount = response.data['unread_count'] ?? 0;
      final notifications = jsonList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      return (notifications, unreadCount);
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          e.response?.data?['error']?['message'] ??
              'Failed to load notifications',
        );
      }
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await apiClient.dio.patch(ApiConstants.notificationsReadAll);
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          e.response?.data?['error']?['message'] ??
              'Failed to mark notifications as read',
        );
      }
      throw Exception('Failed to mark notifications as read: $e');
    }
  }

  Future<void> markOneRead(String notificationId) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.notifications}/$notificationId/read',
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          e.response?.data?['error']?['message'] ??
              'Failed to mark notification as read',
        );
      }
      throw Exception('Failed to mark notification: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final (_, count) = await getNotifications();
      return count;
    } catch (_) {
      return 0;
    }
  }
}
