import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../../core/app_snackbar.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../domain/ticket_model.dart';
import 'bloc/tickets_bloc.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TicketsBloc>()..add(LoadTickets()),
      child: const _MyTicketsView(),
    );
  }
}

class _MyTicketsView extends StatefulWidget {
  const _MyTicketsView();

  @override
  State<_MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<_MyTicketsView> {
  String _sortOption = 'Date (Newest)';

  int _priorityValue(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return 4;
      case 'HIGH':
        return 3;
      case 'MEDIUM':
        return 2;
      case 'LOW':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Tickets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColors.textMain),
            onSelected: (String result) {
              setState(() {
                _sortOption = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Date (Newest)',
                child: Text('Date (Newest)'),
              ),
              const PopupMenuItem<String>(
                value: 'Date (Oldest)',
                child: Text('Date (Oldest)'),
              ),
              const PopupMenuItem<String>(
                value: 'Priority (High to Low)',
                child: Text('Priority (High to Low)'),
              ),
              const PopupMenuItem<String>(
                value: 'Priority (Low to High)',
                child: Text('Priority (Low to High)'),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<TicketsBloc, TicketsState>(
        builder: (context, state) {
          if (state is TicketsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TicketsError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackBar.error(context, state.message);
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load tickets',
                    style: TextStyle(fontSize: 16, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<TicketsBloc>().add(LoadTickets()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is TicketsLoaded) {
            final tickets = state.tickets;
            if (tickets.isEmpty) {
              return const Center(
                child: Text(
                  'No tickets found.',
                  style: TextStyle(color: AppColors.textMain),
                ),
              );
            }

            final sortedTickets = List<TicketModel>.from(tickets);
            sortedTickets.sort((a, b) {
              switch (_sortOption) {
                case 'Date (Newest)':
                  return b.createdAt.compareTo(a.createdAt);
                case 'Date (Oldest)':
                  return a.createdAt.compareTo(b.createdAt);
                case 'Priority (High to Low)':
                  return _priorityValue(
                    b.priority,
                  ).compareTo(_priorityValue(a.priority));
                case 'Priority (Low to High)':
                  return _priorityValue(
                    a.priority,
                  ).compareTo(_priorityValue(b.priority));
                default:
                  return 0;
              }
            });

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<TicketsBloc>().add(LoadTickets()),
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: sortedTickets.length,
                itemBuilder: (context, index) {
                  return _TicketCard(ticket: sortedTickets[index]);
                },
              ),
            );
          }
          return const Center(child: Text('No Data'));
        },
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
          _buildNavItem(
            Icons.grid_view,
            'Home',
            false,
            onTap: () => context.go('/client'),
          ),
          _buildNavItem(Icons.confirmation_number_outlined, 'My Tickets', true),
          _buildNavItem(
            Icons.notifications_none_outlined,
            'Alerts',
            false,
            onTap: () => context.push('/notifications'),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
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
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    switch (ticket.priority.toUpperCase()) {
      case 'CRITICAL':
        indicatorColor = Colors.red;
        break;
      case 'HIGH':
        indicatorColor = Colors.orange;
        break;
      case 'MEDIUM':
        indicatorColor = Colors.blue;
        break;
      default:
        indicatorColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        context.push('/ticket-detail', extra: ticket);
      },
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
    );
  }
}
