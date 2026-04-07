import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/admin_support_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/support_queue_provider.dart';

class SupportTicketQueueScreen extends ConsumerStatefulWidget {
  const SupportTicketQueueScreen({super.key});

  @override
  ConsumerState<SupportTicketQueueScreen> createState() =>
      _SupportTicketQueueScreenState();
}

class _SupportTicketQueueScreenState
    extends ConsumerState<SupportTicketQueueScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(supportTicketCountsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/support'),
        appBar: AppBar(
          title: const Text('Support tickets'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: countsAsync.maybeWhen(
                  data: (counts) => _tabLabel('Open', counts.open),
                  orElse: () => const Text('Open'),
                ),
              ),
              Tab(
                child: countsAsync.maybeWhen(
                  data: (counts) => _tabLabel('In Progress', counts.inProgress),
                  orElse: () => const Text('In Progress'),
                ),
              ),
              Tab(
                child: countsAsync.maybeWhen(
                  data: (counts) => _tabLabel('Resolved', counts.resolved),
                  orElse: () => const Text('Resolved'),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  const AdminBrandHeader(
                    title: 'Support control center',
                    subtitle:
                        'Track, prioritize, and resolve user issues with clear ownership',
                    icon: Icons.support_agent,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by subject, user, or ticket ID',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear search',
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _QueueTab(
                    status: SupportTicketStatus.open,
                    search: _searchController.text,
                  ),
                  _QueueTab(
                    status: SupportTicketStatus.inProgress,
                    search: _searchController.text,
                  ),
                  _QueueTab(
                    status: SupportTicketStatus.resolved,
                    search: _searchController.text,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends ConsumerWidget {
  final SupportTicketStatus status;
  final String search;

  const _QueueTab({required this.status, required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = SupportTicketQueueQuery(status: status, search: search);
    final queueAsync = ref.watch(supportQueueProvider(query));

    return queueAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return const Center(
            child: Text('No support tickets match this tab or the current search.'),
          );
        }

        return ListView.separated(
          addAutomaticKeepAlives: false,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: tickets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            final priorityColor = _priorityColor(ticket.priority);
            final isVeryOld = _isVeryOld(ticket.createdAt);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: priorityColor, width: 1.8),
              ),
              child: ListTile(
                title: Text(ticket.subject),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(ticket.userName),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          text: _priorityLabel(ticket.priority),
                          color: priorityColor,
                        ),
                        _Pill(
                          text: _ageLabel(ticket.createdAt),
                          color: isVeryOld
                              ? AdminColors.textTertiary
                              : AdminColors.textSecondary,
                        ),
                        _Pill(
                          text: ticket.assignedAdminName.isEmpty
                              ? 'Not assigned'
                              : 'Assigned to ${ticket.assignedAdminName}',
                          color: ticket.assignedAdminName.isEmpty
                              ? AdminColors.brandOrange
                              : AdminColors.primary,
                          backgroundColor: ticket.assignedAdminName.isEmpty
                              ? AdminColors.warningTint
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/support/${ticket.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorRetry(
        title: 'Unable to load support ticket queue',
        subtitle: 'Please check your connection and try again.',
        onRetry: () => ref.invalidate(supportQueueProvider(query)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;

  const _Pill({required this.text, required this.color, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

String _ageLabel(DateTime? createdAt) {
  if (createdAt == null) return 'Age unknown';
  final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
  if (diff.inDays > 0) return '${diff.inDays}d old';
  if (diff.inHours > 0) return '${diff.inHours}h old';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m old';
  return 'Just now';
}

bool _isVeryOld(DateTime? createdAt) {
  if (createdAt == null) return false;
  final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
  return diff.inDays > 7;
}

Widget _tabLabel(String title, int count) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(color: Colors.white),
      children: [
        TextSpan(text: '$title '),
        TextSpan(
          text: '($count)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
