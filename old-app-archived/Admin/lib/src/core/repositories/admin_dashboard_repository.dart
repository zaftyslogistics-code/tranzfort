import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(ref),
);

class AdminDashboardRepository {
  final Ref _ref;
  static const List<String> _profileVerificationQueueStatusesPreferred = <String>[
    'pending',
    'submitted',
    'under_review',
  ];
  static const List<String> _profileVerificationQueueStatusesLegacy = <String>[
    'pending',
  ];

  AdminDashboardRepository(this._ref);

  Future<AdminDashboardSnapshot> fetchSnapshot() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) {
      return const AdminDashboardSnapshot(isLiveData: false);
    }

    final now = DateTime.now().toUtc();
    final h6 = now.subtract(const Duration(hours: 6)).toIso8601String();
    final h20 = now.subtract(const Duration(hours: 20)).toIso8601String();
    final h24 = now.subtract(const Duration(hours: 24)).toIso8601String();
    final h48 = now.subtract(const Duration(hours: 48)).toIso8601String();

    final client = Supabase.instance.client;

    final activeUsers = await _safeCount(() {
      return client.from('profiles').select('id').eq('is_banned', false);
    });

    final verifiedTrucks = await _safeCount(() {
      return client.from('trucks').select('id').eq('status', 'verified');
    });

    final pendingProfileVerifications = await _safeProfileVerificationCount(
      client,
    );
    final pendingTruckVerifications = await _safeCount(() {
      return client.from('trucks').select('id').eq('status', 'pending');
    });

    final openTickets = await _safeCount(() {
      return client.from('support_tickets').select('id').inFilter('status', [
        'open',
        'in_progress',
      ]);
    });

    final activeSuperLoads = await _safeCount(() {
      return client
          .from('loads')
          .select('id')
          .eq('is_super_load', true)
          .not('super_status', 'in', '(none,completed)');
    });

    final verifApproachingProfiles = await _safeProfileVerificationCount(
      client,
      gteUpdatedAt: h24,
      ltUpdatedAt: h20,
    );
    final verifApproachingTrucks = await _safeCount(() {
      return client
          .from('trucks')
          .select('id')
          .eq('status', 'pending')
          .gte('created_at', h24)
          .lt('created_at', h20);
    });

    final verifExceededProfiles = await _safeProfileVerificationCount(
      client,
      ltUpdatedAt: h24,
    );
    final verifExceededTrucks = await _safeCount(() {
      return client
          .from('trucks')
          .select('id')
          .eq('status', 'pending')
          .lt('created_at', h24);
    });

    final staleSupportTickets = await _safeCount(() {
      return client
          .from('support_tickets')
          .select('id')
          .inFilter('status', ['open', 'in_progress'])
          .lt('updated_at', h48);
    });

    final superLoadDispatchDelayed = await _safeCount(() {
      return client
          .from('loads')
          .select('id')
          .eq('is_super_load', true)
          .eq('super_status', 'requested')
          .lt('created_at', h6);
    });

    final recentActivity = await _safeRecentActivity(client);

    final verificationApproaching =
        verifApproachingProfiles + verifApproachingTrucks;
    final verificationExceeded = verifExceededProfiles + verifExceededTrucks;

    final alerts = <AdminSlaAlert>[];
    if (verificationApproaching > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$verificationApproaching verifications approaching 24h SLA',
          severity: AdminAlertSeverity.warning,
        ),
      );
    }
    if (verificationExceeded > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$verificationExceeded verifications exceeded 24h SLA',
          severity: AdminAlertSeverity.critical,
        ),
      );
    }
    if (staleSupportTickets > 0) {
      alerts.add(
        AdminSlaAlert(
          message: '$staleSupportTickets support tickets stale > 48h',
          severity: AdminAlertSeverity.critical,
        ),
      );
    }
    if (superLoadDispatchDelayed > 0) {
      alerts.add(
        AdminSlaAlert(
          message:
              '$superLoadDispatchDelayed super loads awaiting dispatch > 6h',
          severity: AdminAlertSeverity.warning,
        ),
      );
    }

    return AdminDashboardSnapshot(
      isLiveData: true,
      activeUsers: activeUsers,
      verifiedTrucks: verifiedTrucks,
      pendingVerifications:
          pendingProfileVerifications + pendingTruckVerifications,
      openTickets: openTickets,
      activeSuperLoads: activeSuperLoads,
      slaAlerts: alerts,
      recentActivity: recentActivity,
    );
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() call) async {
    try {
      final rows = await call();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _safeProfileVerificationCount(
    SupabaseClient client, {
    String? gteUpdatedAt,
    String? ltUpdatedAt,
  }) async {
    Future<List<dynamic>> queryWithStatuses(List<String> statuses) {
      dynamic query = client
          .from('profiles')
          .select('id')
          .inFilter('verification_status', statuses);
      if (gteUpdatedAt != null) {
        query = query.gte('updated_at', gteUpdatedAt);
      }
      if (ltUpdatedAt != null) {
        query = query.lt('updated_at', ltUpdatedAt);
      }
      return query;
    }

    try {
      final rows = await queryWithStatuses(
        _profileVerificationQueueStatusesPreferred,
      );
      return rows.length;
    } on PostgrestException catch (error) {
      if (!_isVerificationStatusEnumMismatch(error)) {
        return 0;
      }

      try {
        final rows = await queryWithStatuses(
          _profileVerificationQueueStatusesLegacy,
        );
        return rows.length;
      } catch (_) {
        return 0;
      }
    } catch (_) {
      return 0;
    }
  }

  bool _isVerificationStatusEnumMismatch(PostgrestException error) {
    return error.code == '22P02' &&
        error.message.toLowerCase().contains('verification_status');
  }

  Future<List<String>> _safeRecentActivity(SupabaseClient client) async {
    try {
      final rows = await client
          .from('audit_logs')
          .select('action,entity_type,entity_id,created_at')
          .order('created_at', ascending: false)
          .limit(10);

      return rows.map<String>((row) {
        final action = _asString(row['action']);
        final entityType = _asString(row['entity_type']);
        final entityId = _asString(row['entity_id']);
        final createdAt = DateTime.tryParse(_asString(row['created_at']));
        final timeLabel = createdAt == null
            ? 'unknown time'
            : '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}';
        final idLabel = entityId.isEmpty ? '-' : entityId;
        return '$timeLabel - $action $entityType ($idLabel)';
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}

String _asString(dynamic value) => (value ?? '').toString();

enum AdminAlertSeverity { warning, critical }

class AdminSlaAlert {
  final String message;
  final AdminAlertSeverity severity;

  const AdminSlaAlert({required this.message, required this.severity});
}

class AdminDashboardSnapshot {
  final bool isLiveData;
  final int activeUsers;
  final int verifiedTrucks;
  final int pendingVerifications;
  final int openTickets;
  final int activeSuperLoads;
  final List<AdminSlaAlert> slaAlerts;
  final List<String> recentActivity;

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
