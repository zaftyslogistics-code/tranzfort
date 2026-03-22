import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/admin_routes.dart';
import '../providers/admin_app_state_providers.dart';

enum AdminAlertSeverity { warning, critical }

class AdminSlaAlert {
  final String message;
  final AdminAlertSeverity severity;
  final String? route;
  final String? actionLabel;

  const AdminSlaAlert({
    required this.message,
    required this.severity,
    this.route,
    this.actionLabel,
  });
}

class AdminRecentActivityItem {
  final String label;
  final String targetObjectType;
  final String targetObjectId;

  const AdminRecentActivityItem({
    required this.label,
    required this.targetObjectType,
    required this.targetObjectId,
  });
}

class AdminDashboardSnapshot {
  final bool isLiveData;
  final int activeUsers;
  final int verifiedTrucks;
  final int pendingVerifications;
  final int openTickets;
  final int activeSuperLoads;
  final List<AdminSlaAlert> slaAlerts;
  final List<AdminRecentActivityItem> recentActivity;

  const AdminDashboardSnapshot({
    required this.isLiveData,
    this.activeUsers = 0,
    this.verifiedTrucks = 0,
    this.pendingVerifications = 0,
    this.openTickets = 0,
    this.activeSuperLoads = 0,
    this.slaAlerts = const [],
    this.recentActivity = const [],
  });
}

abstract class AdminDashboardBackend {
  Future<int> countActiveUsers();

  Future<int> countVerifiedTrucks();

  Future<int> countPendingVerifications();

  Future<int> countOpenTickets();

  Future<int> countActiveSuperLoads();

  Future<int> countVerificationApproachingSla();

  Future<int> countVerificationExceededSla();

  Future<int> countStaleSupportTickets();

  Future<int> countDelayedSuperLoads();

  Future<List<AdminRecentActivityItem>> fetchRecentActivity();
}

class SupabaseAdminDashboardBackend implements AdminDashboardBackend {
  final SupabaseClient? client;

  const SupabaseAdminDashboardBackend(this.client);

  @override
  Future<int> countActiveUsers() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(() => activeClient.from('profiles').select('id').eq('is_banned', false));
  }

  @override
  Future<int> countVerifiedTrucks() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(() => activeClient.from('trucks').select('id').eq('status', 'verified'));
  }

  @override
  Future<int> countPendingVerifications() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }

    return _safeCount(
      () => activeClient
          .from('verification_cases')
          .select('id')
          .inFilter('case_status', ['submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated']),
    );
  }

  @override
  Future<int> countOpenTickets() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(
      () => activeClient.from('support_tickets').select('id').inFilter('status', ['open', 'in_progress', 'waiting_for_user']),
    );
  }

  @override
  Future<int> countActiveSuperLoads() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(
      () => activeClient
          .from('loads')
          .select('id')
          .eq('is_super_load', true)
          .inFilter('super_status', ['request_submitted', 'under_review', 'approved_payment_pending', 'active']),
    );
  }

  @override
  Future<int> countVerificationApproachingSla() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    final now = DateTime.now().toUtc();
    final h24 = now.subtract(const Duration(hours: 24)).toIso8601String();
    final h20 = now.subtract(const Duration(hours: 20)).toIso8601String();
    return _safeCount(
      () => activeClient
          .from('verification_cases')
          .select('id')
          .inFilter('case_status', ['submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated'])
          .gte('submitted_at', h24)
          .lt('submitted_at', h20),
    );
  }

  @override
  Future<int> countVerificationExceededSla() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    final h24 = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
    return _safeCount(
      () => activeClient
          .from('verification_cases')
          .select('id')
          .inFilter('case_status', ['submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated'])
          .lt('submitted_at', h24),
    );
  }

  @override
  Future<int> countStaleSupportTickets() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    final h48 = DateTime.now().toUtc().subtract(const Duration(hours: 48)).toIso8601String();
    return _safeCount(
      () => activeClient
          .from('support_tickets')
          .select('id')
          .inFilter('status', ['open', 'in_progress', 'waiting_for_user'])
          .lt('updated_at', h48),
    );
  }

  @override
  Future<int> countDelayedSuperLoads() async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    final h6 = DateTime.now().toUtc().subtract(const Duration(hours: 6)).toIso8601String();
    return _safeCount(
      () => activeClient
          .from('loads')
          .select('id')
          .eq('is_super_load', true)
          .eq('super_status', 'request_submitted')
          .lt('created_at', h6),
    );
  }

  @override
  Future<List<AdminRecentActivityItem>> fetchRecentActivity() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('audit_logs')
          .select('action_type, target_object_type, target_object_id, created_at')
          .order('created_at', ascending: false)
          .limit(10);
      return rows.map<AdminRecentActivityItem>((row) {
        final action = _asString(row['action_type']);
        final entityType = _asString(row['target_object_type']);
        final entityId = _asString(row['target_object_id']);
        final createdAt = DateTime.tryParse(_asString(row['created_at']));
        final timeLabel = createdAt == null
            ? 'Unknown time'
            : '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}';
        return AdminRecentActivityItem(
          label: '$timeLabel - $action $entityType (${entityId.isEmpty ? '-' : entityId})',
          targetObjectType: entityType,
          targetObjectId: entityId,
        );
      }).toList(growable: false);
    } catch (error) {
      debugPrint('Admin dashboard fetchRecentActivity error: $error');
      return const [];
    }
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() query) async {
    try {
      final result = await query();
      return result.length;
    } catch (error) {
      debugPrint('Admin dashboard _safeCount error: $error');
      return 0;
    }
  }

}

