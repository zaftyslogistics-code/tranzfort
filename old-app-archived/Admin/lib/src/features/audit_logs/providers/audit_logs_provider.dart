import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/audit_logs_repository.dart';

final auditLogsProvider =
    FutureProvider.family<List<AuditLogEntry>, AuditLogQuery>((ref, query) {
      return ref.read(auditLogsRepositoryProvider).fetchLogs(query);
    });
