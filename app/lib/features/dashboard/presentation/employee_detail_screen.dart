import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../data/admin_repository.dart';
import '../../tickets/domain/ticket_model.dart';

/// Admin drill-down screen showing a single employee's details and ticket list.
class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  List<TicketModel> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final raw = await sl<AdminRepository>().fetchEmployeeTickets(
        widget.employee['id'],
      );
      setState(() {
        _tickets = raw.map((e) => TicketModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final profile = emp['employee_profile'] ?? {};
    final openCount = profile['open_ticket_count'] ?? 0;
    final maxCap = profile['max_capacity'] ?? 10;
    final dept = profile['department'] ?? 'N/A';
    final isActive = emp['is_active'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(emp['full_name'] ?? 'Employee')),
      body: Column(
        children: [
          // ── Employee summary card ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (emp['full_name'] ?? 'E')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp['full_name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            emp['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withAlpha(25)
                            : AppColors.danger.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Department', dept),
                    _statItem('Open', '$openCount'),
                    _statItem('Capacity', '$maxCap'),
                    _statItem(
                      'Usage',
                      '${maxCap > 0 ? ((openCount / maxCap) * 100).round() : 0}%',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Ticket list header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assigned Tickets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_tickets.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Ticket list ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                ? const Center(
                    child: Text(
                      'No tickets assigned to this employee.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTickets,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        return _buildTicketCard(context, t);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket) {
    Color statusColor;
    switch (ticket.status) {
      case 'pending_review':
        statusColor = Colors.orange;
        break;
      case 'escalated':
        statusColor = Colors.red;
        break;
      case 'resolved':
        statusColor = AppColors.success;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => context.push('/ticket-detail', extra: ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.ticketNumber,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ticket.status.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
