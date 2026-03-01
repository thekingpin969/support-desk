import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../../tickets/domain/ticket_model.dart';

class EmployeeDashboardData {
  final Map<String, dynamic> user;
  final EmployeeMetrics metrics;
  final List<TicketModel> activeTickets;
  final List<TicketModel> closedTickets;

  const EmployeeDashboardData({
    required this.user,
    required this.metrics,
    required this.activeTickets,
    required this.closedTickets,
  });
}

class EmployeeMetrics {
  final int openTicketCount;
  final int maxCapacity;
  final int slaComplianceRate;
  final int avgResponseTimeHours;
  final int escalatedCount;
  final int warningCount;
  final int unreadNotificationCount;

  const EmployeeMetrics({
    required this.openTicketCount,
    required this.maxCapacity,
    required this.slaComplianceRate,
    required this.avgResponseTimeHours,
    required this.escalatedCount,
    required this.warningCount,
    required this.unreadNotificationCount,
  });

  factory EmployeeMetrics.fromJson(Map<String, dynamic> json) {
    return EmployeeMetrics(
      openTicketCount: json['open_ticket_count'] ?? 0,
      maxCapacity: json['max_capacity'] ?? 10,
      slaComplianceRate: json['sla_compliance_rate'] ?? 100,
      avgResponseTimeHours: json['avg_response_time_hours'] ?? 0,
      escalatedCount: json['escalated_count'] ?? 0,
      warningCount: json['warning_count'] ?? 0,
      unreadNotificationCount: json['unread_notification_count'] ?? 0,
    );
  }
}

class EmployeeRepository {
  final ApiClient apiClient;

  EmployeeRepository({required this.apiClient});

  Future<EmployeeDashboardData> fetchDashboard() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.employeeDashboard);
      final data = response.data['data'];
      final metrics = EmployeeMetrics.fromJson(data['metrics']);
      final activeTickets = (data['active_tickets'] as List)
          .map((e) => TicketModel.fromJson(e))
          .toList();
      final closedTickets = (data['closed_tickets'] as List)
          .map((e) => TicketModel.fromJson(e))
          .toList();
      return EmployeeDashboardData(
        user: data['user'],
        metrics: metrics,
        activeTickets: activeTickets,
        closedTickets: closedTickets,
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to load dashboard';
    }
  }
}
