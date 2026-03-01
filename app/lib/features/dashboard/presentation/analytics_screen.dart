import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/admin_bloc.dart';
import '../../../core/di.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminBloc>()..add(LoadAnalytics()),
      child: const _AnalyticsScreenView(),
    );
  }
}

class _AnalyticsScreenView extends StatelessWidget {
  const _AnalyticsScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Analytics')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (state is AdminLoaded) {
            final stats = state.analytics;
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<AdminBloc>().add(LoadAnalytics()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatRow(
                    'Total Tickets (Today)',
                    stats['total_today'].toString(),
                    Icons.confirmation_num,
                    Colors.blue,
                  ),
                  _buildStatRow(
                    'Pending Review',
                    stats['pending_review'].toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  _buildStatRow(
                    'Escalated Tickets',
                    stats['escalated'].toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                  _buildStatRow(
                    'Avg Resolution Time (hrs)',
                    stats['avg_resolution_hours']?.toString() ?? '0.0',
                    Icons.timelapse,
                    Colors.purple,
                  ),
                  _buildStatRow(
                    'SLA Compliance',
                    '${stats['sla_compliance_pct'] ?? '100.0'}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
