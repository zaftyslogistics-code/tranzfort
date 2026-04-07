import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/repositories/audit_logs_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../core/utils/ist_time.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../providers/audit_logs_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _keywordController = TextEditingController();
  final _actionController = TextEditingController();
  final _entityController = TextEditingController();

  String _csvEscape(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<void> _exportCsv(AuditLogQuery query) async {
    final logs = await ref.read(auditLogsRepositoryProvider).fetchLogs(query);

    if (!mounted) {
      return;
    }

    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audit logs available to export.')),
      );
      return;
    }

    final buffer = StringBuffer()
      ..writeln('id,admin_id,admin_name,action,entity_type,entity_id,created_at,metadata');

    for (final log in logs) {
      buffer.writeln([
        _csvEscape(log.id),
        _csvEscape(log.adminId),
        _csvEscape(log.adminName),
        _csvEscape(log.action),
        _csvEscape(log.entityType),
        _csvEscape(log.entityId),
        _csvEscape(log.createdAt?.toIso8601String() ?? ''),
        _csvEscape(log.metadata.toString()),
      ].join(','));
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}${Platform.pathSeparator}audit-logs-$timestamp.csv');
      await file.writeAsString(buffer.toString());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audit log CSV exported to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export audit log CSV: $e')),
      );
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _actionController.dispose();
    _entityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentAdminRoleProvider);

    if (!adminHasAccess(role, {AdminRole.superAdmin})) {
      return Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/audit-logs'),
        appBar: AppBar(title: const Text('Audit logs')),
        body: const Center(
          child: Text('Only Super Admins can access audit logs.'),
        ),
      );
    }

    final query = AuditLogQuery(
      keyword: _keywordController.text,
      action: _actionController.text,
      entityType: _entityController.text,
      limit: 120,
    );

    final logsAsync = ref.watch(auditLogsProvider(query));

    return Scaffold(
      drawer: const AdminNavigationDrawer(currentRoute: '/audit-logs'),
      appBar: AppBar(
        title: const Text('Audit logs'),
        actions: [
          IconButton(
            onPressed: () => _exportCsv(query),
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export audit log CSV',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.cardPadding,
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.pagePadding,
        ),
        children: [
          const AdminBrandHeader(
            title: 'Security and change history',
            subtitle:
                'Trace critical admin actions across users, loads, verifications, and operations',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      labelText: 'Keyword (admin, action, entity, or ID)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AdminDesignTokens.gapSm),
                  Wrap(
                    spacing: AdminDesignTokens.gapSm,
                    children: [
                      'verify',
                      'ban',
                      'assign',
                      'create',
                      'update',
                      'delete',
                    ].map((action) => FilterChip(
                      label: Text(action),
                      selected: _actionController.text == action,
                      onSelected: (selected) {
                        setState(() {
                          _actionController.text = selected ? action : '';
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: AdminDesignTokens.gapSm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _actionController,
                          decoration: const InputDecoration(
                            labelText: 'Action',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AdminDesignTokens.gapSm),
                      Expanded(
                        child: TextField(
                          controller: _entityController,
                          decoration: const InputDecoration(
                            labelText: 'Entity type',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Text(
                      'No audit logs match the selected filters.',
                    ),
                  ),
                );
              }

              return Column(
                children: logs
                    .map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: AdminDesignTokens.gapSm),
                        child: Card(
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _actionColor(log.action),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            title: Text(
                              '${log.action} • ${log.entityType}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${_timeAgo(log.createdAt)} • ${log.adminName}',
                                ),
                                const SizedBox(height: 4),
                                Text('Entity ID: ${log.entityId.ifEmpty('-')}'),
                                if (log.metadata.isNotEmpty)
                                  Text(
                                    'Metadata: ${log.metadata}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AdminColors.textSecondary,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                child: Text('Unable to load audit logs right now.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

Color _actionColor(String action) {
  final lower = action.toLowerCase();
  if (lower.contains('verify')) return AdminColors.brandTeal;
  if (lower.contains('ban')) return AdminColors.error;
  if (lower.contains('assign')) return AdminColors.info;
  return AdminColors.textSecondary;
}

String _timeAgo(DateTime? dateTime) {
  if (dateTime == null) return '-';
  final diff = IstTime.age(dateTime);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}
