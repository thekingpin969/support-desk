import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminActionCard(
            context,
            'Employee Management',
            Icons.people,
            'Manage roles and capacity',
            () {},
          ),
          _buildAdminActionCard(
            context,
            'System Analytics',
            Icons.analytics,
            'View ticket resolution metrics',
            () {},
          ),
          _buildAdminActionCard(
            context,
            'SLA Configuration',
            Icons.settings,
            'Adjust SLA timers and warnings',
            () {},
          ),
          _buildAdminActionCard(
            context,
            'Escalations & Reviews',
            Icons.campaign,
            'Requires admin attention',
            () {},
          ),
        ],
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
