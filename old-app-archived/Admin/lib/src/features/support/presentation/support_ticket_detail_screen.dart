import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/repositories/admin_support_repository.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/support_ticket_detail_provider.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../models/support_canned_response_templates.dart';

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();
  final _resolutionController = TextEditingController();
  SupportTicketPriority? _selectedPriority;
  String? _selectedTemplateKey;

  @override
  void dispose() {
    _replyController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  void _applyTemplate(SupportCannedResponseTemplate template) {
    setState(() => _selectedTemplateKey = template.key);
    _replyController.text = template.body;
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _replyController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(supportTicketDetailProvider(widget.ticketId));
    final actionState = ref.watch(supportTicketActionProvider);
    final role = ref.watch(currentAdminRoleProvider);
    final adminAsync = ref.watch(currentAdminAccessProvider);
    final isSuperAdmin = adminHasAccess(role, {AdminRole.superAdmin});

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket details')),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Support ticket not found.'));
          }

          final ticket = detail.ticket;
          _selectedPriority ??= ticket.priority;
          
          // Check if Ops Admin can perform actions on this ticket
          final currentAdmin = adminAsync.valueOrNull;
          final isAssignedToMe = currentAdmin != null && 
              ticket.assignedAdminId == currentAdmin.id;
          final canPerformActions = isSuperAdmin || isAssignedToMe;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.cardPadding,
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.pagePadding,
            ),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket: ${ticket.subject}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Text(
                        '${detail.userNameWithRole} • ${_statusLabel(ticket.status)} • ${_priorityLabel(ticket.priority)}',
                      ),
                      const SizedBox(height: AdminDesignTokens.gapXs),
                      Text('Created: ${_formatDate(ticket.createdAt)}'),
                      Text(
                        ticket.assignedAdminName.isEmpty
                            ? 'Assigned: Unassigned'
                            : 'Assigned: ${ticket.assignedAdminName}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Wrap(
                        spacing: AdminDesignTokens.gapSm,
                        runSpacing: AdminDesignTokens.gapXs,
                        children: [
                          _MetaPill(
                            label: 'Status: ${_statusLabel(ticket.status)}',
                            color: AdminColors.primary,
                          ),
                          _MetaPill(
                            label: 'Priority: ${_priorityLabel(ticket.priority)}',
                            color: _priorityColor(ticket.priority),
                          ),
                          _MetaPill(
                            label: 'Age: ${_ageLabel(ticket.createdAt)}',
                            color: AdminColors.textSecondary,
                          ),
                          _MetaPill(
                            label: ticket.assignedAdminName.isEmpty
                                ? 'Assignee: Unassigned'
                                : 'Assignee: ${ticket.assignedAdminName}',
                            color: ticket.assignedAdminName.isEmpty
                                ? AdminColors.brandOrange
                                : AdminColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Description',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Text(detail.description.ifEmpty('-')),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Text('Issue category: ${detail.category.ifEmpty('-')}'),
                      Text('User mobile: ${detail.userMobile.ifEmpty('-')}'),
                      Text('User email: ${detail.userEmail.ifEmpty('-')}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversation history',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      if (detail.messages.isEmpty)
                        const Text('No conversation replies yet.')
                      else
                        ...detail.messages.map((message) {
                          final isAdmin = message.senderRole == 'admin';
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                              bottom: AdminDesignTokens.gapSm,
                            ),
                            padding: const EdgeInsets.all(AdminDesignTokens.gapSm),
                            decoration: BoxDecoration(
                              color:
                                  (isAdmin
                                          ? AdminColors.brandTealLight
                                          : AdminColors.brandOrangeLight)
                                      .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${isAdmin ? 'Admin' : 'User'}: ${message.senderName}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(message.content),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(message.createdAt),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AdminColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reply to user',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      TextField(
                        controller: _replyController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Type a reply for the user here',
                        ),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Text(
                        'Quick templates',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Wrap(
                        spacing: AdminDesignTokens.gapSm,
                        runSpacing: AdminDesignTokens.gapSm,
                        children: supportCannedResponseTemplates
                            .map(
                              (item) => ChoiceChip(
                                label: Text(item.title),
                                selected: _selectedTemplateKey == item.key,
                                onSelected: (_) => _applyTemplate(item),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      DropdownButtonFormField<SupportCannedResponseTemplate>(
                        initialValue: supportCannedResponseTemplates
                            .where((item) => item.key == _selectedTemplateKey)
                            .cast<SupportCannedResponseTemplate?>()
                            .firstOrNull,
                        decoration: const InputDecoration(
                          labelText: 'Canned Responses',
                        ),
                        items: supportCannedResponseTemplates
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.title),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _applyTemplate(value);
                        },
                      ),
                      const SizedBox(height: AdminDesignTokens.sectionGap),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: actionState.isLoading ? null : _sendReply,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Send reply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              if (canPerformActions)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AdminDesignTokens.gapSm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: actionState.isLoading
                                    ? null
                                    : _assignToMe,
                                child: const Text('Assign to Me'),
                              ),
                            ),
                            const SizedBox(width: AdminDesignTokens.gapSm),
                            Expanded(
                              child:
                                  DropdownButtonFormField<SupportTicketPriority>(
                                    initialValue: _selectedPriority,
                                    decoration: const InputDecoration(
                                      labelText: 'Priority',
                                    ),
                                    items: SupportTicketPriority.values
                                        .map(
                                          (priority) => DropdownMenuItem(
                                            value: priority,
                                            child: Text(_priorityLabel(priority)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: actionState.isLoading
                                        ? null
                                        : (value) async {
                                            if (value == null) return;
                                            setState(
                                              () => _selectedPriority = value,
                                            );
                                            final ok = await ref
                                                .read(
                                                  supportTicketActionProvider
                                                      .notifier,
                                                )
                                                .changePriority(
                                                  ticketId: widget.ticketId,
                                                  priority: value,
                                                );
                                            if (!mounted) return;
                                            _showResult(
                                              ok,
                                              success: 'Priority updated.',
                                              fail: 'Could not update priority.',
                                            );
                                          },
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AdminDesignTokens.sectionGap),
                        TextField(
                          controller: _resolutionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Resolution notes (required to mark the ticket resolved)',
                          ),
                        ),
                        const SizedBox(height: AdminDesignTokens.gapSm),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                actionState.isLoading ||
                                    ticket.status == SupportTicketStatus.resolved
                                ? null
                                : _resolve,
                            child: const Text('Mark resolved'),
                          ),
                        ),
                        if (detail.resolutionNotes.isNotEmpty) ...[
                          const SizedBox(height: AdminDesignTokens.gapSm),
                          Text(
                            'Existing resolution: ${detail.resolutionNotes}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: AdminColors.infoTint,
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AdminColors.info),
                        const SizedBox(width: AdminDesignTokens.gapSm),
                        Expanded(
                          child: Text(
                            isAssignedToMe
                                ? 'Actions are available for tickets assigned to you. Use the reply section above.'
                                : 'Read-only view. Assign this ticket to yourself to take action.',
                            style: TextStyle(color: AdminColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorRetry(
          title: 'Unable to load support ticket detail',
          subtitle: 'Please check your connection and try again.',
          onRetry: () => ref.invalidate(supportTicketDetailProvider(widget.ticketId)),
        ),
      ),
    );
  }

  Future<void> _assignToMe() async {
    final ok = await ref
        .read(supportTicketActionProvider.notifier)
        .assignToMe(widget.ticketId);
    if (!mounted) return;
    _showResult(
      ok,
      success: 'Ticket assigned to you successfully.',
      fail: 'Could not assign ticket.',
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      _showResult(false, success: '', fail: 'Reply cannot be empty.');
      return;
    }

    final ok = await ref
        .read(supportTicketActionProvider.notifier)
        .sendReply(ticketId: widget.ticketId, text: text);
    if (!mounted) return;

    _showResult(
      ok,
      success: 'Reply sent successfully.',
      fail: 'Could not send reply.',
    );
    if (ok) _replyController.clear();
  }

  Future<void> _resolve() async {
    final notes = _resolutionController.text.trim();
    if (notes.length < 10) {
      _showResult(
        false,
        success: '',
        fail: 'Resolution notes must be at least 10 characters.',
      );
      return;
    }

    final ok = await ref
        .read(supportTicketActionProvider.notifier)
        .resolveTicket(ticketId: widget.ticketId, notes: notes);
    if (!mounted) return;

    _showResult(
      ok,
      success: 'Ticket marked as resolved.',
      fail: 'Could not resolve ticket.',
    );
    if (ok) _resolutionController.clear();
  }

  void _showResult(bool ok, {required String success, required String fail}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? success : fail)));
  }
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return IstTime.formatDate(dateTime, 'dd MMM yyyy, hh:mm a');
}

String _priorityLabel(SupportTicketPriority priority) {
  switch (priority) {
    case SupportTicketPriority.low:
      return 'Low';
    case SupportTicketPriority.medium:
      return 'Medium';
    case SupportTicketPriority.high:
      return 'High';
    case SupportTicketPriority.urgent:
      return 'Urgent';
  }
}

String _statusLabel(SupportTicketStatus status) {
  switch (status) {
    case SupportTicketStatus.open:
      return 'Open';
    case SupportTicketStatus.inProgress:
      return 'In Progress';
    case SupportTicketStatus.resolved:
      return 'Resolved';
  }
}

Color _priorityColor(SupportTicketPriority priority) {
  switch (priority) {
    case SupportTicketPriority.low:
      return Colors.green;
    case SupportTicketPriority.medium:
      return AdminColors.brandOrange;
    case SupportTicketPriority.high:
      return Colors.deepOrange;
    case SupportTicketPriority.urgent:
      return AdminColors.error;
  }
}

String _ageLabel(DateTime? createdAt) {
  if (createdAt == null) return 'unknown';
  final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'now';
}

extension on SupportTicketDetail {
  String get userNameWithRole {
    final role = userRole.isEmpty ? '' : ' ($userRole)';
    return '${ticket.userName}$role';
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
