import 'package:admin/src/core/repositories/admin_operational_case_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminOperationalCaseBackend implements AdminOperationalCaseBackend {
  List<Map<String, dynamic>> operationalCases = const [];
  Map<String, Map<String, dynamic>> operationalCasesById = const {};
  Map<String, List<Map<String, dynamic>>> operationalCaseEventsById = const {};
  Map<String, Map<String, dynamic>> profilesById = const {};
  Map<String, Map<String, dynamic>> tripsById = const {};
  Map<String, Map<String, dynamic>> loadsById = const {};
  Map<String, Map<String, dynamic>> adminUsersById = const {};
  List<Map<String, dynamic>> activeSuperAdmins = const [];
  String? lastClaimedCaseId;
  String? lastReleasedCaseId;
  String? lastTransitionCaseId;
  OperationalCaseTransitionTarget? lastTransitionTarget;
  String? lastTransitionSummary;
  String? lastTransitionNote;
  String? lastResolvedCaseId;
  OperationalCaseResolutionTarget? lastResolutionTarget;
  String? lastResolutionSummary;
  String? lastEscalatedCaseId;
  String? lastEscalationTargetId;
  String? lastEscalationReason;

  @override
  Future<List<Map<String, dynamic>>> fetchOperationalCases() async => operationalCases;

  @override
  Future<Map<String, dynamic>?> fetchOperationalCaseById(String caseId) async => operationalCasesById[caseId];

  @override
  Future<List<Map<String, dynamic>>> fetchOperationalCaseEvents(String caseId) async => operationalCaseEventsById[caseId] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async => ids
      .map((id) => profilesById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<List<Map<String, dynamic>>> fetchTripsByIds(List<String> ids) async => ids
      .map((id) => tripsById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<Map<String, dynamic>?> fetchTripById(String id) async => tripsById[id];

  @override
  Future<List<Map<String, dynamic>>> fetchLoadsByIds(List<String> ids) async => ids
      .map((id) => loadsById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<Map<String, dynamic>?> fetchLoadById(String id) async => loadsById[id];

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async => ids
      .map((id) => adminUsersById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<Map<String, dynamic>?> fetchAdminUserById(String id) async => adminUsersById[id];

  @override
  Future<List<Map<String, dynamic>>> fetchActiveSuperAdmins() async => activeSuperAdmins;

  @override
  Future<bool> claimOperationalCase(String caseId) async {
    lastClaimedCaseId = caseId;
    return true;
  }

  @override
  Future<bool> releaseOperationalCase(String caseId) async {
    lastReleasedCaseId = caseId;
    return true;
  }

  @override
  Future<bool> transitionOperationalCase({
    required String caseId,
    required OperationalCaseTransitionTarget target,
    String? summary,
    String? internalNote,
  }) async {
    lastTransitionCaseId = caseId;
    lastTransitionTarget = target;
    lastTransitionSummary = summary;
    lastTransitionNote = internalNote;
    return true;
  }

  @override
  Future<bool> resolveOperationalCase({
    required String caseId,
    required OperationalCaseResolutionTarget target,
    required String summary,
  }) async {
    lastResolvedCaseId = caseId;
    lastResolutionTarget = target;
    lastResolutionSummary = summary;
    return true;
  }

  @override
  Future<bool> escalateOperationalCase({
    required String caseId,
    required String targetAdminUserId,
    String? reason,
  }) async {
    lastEscalatedCaseId = caseId;
    lastEscalationTargetId = targetAdminUserId;
    lastEscalationReason = reason;
    return true;
  }
}

void main() {
  test('getOperationalCases maps counts, broad search, and lifecycle actions to backend', () async {
    final backend = _FakeAdminOperationalCaseBackend()
      ..operationalCases = [
        {
          'id': 'case-1',
          'case_type': 'trip_dispute',
          'primary_object_type': 'trip',
          'primary_object_id': 'trip-1',
          'queue_classification': 'dispute',
          'status': 'queued',
          'claimed_by_admin_user_id': '',
          'claimed_at': null,
          'waiting_reason': 'Awaiting bank receipt',
          'escalated_to_admin_user_id': '',
          'resolution_summary': '',
          'created_at': '2026-03-11T08:00:00.000Z',
          'updated_at': '2026-03-11T09:00:00.000Z',
          'resolved_at': null,
        },
        {
          'id': 'case-2',
          'case_type': 'trip_dispute',
          'primary_object_type': 'trip',
          'primary_object_id': 'trip-2',
          'queue_classification': 'dispute',
          'status': 'resolved',
          'claimed_by_admin_user_id': '',
          'claimed_at': null,
          'waiting_reason': '',
          'escalated_to_admin_user_id': '',
          'resolution_summary': 'Final super-admin review',
          'created_at': '2026-03-11T08:00:00.000Z',
          'updated_at': '2026-03-11T09:00:00.000Z',
          'resolved_at': '2026-03-11T10:00:00.000Z',
        },
      ]
      ..tripsById = {
        'trip-1': {'id': 'trip-1', 'load_id': 'load-1', 'supplier_id': 's1', 'trucker_id': 't1', 'stage': 'proof_submitted'},
        'trip-2': {'id': 'trip-2', 'load_id': 'load-2', 'supplier_id': 's2', 'trucker_id': 't2', 'stage': 'proof_submitted'},
      }
      ..loadsById = {
        'load-1': {'id': 'load-1', 'origin_city': 'Mumbai', 'destination_city': 'Pune', 'material_type': 'Steel'},
        'load-2': {'id': 'load-2', 'origin_city': 'Delhi', 'destination_city': 'Bangalore', 'material_type': 'Steel'},
      };

    final container = ProviderContainer(overrides: [adminOperationalCaseBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminOperationalCaseRepositoryProvider);
    final page = await repository.getOperationalCases(
      const OperationalCaseQuery(
        statusFilter: OperationalCaseStatusFilter.all,
        search: 'mumbai',
      ),
    );
    final waitingPage = await repository.getOperationalCases(
      const OperationalCaseQuery(
        statusFilter: OperationalCaseStatusFilter.all,
        search: 'awaiting bank receipt',
      ),
    );
    final resolutionPage = await repository.getOperationalCases(
      const OperationalCaseQuery(
        statusFilter: OperationalCaseStatusFilter.all,
        search: 'final super-admin review',
      ),
    );
    final claimOk = await repository.claimCase('case-1');
    final releaseOk = await repository.releaseCase('case-1');

    expect(page.counts.queued, 1);
    expect(page.items.single.claimedByLabel, '');
    expect(page.items.single.escalatedToLabel, '');
    expect(waitingPage.items, hasLength(1));
    expect(waitingPage.items.single.id, 'case-1');
    expect(resolutionPage.items, hasLength(1));
    expect(resolutionPage.items.single.id, 'case-2');
    expect(claimOk, isTrue);
    expect(releaseOk, isTrue);
    expect(backend.lastClaimedCaseId, 'case-1');
    expect(backend.lastReleasedCaseId, 'case-1');
  });

  test('getOperationalCaseDetail maps events and transition/resolve route to backend', () async {
    final backend = _FakeAdminOperationalCaseBackend()
      ..operationalCasesById = {
        'case-1': {
          'id': 'case-1',
          'case_type': 'trip_dispute',
          'primary_object_type': 'trip',
          'primary_object_id': 'trip-1',
          'queue_classification': 'dispute',
          'status': 'claimed',
          'claimed_by_admin_user_id': 'admin-1',
          'claimed_at': null,
          'waiting_reason': 'Awaiting more proof',
          'escalated_to_admin_user_id': '',
          'resolution_summary': '',
          'created_at': '2026-03-11T08:00:00.000Z',
          'updated_at': '2026-03-11T09:00:00.000Z',
          'resolved_at': null,
        },
      }
      ..operationalCaseEventsById = {
        'case-1': [
          {
            'id': 'event-1',
            'event_type': 'case_claimed',
            'event_summary': 'Operational case claimed',
            'internal_note': '',
            'created_at': '2026-03-11T09:00:00.000Z',
          },
        ],
      }
      ..tripsById = {
        'trip-1': {'id': 'trip-1', 'load_id': 'load-1', 'supplier_id': 's1', 'trucker_id': 't1', 'stage': 'proof_submitted'},
      }
      ..profilesById = {
        's1': {'id': 's1', 'full_name': 'Supplier One'},
        't1': {'id': 't1', 'full_name': 'Trucker One'},
      }
      ..loadsById = {
        'load-1': {'id': 'load-1', 'origin_city': 'Mumbai', 'destination_city': 'Pune', 'material': 'Steel', 'supplier_id': 's1', 'assigned_trucker_id': 't1', 'status': 'active'},
      }
      ..adminUsersById = {
        'admin-1': {'id': 'admin-1', 'full_name': 'Ops One', 'role': 'ops_admin'},
      };

    final container = ProviderContainer(overrides: [adminOperationalCaseBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminOperationalCaseRepositoryProvider);
    final detail = await repository.getOperationalCaseDetail('case-1');
    final transitionOk = await repository.transitionCase(
      caseId: 'case-1',
      target: OperationalCaseTransitionTarget.waitingForUser,
      summary: 'Need more proof',
      internalNote: 'Ask for clearer POD image',
    );
    final resolveOk = await repository.resolveCase(
      caseId: 'case-1',
      target: OperationalCaseResolutionTarget.resolved,
      summary: 'Dispute settled',
    );

    expect(detail, isNotNull);
    expect(detail!.item.claimedByLabel, 'Ops One');
    expect(detail.events.single.eventType, 'case_claimed');
    expect(detail.linkedObjectMetadata['Trip stage'], 'Proof Submitted');
    expect(detail.linkedObjectMetadata['Supplier id'], 's1');
    expect(detail.linkedObjectMetadata['Supplier'], 'Supplier One (s1)');
    expect(detail.linkedObjectMetadata['Trucker id'], 't1');
    expect(detail.linkedObjectMetadata['Assigned trucker'], 'Trucker One (t1)');
    expect(transitionOk, isTrue);
    expect(resolveOk, isTrue);
    expect(backend.lastTransitionTarget, OperationalCaseTransitionTarget.waitingForUser);
    expect(backend.lastResolutionTarget, OperationalCaseResolutionTarget.resolved);
  });

  test('getEscalationTargets and escalateCase route to backend', () async {
    final backend = _FakeAdminOperationalCaseBackend()
      ..activeSuperAdmins = const [
        {'id': 'admin-super-1', 'full_name': 'Super Admin One', 'role': 'super_admin'},
      ];

    final container = ProviderContainer(overrides: [adminOperationalCaseBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminOperationalCaseRepositoryProvider);
    final targets = await repository.getEscalationTargets();
    final ok = await repository.escalateCase(
      caseId: 'case-1',
      targetAdminUserId: 'admin-super-1',
      reason: 'Needs super admin review',
    );

    expect(targets, hasLength(1));
    expect(targets.single.name, 'Super Admin One');
    expect(ok, isTrue);
    expect(backend.lastEscalatedCaseId, 'case-1');
    expect(backend.lastEscalationTargetId, 'admin-super-1');
  });
}
