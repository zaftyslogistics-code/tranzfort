import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/admin_verification_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/verification_queue_provider.dart';

class VerificationQueueScreen extends ConsumerWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queuesAsync = ref.watch(verificationQueuesProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/verifications'),
        appBar: AppBar(
          title: const Text('Verification queues'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: queuesAsync.maybeWhen(
                  data: (q) => _tabLabel('Supplier', q.suppliers.length),
                  orElse: () => const Text('Supplier'),
                ),
              ),
              Tab(
                child: queuesAsync.maybeWhen(
                  data: (q) => _tabLabel('Trucker', q.truckers.length),
                  orElse: () => const Text('Trucker'),
                ),
              ),
              Tab(
                child: queuesAsync.maybeWhen(
                  data: (q) => _tabLabel('Truck', q.trucks.length),
                  orElse: () => const Text('Truck'),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: AdminBrandHeader(
                title: 'Verification control',
                subtitle:
                    'Review submitted documents and action SLA-risk items first',
                icon: Icons.verified_user_outlined,
              ),
            ),
            Expanded(
              child: queuesAsync.when(
                data: (queues) => TabBarView(
                  children: [
                    _QueueList(items: queues.suppliers),
                    _QueueList(items: queues.truckers),
                    _QueueList(items: queues.trucks),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorRetry(
                  title: 'Unable to load verification queue',
                  subtitle: 'Please check your connection and try again.',
                  onRetry: () => ref
                      .read(verificationQueuesProvider.notifier)
                      .refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  final List<VerificationQueueItem> items;

  const _QueueList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AdminColors.border),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AdminColors.textTertiary,
                  size: 24,
                ),
                SizedBox(height: 8),
                Text('No pending verification requests in this queue.'),
              ],
            ),
          ),
        ),
      );
    }

    final queueType = items.first.type;
    final sortedItems = [...items]
      ..sort((a, b) {
        final aTime = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columns: _columnsFor(queueType),
              rows: sortedItems
                  .asMap()
                  .entries
                  .map((entry) => _rowFor(context, entry.value, entry.key))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _columnsFor(VerificationEntityType type) {
    switch (type) {
      case VerificationEntityType.supplier:
        return const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Company')),
          DataColumn(label: Text('Mobile')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Submitted')),
          DataColumn(label: Text('SLA')),
        ];
      case VerificationEntityType.trucker:
        return const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('DL Number')),
          DataColumn(label: Text('Mobile')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Submitted')),
          DataColumn(label: Text('SLA')),
        ];
      case VerificationEntityType.truck:
        return const [
          DataColumn(label: Text('Truck Number')),
          DataColumn(label: Text('Owner')),
          DataColumn(label: Text('Body Type')),
          DataColumn(label: Text('Tyres')),
          DataColumn(label: Text('Submitted')),
          DataColumn(label: Text('SLA')),
        ];
    }
  }

  DataRow _rowFor(BuildContext context, VerificationQueueItem item, int index) {
    final shaded = index.isOdd;
    final rowColor = WidgetStateProperty.resolveWith<Color?>((_) {
      return shaded ? AdminColors.scaffoldBg : null;
    });

    switch (item.type) {
      case VerificationEntityType.supplier:
        return DataRow(
          color: rowColor,
          cells: [
            DataCell(Text(item.primaryLabel)),
            DataCell(Text(item.companyName.isEmpty ? '-' : item.companyName)),
            DataCell(Text(item.secondaryLabel)),
            DataCell(Text(item.email.isEmpty ? '-' : item.email)),
            DataCell(Text(_submittedLabel(item.submittedAt))),
            DataCell(_slaCell(item.slaHoursRemaining)),
          ],
          onSelectChanged: (_) => _openDetail(context, item),
        );
      case VerificationEntityType.trucker:
        return DataRow(
          color: rowColor,
          cells: [
            DataCell(Text(item.primaryLabel)),
            DataCell(Text(item.dlNumber.isEmpty ? '-' : item.dlNumber)),
            DataCell(Text(item.secondaryLabel)),
            DataCell(Text(item.email.isEmpty ? '-' : item.email)),
            DataCell(Text(_submittedLabel(item.submittedAt))),
            DataCell(_slaCell(item.slaHoursRemaining)),
          ],
          onSelectChanged: (_) => _openDetail(context, item),
        );
      case VerificationEntityType.truck:
        return DataRow(
          color: rowColor,
          cells: [
            DataCell(Text(item.primaryLabel)),
            DataCell(Text(item.ownerName.isEmpty ? '-' : item.ownerName)),
            DataCell(Text(item.bodyType.isEmpty ? '-' : item.bodyType)),
            DataCell(Text(item.tyres <= 0 ? '-' : '${item.tyres}')),
            DataCell(Text(_submittedLabel(item.submittedAt))),
            DataCell(_slaCell(item.slaHoursRemaining)),
          ],
          onSelectChanged: (_) => _openDetail(context, item),
        );
    }
  }

  Widget _slaCell(double slaHoursRemaining) {
    final isExpired = slaHoursRemaining < 0;
    final isWarning = slaHoursRemaining >= 0 && slaHoursRemaining <= 4;
    final color = isExpired
        ? AdminColors.error
        : (isWarning ? AdminColors.brandOrange : AdminColors.primary);
    final label = isExpired
        ? 'Exceeded ${slaHoursRemaining.abs().toStringAsFixed(1)}h'
        : '${slaHoursRemaining.toStringAsFixed(1)}h left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _submittedLabel(DateTime? submittedAt) {
    if (submittedAt == null) return '-';
    final now = DateTime.now().toUtc();
    final diff = now.difference(submittedAt.toUtc());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _openDetail(BuildContext context, VerificationQueueItem item) {
    context.push('/verification/${verificationTypePath(item.type)}/${item.id}');
  }
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