class AdminDashboardRepository {
  final AdminDashboardBackend backend;

  const AdminDashboardRepository({required this.backend});

  Future<AdminDashboardSnapshot> fetchSnapshot() async {
    final activeUsers = await backend.countActiveUsers();
    final verifiedTrucks = await backend.countVerifiedTrucks();
    final pendingVerifications = await backend.countPendingVerifications();
    final openTickets = await backend.countOpenTickets();
    final activeSuperLoads = await backend.countActiveSuperLoads();
    final verificationApproaching = await backend.countVerificationApproachingSla();
    final verificationExceeded = await backend.countVerificationExceededSla();
    final staleSupportTickets = await backend.countStaleSupportTickets();
    final delayedSuperLoads = await backend.countDelayedSuperLoads();
    final recentActivity = await backend.fetchRecentActivity();

    final alerts = <AdminSlaAlert>[];
    if (verificationApproaching > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$verificationApproaching verifications are approaching the 24h SLA window.',
          severity: AdminAlertSeverity.warning,
          route: AdminRoutes.verificationPath,
          actionLabel: 'Open verification queue',
        ),
      );
    }
    if (verificationExceeded > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$verificationExceeded verifications have exceeded the 24h SLA window.',
          severity: AdminAlertSeverity.critical,
          route: AdminRoutes.verificationPath,
          actionLabel: 'Open verification queue',
        ),
      );
    }
    if (staleSupportTickets > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$staleSupportTickets support tickets have been stale for more than 48h.',
          severity: AdminAlertSeverity.critical,
          route: AdminRoutes.supportPath,
          actionLabel: 'Open support queue',
        ),
      );
    }
    if (delayedSuperLoads > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$delayedSuperLoads Super Load requests are still waiting for dispatch after 6h.',
          severity: AdminAlertSeverity.warning,
          route: AdminRoutes.superOpsPath,
          actionLabel: 'Open Super Ops',
        ),
      );
    }

    final isLiveData = backend is SupabaseAdminDashboardBackend && (backend as SupabaseAdminDashboardBackend).client != null;
    return AdminDashboardSnapshot(
      isLiveData: isLiveData,
      activeUsers: activeUsers,
      verifiedTrucks: verifiedTrucks,
      pendingVerifications: pendingVerifications,
      openTickets: openTickets,
      activeSuperLoads: activeSuperLoads,
      slaAlerts: alerts,
      recentActivity: recentActivity,
    );
  }
}

String _asString(dynamic value) => (value ?? '').toString();

final adminDashboardBackendProvider = Provider<AdminDashboardBackend>((ref) {
  return SupabaseAdminDashboardBackend(ref.watch(adminSupabaseClientProvider));
});

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(
    backend: ref.watch(adminDashboardBackendProvider),
  );
});
