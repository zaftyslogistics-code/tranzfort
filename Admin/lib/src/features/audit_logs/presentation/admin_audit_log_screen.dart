import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_audit_log_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_audit_log_providers.dart';

part 'admin_audit_log_sections.dart';

class AdminAuditLogScreen extends ConsumerWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(adminAuditLogProvider);

    return Scaffold(
      body: auditAsync.when(
        data: (state) => _AdminAuditLogContent(
          state: state,
          ref: ref,
          onOpenDetail: _openDetail,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Unable to load audit logs right now.')),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, AdminAuditLogEntry entry) {
    final payloadText = entry.payload.isEmpty
        ? '{}'
        : const JsonEncoder.withIndent('  ').convert(entry.payload);
    final detailPath = _auditEntryDetailPath(entry);
    final secondaryDetailPath = _auditSecondaryEntryDetailPath(entry);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_actionLabel(entry.actionType)),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Summary', value: entry.summary.isEmpty ? '-' : entry.summary),
                  _DetailRow(label: 'Audit id', value: entry.id.isEmpty ? '-' : entry.id),
                  _DetailRow(label: 'Actor type', value: entry.actorType.isEmpty ? '-' : entry.actorType),
                  _DetailRow(label: 'Actor role', value: entry.actorRole.isEmpty ? '-' : entry.actorRole),
                  _DetailRow(label: 'Actor admin', value: entry.actorAdminLabel.isEmpty ? '-' : entry.actorAdminLabel),
                  _DetailRow(label: 'Actor admin id', value: entry.actorAdminUserId.isEmpty ? '-' : entry.actorAdminUserId),
                  _DetailRow(label: 'Target', value: '${entry.targetObjectType.isEmpty ? '-' : entry.targetObjectType} • ${entry.targetObjectId.isEmpty ? '-' : entry.targetObjectId}'),
                  _DetailRow(label: 'Secondary', value: '${entry.secondaryObjectType.isEmpty ? '-' : entry.secondaryObjectType} • ${entry.secondaryObjectId.isEmpty ? '-' : entry.secondaryObjectId}'),
                  _DetailRow(label: 'Visibility', value: entry.visibilityClass.isEmpty ? '-' : entry.visibilityClass),
                  _DetailRow(label: 'Created', value: _dateLabel(entry.createdAt)),
                  if (detailPath != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      key: ValueKey('audit-dialog-open-related-${entry.id}'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go(detailPath);
                      },
                      child: const Text('Open related item'),
                    ),
                  ],
                  if (secondaryDetailPath != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: ValueKey('audit-dialog-open-secondary-${entry.id}'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go(secondaryDetailPath);
                      },
                      child: const Text('Open secondary item'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text('Payload', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.raisedSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(payloadText),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _pickStartDate(
  BuildContext context,
  WidgetRef ref,
  AdminAuditLogQuery query,
) async {
  final picked = await showDatePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateTime(2100),
    initialDate: query.startDate ?? query.endDate ?? DateTime.now(),
  );
  if (picked == null) {
    return;
  }
  final endDate = query.endDate;
  final normalizedEndDate = endDate != null && endDate.isBefore(picked) ? picked : endDate;
  await ref.read(adminAuditLogProvider.notifier).updateDateRange(
        startDate: picked,
        endDate: normalizedEndDate,
      );
}

Future<void> _pickEndDate(
  BuildContext context,
  WidgetRef ref,
  AdminAuditLogQuery query,
) async {
  final initialDate = query.endDate ?? query.startDate ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateTime(2100),
    initialDate: initialDate,
  );
  if (picked == null) {
    return;
  }
  final startDate = query.startDate;
  final normalizedStartDate = startDate != null && startDate.isAfter(picked) ? picked : startDate;
  await ref.read(adminAuditLogProvider.notifier).updateDateRange(
        startDate: normalizedStartDate,
        endDate: picked,
      );
}
