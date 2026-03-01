import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../dashboard/data/admin_repository.dart';

import '../domain/ticket_model.dart';
import 'bloc/tickets_bloc.dart';
import 'employee_response_sheet.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  List<dynamic> _auditLogs = [];
  bool _auditLoading = false;
  bool _showAudit = false;

  @override
  void initState() {
    super.initState();
    _fetchAuditTrail();
  }

  Future<void> _fetchAuditTrail() async {
    setState(() => _auditLoading = true);
    try {
      final response = await sl<AdminRepository>().apiClient.dio.get(
        '${ApiConstants.tickets}/${widget.ticket.id}/audit',
      );
      final logs = response.data['audit_logs'] as List? ?? [];
      if (mounted) setState(() => _auditLogs = logs);
    } catch (_) {
      // Silently fail — audit is non-critical
    } finally {
      if (mounted) setState(() => _auditLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TicketsBloc>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                widget.ticket.ticketNumber,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTicketHeader(),
                  const SizedBox(height: 24),
                  _buildClientInfo(context),
                  if (widget.ticket.images.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildImages(context),
                  ],
                  const SizedBox(height: 24),
                  _buildResponses(context),
                  const SizedBox(height: 24),
                  _buildAuditTrail(),
                  _buildRoleBasedActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Ticket header card ─────────────────────────────────────────────────────
  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priorityBadge(widget.ticket.priority),
              _statusBadge(widget.ticket.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.ticket.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.ticket.description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created: ${DateFormat('MMM dd, HH:mm').format(widget.ticket.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (widget.ticket.slaDeadline != null)
                Text(
                  'SLA: ${DateFormat('MMM dd, HH:mm').format(widget.ticket.slaDeadline!)}',
                  style: TextStyle(fontSize: 12, color: Colors.red[400]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color c = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // ─── Client info (visible to employee and admin) ─────────────────────────────
  Widget _buildClientInfo(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        final role = state.user.role;
        if (role != 'employee' && role != 'admin') {
          return const SizedBox.shrink();
        }
        final client = widget.ticket.client;
        if (client == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client['full_name'] ?? 'Client',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    client['email'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Image thumbnails with fullscreen viewer ─────────────────────────────────
  Widget _buildImages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.ticket.images.length,
            itemBuilder: (context, index) {
              final image = widget.ticket.images[index];
              return GestureDetector(
                onTap: () => _openFullscreen(context, image.imageUrl),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(image.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _FullscreenImageViewer(imageUrl: url)),
    );
  }

  // ─── Response thread ─────────────────────────────────────────────────────────
  Widget _buildResponses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Responses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (widget.ticket.responses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Text(
              'No responses yet.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isAdmin =
                  authState is AuthAuthenticated &&
                  authState.user.role == 'admin';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.ticket.responses
                    .map((r) => _buildResponseItem(context, r, isAdmin))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildResponseItem(
    BuildContext context,
    TicketResponse response,
    bool isAdmin,
  ) {
    Color typeColor = Colors.blue;
    if (response.type == 'APPROVED' || response.type == 'approved') {
      typeColor = Colors.green;
    } else if (response.type == 'REJECTED' || response.type == 'rejected') {
      typeColor = Colors.red;
    } else if (response.type == 'PENDING_REVIEW' ||
        response.type == 'pending_review') {
      typeColor = Colors.orange;
    } else if (response.type == 'REVISION_REQUESTED' ||
        response.type == 'revision_requested') {
      typeColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                response.employeeName ?? 'Support Team',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.type.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 10,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(response.content, style: TextStyle(color: Colors.grey[800])),
          // Show admin feedback if response was rejected
          if (response.adminFeedback != null &&
              response.adminFeedback!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Feedback:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    response.adminFeedback!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            DateFormat('MMM dd, HH:mm').format(response.createdAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          // Admin approve/reject buttons on pending_review
          if (isAdmin &&
              (response.type == 'PENDING_REVIEW' ||
                  response.type == 'pending_review')) ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectDialog(context, response.id),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    context.read<TicketsBloc>().add(
                      ApproveResponse(widget.ticket.id, response.id),
                    );
                  },
                  child: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext ctx, String responseId) {
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Response'),
        content: TextField(
          controller: feedbackCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Feedback / Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (feedbackCtrl.text.trim().isEmpty) return;
              ctx.read<TicketsBloc>().add(
                RejectResponse(
                  widget.ticket.id,
                  responseId,
                  feedback: feedbackCtrl.text.trim(),
                ),
              );
              Navigator.pop(dialogCtx);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Audit trail ─────────────────────────────────────────────────────────────
  Widget _buildAuditTrail() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        final role = state.user.role;
        if (role != 'employee' && role != 'admin') {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _showAudit = !_showAudit),
              child: Row(
                children: [
                  const Text(
                    'Audit Trail',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (_auditLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const Spacer(),
                  Icon(
                    _showAudit
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (_showAudit) ...[
              const SizedBox(height: 12),
              if (_auditLogs.isEmpty)
                const Text(
                  'No audit logs.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              else
                ..._auditLogs.map((log) => _buildAuditItem(log)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAuditItem(dynamic log) {
    final fromStatus =
        (log['from_status'] as String?)?.toUpperCase().replaceAll('_', ' ') ??
        '—';
    final toStatus =
        (log['to_status'] as String?)?.toUpperCase().replaceAll('_', ' ') ?? '';
    final note = log['note'] as String? ?? '';
    final changedAt = log['changed_at'] != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(log['changed_at']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromStatus → $toStatus',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            changedAt,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Role-based action buttons ────────────────────────────────────────────────
  Widget _buildRoleBasedActions(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        final role = state.user.role;

        // ── Client actions on resolved/closed ──────────────────────────────────
        if (role == 'client') {
          final isResolved =
              widget.ticket.status == 'resolved' ||
              widget.ticket.status == 'RESOLVED';
          final isClosed =
              widget.ticket.status == 'closed' ||
              widget.ticket.status == 'CLOSED';
          if (isResolved || isClosed) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(context),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate Response'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<TicketsBloc>().add(
                      ReopenTicket(widget.ticket.id),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket Reopened')),
                    );
                    context.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reopen Ticket'),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }

        // ── Employee actions ────────────────────────────────────────────────────
        if (role == 'employee') {
          // Determine if the employee can still respond
          final canRespond = _canEmployeeRespond();
          if (!canRespond) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => BlocProvider.value(
                      value: context.read<TicketsBloc>(),
                      child: EmployeeResponseSheet(ticket: widget.ticket),
                    ),
                  );
                },
                icon: const Icon(Icons.reply),
                label: const Text('Write Response'),
              ),
            ],
          );
        }

        // ── Admin actions ───────────────────────────────────────────────────────
        if (role == 'admin') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  context.read<TicketsBloc>().add(
                    EscalateTicket(widget.ticket.id),
                  );
                },
                icon: const Icon(Icons.warning, color: Colors.white),
                label: const Text(
                  'Escalate & Notify',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showReassignDialog(context),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Reassign Ticket'),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Returns true if an employee should see the Write Response button.
  /// Hides it when any response is pending_review, approved, or ticket is resolved/closed.
  bool _canEmployeeRespond() {
    final status = widget.ticket.status.toLowerCase();
    if (status == 'resolved' ||
        status == 'closed' ||
        status == 'pending_review') {
      return false;
    }
    // Also check if any response is already pending_review or approved
    for (final r in widget.ticket.responses) {
      final rStatus = r.type.toLowerCase();
      if (rStatus == 'pending_review' || rStatus == 'approved') {
        return false;
      }
    }
    return true;
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────
  void _showReassignDialog(BuildContext screenContext) {
    showDialog(
      context: screenContext,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Ticket'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: sl<AdminRepository>().fetchEmployees(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }
              final employees = snapshot.data ?? [];
              if (employees.isEmpty) {
                return const Text('No employees found.');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  return ListTile(
                    title: Text(emp['full_name']),
                    subtitle: Text(
                      'Open Tickets: ${emp['employee_profile']?['open_ticket_count'] ?? 0}',
                    ),
                    onTap: () {
                      screenContext.read<TicketsBloc>().add(
                        ReassignTicket(widget.ticket.id, emp['id']),
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext screenContext) {
    int rating = 5;
    final commentController = TextEditingController();
    showDialog(
      context: screenContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Response'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                screenContext.read<TicketsBloc>().add(
                  RateTicket(widget.ticket.id, rating, commentController.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullscreen image viewer ────────────────────────────────────────────────────
class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullscreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
