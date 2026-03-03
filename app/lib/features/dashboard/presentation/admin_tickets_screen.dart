import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../tickets/domain/ticket_model.dart';
import '../../tickets/presentation/bloc/tickets_bloc.dart';

/// Admin-facing ticket list with filter tabs for All, Pending Review, and Escalated.
/// Accepts an optional [initialFilter] to jump straight to a tab.
class AdminTicketsScreen extends StatelessWidget {
  final String? initialFilter; // 'pending_review', 'escalated', or null (all)

  const AdminTicketsScreen({super.key, this.initialFilter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TicketsBloc>()..add(LoadTickets()),
      child: _AdminTicketsView(initialFilter: initialFilter),
    );
  }
}

class _AdminTicketsView extends StatefulWidget {
  final String? initialFilter;
  const _AdminTicketsView({this.initialFilter});

  @override
  State<_AdminTicketsView> createState() => _AdminTicketsViewState();
}

class _AdminTicketsViewState extends State<_AdminTicketsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filters
  String? _priorityFilter;
  String? _statusFilter;

  final List<String> _tabs = [
    'All',
    'Pending Review',
    'Assigned',
    'Revision Req.',
    'Escalated',
    'Reassigned',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialFilter == 'pending_review') initialIndex = 1;
    if (widget.initialFilter == 'assigned') initialIndex = 2;
    if (widget.initialFilter == 'revision_requested') initialIndex = 3;
    if (widget.initialFilter == 'escalated') initialIndex = 4;
    if (widget.initialFilter == 'reassigned') initialIndex = 5;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TicketModel> _applyFilters(List<TicketModel> tickets) {
    var filtered = List<TicketModel>.from(tickets);

    // Tab filter
    final tabIndex = _tabController.index;
    if (tabIndex == 1) {
      filtered = filtered.where((t) => t.status == 'pending_review').toList();
    } else if (tabIndex == 2) {
      filtered = filtered.where((t) => t.status == 'assigned').toList();
    } else if (tabIndex == 3) {
      filtered = filtered
          .where((t) => t.status == 'revision_requested')
          .toList();
    } else if (tabIndex == 4) {
      filtered = filtered.where((t) => t.status == 'escalated').toList();
    } else if (tabIndex == 5) {
      filtered = filtered.where((t) => t.status == 'reassigned').toList();
    }

    // Priority filter
    if (_priorityFilter != null) {
      filtered = filtered.where((t) => t.priority == _priorityFilter).toList();
    }

    // Additional status filter on "All" tab
    if (tabIndex == 0 && _statusFilter != null) {
      filtered = filtered.where((t) => t.status == _statusFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tickets'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
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
                  final filtered = _applyFilters(state.tickets);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tickets match the current filters.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<TicketsBloc>().add(LoadTickets()),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _AdminTicketCard(ticket: filtered[index]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final priorities = ['critical', 'high', 'medium', 'low'];
    final statuses = [
      'open',
      'assigned',
      'in_progress',
      'pending_review',
      'revision_requested',
      'resolved',
      'closed',
      'reopened',
      'escalated',
      'reassigned',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority filter row
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('All Priorities', _priorityFilter == null, () {
                  setState(() => _priorityFilter = null);
                }),
                ...priorities.map(
                  (p) => _chip(
                    p.toUpperCase(),
                    _priorityFilter == p,
                    () => setState(() => _priorityFilter = p),
                  ),
                ),
              ],
            ),
          ),
          // Status filter row (only on All tab)
          if (_tabController.index == 0) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('All Status', _statusFilter == null, () {
                    setState(() => _statusFilter = null);
                  }),
                  ...statuses.map(
                    (s) => _chip(
                      s.toUpperCase().replaceAll('_', ' '),
                      _statusFilter == s,
                      () => setState(() => _statusFilter = s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : AppColors.textMain,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _AdminTicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _AdminTicketCard({required this.ticket});

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

    Color statusColor;
    switch (ticket.status) {
      case 'open':
        statusColor = AppColors.info;
        break;
      case 'assigned':
        statusColor = AppColors.primary;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'pending_review':
        statusColor = Colors.orange;
        break;
      case 'revision_requested':
        statusColor = Colors.deepOrange;
        break;
      case 'escalated':
        statusColor = Colors.red;
        break;
      case 'reassigned':
        statusColor = Colors.purple;
        break;
      case 'resolved':
        statusColor = AppColors.success;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      case 'reopened':
        statusColor = Colors.teal;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => context.push('/ticket-detail', extra: ticket),
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: indicatorColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ticket.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: indicatorColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ticket.status.toUpperCase().replaceAll(
                                  '_',
                                  ' ',
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.ticketNumber,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (ticket.slaDeadline != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat(
                                      'MMM dd, HH:mm',
                                    ).format(ticket.slaDeadline!),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
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
