import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../tickets/presentation/bloc/tickets_bloc.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../../core/logout_dialog.dart';
import 'package:intl/intl.dart';
import '../../tickets/domain/ticket_model.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TicketsBloc>()..add(LoadTickets()),
      child: const _ClientDashboardView(),
    );
  }
}

class _ClientDashboardView extends StatelessWidget {
  const _ClientDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    final total = tickets.length;
                    final open = tickets
                        .where(
                          (t) => t.status != 'resolved' && t.status != 'closed',
                        )
                        .length;
                    final resolved = tickets
                        .where(
                          (t) => t.status == 'resolved' || t.status == 'closed',
                        )
                        .length;

                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<TicketsBloc>().add(LoadTickets()),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildOverview(total, open, resolved),
                            const SizedBox(height: 32),
                            _buildActiveTicketsList(state.tickets),
                          ],
                        ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          context.push('/tickets/create');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user?.fullName ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName.substring(0, 1).toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search placeholder
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tickets...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverview(int total, int open, int resolved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total',
                total.toString(),
                Icons.folder_open,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Open',
                open.toString(),
                Icons.pending,
                AppColors.primary,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Resolved',
                resolved.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? color : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: Colors.grey[100]!),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isPrimary
                ? Colors.white.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            radius: 16,
            child: Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : AppColors.textMain,
            ),
          ),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTicketsList(List tickets) {
    if (tickets.isEmpty) return const Center(child: Text("No tickets found."));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Tickets',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tickets.map((t) => _TicketCard(ticket: t)),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view, 'Home', true),
          _buildNavItem(
            Icons.confirmation_number_outlined,
            'My Tickets',
            false,
            onTap: () => context.go('/my-tickets'),
          ),
          _buildNavItem(
            Icons.notifications_none_outlined,
            'Alerts',
            false,
            onTap: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Logout',
            onPressed: () => showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[400]),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final dynamic ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    if (ticket.priority == 'CRITICAL') {
      indicatorColor = Colors.red;
    } else if (ticket.priority == 'HIGH') {
      indicatorColor = Colors.orange;
    } else if (ticket.priority == 'MEDIUM') {
      indicatorColor = Colors.blue;
    } else {
      indicatorColor = Colors.grey;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          context.push('/ticket-detail', extra: ticket as TicketModel);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: indicatorColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: indicatorColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ticket.priority,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: indicatorColor,
                                  ),
                                ),
                              ),
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
                          const SizedBox(height: 8),
                          Text(
                            ticket.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ticket.slaDeadline != null
                                        ? DateFormat(
                                            'HH:mm',
                                          ).format(ticket.slaDeadline!)
                                        : 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Status: ${ticket.status}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
