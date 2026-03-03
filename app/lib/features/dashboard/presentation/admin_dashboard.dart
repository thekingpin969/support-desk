import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/admin_bloc.dart';
import '../../../core/di.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/logout_dialog.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminBloc>()..add(LoadAnalytics()),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => showLogoutDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            AppSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<AdminBloc>().add(LoadAnalytics()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
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
                  const Text(
                    'System Overview (Today)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricCard(
                        'Total Tickets',
                        stats['total_today'].toString(),
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'Pending Review',
                        stats['pending_review'].toString(),
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricCard(
                        'Escalated',
                        stats['escalated'].toString(),
                        Colors.red,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'Avg Resolution',
                        '${stats['avg_resolution_hours'] ?? '0.0'}h',
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Ticket Queues',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAdminActionCard(
                    context,
                    'Pending Review',
                    Icons.rate_review,
                    'Tickets awaiting your approval',
                    () => context.push('/admin/tickets?filter=pending_review'),
                  ),
                  _buildAdminActionCard(
                    context,
                    'Escalated Tickets',
                    Icons.warning_amber,
                    'SLA breached — action required',
                    () => context.push('/admin/tickets?filter=escalated'),
                  ),
                  _buildAdminActionCard(
                    context,
                    'All Tickets',
                    Icons.list_alt,
                    'Filterable list of every ticket',
                    () => context.push('/admin/tickets'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAdminActionCard(
                    context,
                    'Employee Management',
                    Icons.people,
                    'Manage roles and capacity',
                    () => context.push('/admin/employees'),
                  ),
                  _buildAdminActionCard(
                    context,
                    'System Analytics',
                    Icons.analytics,
                    'View ticket resolution metrics',
                    () => context.push('/admin/analytics'),
                  ),
                  _buildAdminActionCard(
                    context,
                    'SLA Configuration',
                    Icons.settings,
                    'Adjust SLA timers and warnings',
                    () => context.push('/admin/sla'),
                  ),
                  _buildAdminActionCard(
                    context,
                    'Categories Configuration',
                    Icons.category,
                    'Manage ticket categories',
                    () => context.push('/admin/categories'),
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

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
