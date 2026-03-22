import 'package:admin/src/core/repositories/admin_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminDashboardBackend implements AdminDashboardBackend {
  int activeUsers = 0;
  int verifiedTrucks = 0;
  int pendingVerifications = 0;
  int openTickets = 0;
  int activeSuperLoads = 0;
  int verificationApproachingSla = 0;
  int verificationExceededSla = 0;
  int staleSupportTickets = 0;
  int delayedSuperLoads = 0;
  List<AdminRecentActivityItem> recentActivity = const [];

  @override
  Future<int> countActiveSuperLoads() async => activeSuperLoads;

  @override
  Future<int> countActiveUsers() async => activeUsers;

  @override
  Future<int> countDelayedSuperLoads() async => delayedSuperLoads;

  @override
  Future<int> countOpenTickets() async => openTickets;

  @override
  Future<int> countPendingVerifications() async => pendingVerifications;

  @override
  Future<int> countStaleSupportTickets() async => staleSupportTickets;

  @override
  Future<int> countVerificationApproachingSla() async => verificationApproachingSla;

  @override
  Future<int> countVerificationExceededSla() async => verificationExceededSla;

  @override
  Future<int> countVerifiedTrucks() async => verifiedTrucks;

  @override
  Future<List<AdminRecentActivityItem>> fetchRecentActivity() async => recentActivity;
}

void main() {
  test('fetchSnapshot preserves pending verification counts from the verification authority backend', () async {
    final backend = _FakeAdminDashboardBackend()
      ..activeUsers = 12
      ..verifiedTrucks = 4
      ..pendingVerifications = 7
      ..openTickets = 3
      ..activeSuperLoads = 2
      ..verificationApproachingSla = 2
      ..verificationExceededSla = 1
      ..recentActivity = const [
        AdminRecentActivityItem(
          label: '09:45 - approved verification_case (case-1)',
          targetObjectType: 'verification_case',
          targetObjectId: 'case-1',
        ),
      ];

    final repository = AdminDashboardRepository(backend: backend);
    final snapshot = await repository.fetchSnapshot();

    expect(snapshot.activeUsers, 12);
    expect(snapshot.verifiedTrucks, 4);
    expect(snapshot.pendingVerifications, 7);
    expect(snapshot.openTickets, 3);
    expect(snapshot.activeSuperLoads, 2);
    expect(snapshot.slaAlerts, hasLength(2));
    expect(
      snapshot.slaAlerts.map((alert) => alert.message),
      contains('2 verifications are approaching the 24h SLA window.'),
    );
    expect(
      snapshot.slaAlerts.map((alert) => alert.message),
      contains('1 verifications have exceeded the 24h SLA window.'),
    );
    expect(snapshot.recentActivity.single.targetObjectType, 'verification_case');
  });
}
