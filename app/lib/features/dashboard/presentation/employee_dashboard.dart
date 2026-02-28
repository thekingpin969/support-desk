import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../tickets/presentation/bloc/tickets_bloc.dart';
import '../../../core/di.dart';
import 'package:intl/intl.dart';
import '../../tickets/domain/ticket_model.dart';
import 'package:go_router/go_router.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TicketsBloc>()..add(LoadTickets()),
      child: const _EmployeeDashboardView(),
    );
  }
}

class _EmployeeDashboardView extends StatelessWidget {
  const _EmployeeDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<TicketsBloc, TicketsState>(
                builder: (context, state) {
                  if (state is TicketsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TicketsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is TicketsLoaded) {
                    final tickets = state.tickets;
                    final active = tickets
                        .where(
                          (t) => t.status != 'resolved' && t.status != 'closed',
                        )
                        .toList();

                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<TicketsBloc>().add(LoadTickets()),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: active.length,
                        itemBuilder: (context, index) {
                          return _buildTicketCard(context, active[index]);
                        },
                      ),
                    );
                  }
                  return const Center(child: Text('No Data'));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      user?.fullName.substring(0, 1) ?? 'E',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning, ${user?.fullName.split(' ').first ?? 'Employee'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Support Specialist L2',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket) {
    Color indicator;
    switch (ticket.priority) {
      case 'CRITICAL':
        indicator = Colors.red;
        break;
      case 'HIGH':
        indicator = Colors.orange;
        break;
      case 'MEDIUM':
        indicator = Colors.blue;
        break;
      default:
        indicator = Colors.grey;
    }

    return GestureDetector(
      onTap: () => context.push('/ticket-detail', extra: ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: indicator, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: indicator.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.priority,
                    style: TextStyle(
                      color: indicator,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color:
                            ticket.slaDeadline != null &&
                                ticket.slaDeadline!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.slaDeadline != null
                            ? DateFormat(
                                'MM/dd HH:mm',
                              ).format(ticket.slaDeadline!)
                            : 'No SLA',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color:
                              ticket.slaDeadline != null &&
                                  ticket.slaDeadline!.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Status: ${ticket.status}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.blue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }
}
