import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_support_providers.dart';

class AdminSupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const AdminSupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<AdminSupportTicketDetailScreen> createState() => _AdminSupportTicketDetailScreenState();
}

class _AdminSupportTicketDetailScreenState extends ConsumerState<AdminSupportTicketDetailScreen> {
  final _replyController = TextEditingController();
  String? _selectedCannedResponse;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminSupportTicketDetailProvider(widget.ticketId));
    final replyState = ref.watch(adminSupportReplyProvider);

    return detailAsync.when(
      data: (detail) {
        if (detail == null) {
          return const Center(child: Text('Support ticket not found.'));
        }

        final ticket = detail.ticket;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.id,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(label: _titleCaseWords(ticket.status), color: AdminColors.warning),
                        _MetaPill(label: _titleCaseWords(ticket.priority), color: _priorityColor(ticket.priority)),
                        _MetaPill(label: _titleCaseWords(ticket.category), color: AdminColors.accentTeal),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Ticket summary',
              child: Column(
                children: [
                  _DetailRow(label: 'Ticket id', value: ticket.id.isEmpty ? '-' : ticket.id),
                  _DetailRow(label: 'Owner', value: ticket.ownerName),
                  _DetailRow(label: 'Category', value: _titleCaseWords(ticket.category)),
                  _DetailRow(label: 'Status', value: _titleCaseWords(ticket.status)),
                  _DetailRow(label: 'Priority', value: _titleCaseWords(ticket.priority)),
                  _DetailRow(label: 'Contact', value: ticket.ownerContact.isEmpty ? '-' : ticket.ownerContact),
                  _DetailRow(label: 'Created', value: _dateTimeLabel(ticket.createdAt)),
                  _DetailRow(label: 'Updated', value: _dateTimeLabel(ticket.updatedAt)),
                  _DetailRow(label: 'Resolved', value: _dateTimeLabel(ticket.resolvedAt)),
                  _DetailRow(label: 'Resolution', value: ticket.resolutionSummary.isEmpty ? '-' : ticket.resolutionSummary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'User profile preview',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Profile id', value: ticket.ownerProfileId.isEmpty ? '-' : ticket.ownerProfileId),
                  _DetailRow(label: 'Role', value: _titleCaseWords(ticket.ownerRole)),
                  _DetailRow(label: 'Verification', value: _titleCaseWords(ticket.ownerVerificationStatus)),
                  _DetailRow(label: 'Trust state', value: ticket.ownerIsBanned ? 'Banned' : 'Active'),
                  _DetailRow(label: 'Joined', value: _dateTimeLabel(ticket.ownerCreatedAt)),
                  _DetailRow(label: 'Last login', value: _dateTimeLabel(ticket.ownerLastLoginAt)),
                  if (ticket.ownerProfileId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey('support-owner-profile-button'),
                        onPressed: () => context.go(AdminRoutes.userDetailPathFor(ticket.ownerProfileId)),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open user profile'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Linked context',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Load', value: ticket.relatedLoadId.isEmpty ? '-' : ticket.relatedLoadId),
                  _DetailRow(label: 'Trip', value: ticket.relatedTripId.isEmpty ? '-' : ticket.relatedTripId),
                  if (ticket.relatedTripId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Trip context is visible on this ticket, but a dedicated admin trip-detail route is not available in the current shell yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                    ),
                  if (ticket.relatedLoadId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey('support-related-load-button'),
                        onPressed: () => context.go(AdminRoutes.loadDetailPathFor(ticket.relatedLoadId)),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Open related load'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Current support contract',
              child: Text(
                'Visible admin replies are live on this ticket. Internal notes, assign-to-me, status changes, priority changes, and resolve actions remain intentionally unavailable here until dedicated admin support contracts land.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Conversation',
              child: detail.messages.isEmpty
                  ? const Text('No ticket messages are available yet.')
                  : Column(
                      children: detail.messages
                          .map(
                            (message) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.forum_outlined),
                              title: Text(message.senderLabel),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.messageBody.isEmpty ? '-' : message.messageBody),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Message ${message.id.isEmpty ? '-' : message.id}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                  ),
                                  if (message.attachmentPath.isNotEmpty)
                                    Text(
                                      'Attachment ${message.attachmentPath}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Visibility ${_titleCaseWords(message.visibilityClass)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created ${_dateTimeLabel(message.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                  ),
                                ],
                              ),
                              trailing: Text(_dateTimeLabel(message.createdAt), style: Theme.of(context).textTheme.labelMedium),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            if (_isReplyable(ticket.status)) ...[
              const SizedBox(height: 16),
              _DetailSectionCard(
                title: 'Reply to ticket',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey('support-canned-response-dropdown'),
                      initialValue: _selectedCannedResponse,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Canned response',
                        hintText: 'Choose a recommended support reply',
                      ),
                      items: adminSupportCannedResponses
                          .map(
                            (response) => DropdownMenuItem<String>(
                              value: response,
                              child: Text(response, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(growable: false),
                      selectedItemBuilder: (context) {
                        return adminSupportCannedResponses
                            .map(
                              (response) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  response,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false);
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCannedResponse = value;
                          if (value != null) {
                            _replyController
                              ..text = value
                              ..selection = TextSelection.collapsed(offset: value.length);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canned responses only prefill the visible reply text below. They do not assign the ticket, change status or priority, escalate the case, or resolve it.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('support-reply-field'),
                      controller: _replyController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Reply',
                        hintText: 'Write the next support response',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('support-reply-button'),
                      onPressed: replyState.isLoading ? null : _submitReply,
                      child: replyState.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Send reply'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AdminColors.error),
              const SizedBox(height: 12),
              const Text('Unable to load support ticket details right now.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(adminSupportTicketDetailProvider(widget.ticketId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReply() async {
    final message = _replyController.text.trim();
    if (message.length < 2) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enter at least 2 characters before sending a support reply.')));
      return;
    }
    bool ok;
    try {
      ok = await ref.read(adminSupportReplyProvider.notifier).replyToTicket(
            ticketId: widget.ticketId,
            messageBody: message,
          );
    } catch (_) {
      ok = false;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(ok ? 'Support reply sent successfully.' : 'Could not send this support reply right now. Try again shortly.')),
      );
    if (ok) {
      setState(() {
        _selectedCannedResponse = null;
      });
      _replyController.clear();
      ref.invalidate(adminSupportTicketDetailProvider(widget.ticketId));
      ref.invalidate(adminSupportQueueProvider);
    }
  }
}

const List<String> adminSupportCannedResponses = <String>[
  'Payment being processed, will reflect within 24h',
  'Please re-upload required documents',
  'Escalated to operations team',
  'Issue resolved. Let us know if you need help.',
];

bool _isReplyable(String status) {
  return !const {'resolved', 'closed'}.contains(status.trim());
}

class _DetailSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
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
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

Color _priorityColor(String value) {
  return switch (value.trim()) {
    'urgent' => AdminColors.error,
    'high' => AdminColors.warning,
    'medium' => AdminColors.accentTeal,
    _ => AdminColors.textSecondary,
  };
}

String _dateTimeLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _titleCaseWords(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
