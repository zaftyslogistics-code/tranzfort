import 'package:admin/src/core/repositories/admin_dashboard_repository.dart';
import 'package:admin/src/core/providers/admin_app_state_providers.dart';
import 'package:admin/src/features/dashboard/providers/admin_dashboard_provider.dart';
import 'package:admin/src/features/dashboard/presentation/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin dashboard renders KPI, alerts, and recent activity from provider state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAdminAuthStateProvider.overrideWithValue(
            const AdminAuthStateSnapshot(
              hasSession: true,
              role: AdminRole.superAdmin,
              isActive: true,
            ),
          ),
          adminDashboardProvider.overrideWith(
            () => _FakeAdminDashboardNotifier(
              const AdminDashboardSnapshot(
                isLiveData: true,
                activeUsers: 42,
                verifiedTrucks: 17,
                pendingVerifications: 6,
                openTickets: 4,
                activeSuperLoads: 3,
                slaAlerts: [
                  AdminSlaAlert(
                    message: '2 verifications are approaching the 24h SLA window.',
                    severity: AdminAlertSeverity.warning,
                    route: '/verification',
                    actionLabel: 'Open verification queue',
                  ),
                ],
                recentActivity: [
                  AdminRecentActivityItem(
                    label: '10:15 - resolved support_ticket (ticket-1)',
                    targetObjectType: 'support_ticket',
                    targetObjectId: 'ticket-1',
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Operations Dashboard'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Verified trucks'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-metric-action-Active users')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-metric-action-Pending verifications')), findsOneWidget);
    expect(find.text('SLA alerts'), findsOneWidget);
    expect(find.text('2 verifications are approaching the 24h SLA window.'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-alert-action-Open verification queue')), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('10:15 - resolved support_ticket (ticket-1)'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-open-recent-support_ticket-ticket-1')), findsOneWidget);
    expect(find.text('Quick navigation'), findsOneWidget);
    expect(find.text('Admin Management'), findsOneWidget);
    expect(find.text('Audit Logs'), findsOneWidget);
  });

  testWidgets('admin dashboard stays renderable on narrow mobile widths', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAdminAuthStateProvider.overrideWithValue(
            const AdminAuthStateSnapshot(
              hasSession: true,
              role: AdminRole.superAdmin,
              isActive: true,
            ),
          ),
          adminDashboardProvider.overrideWith(
            () => _FakeAdminDashboardNotifier(
              const AdminDashboardSnapshot(
                isLiveData: true,
                activeUsers: 2,
                verifiedTrucks: 0,
                pendingVerifications: 0,
                openTickets: 0,
                activeSuperLoads: 0,
                slaAlerts: [],
                recentActivity: [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Operations Dashboard'), findsOneWidget);
    expect(find.text('Quick navigation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAdminDashboardNotifier extends AdminDashboardNotifier {
  final AdminDashboardSnapshot snapshot;

  _FakeAdminDashboardNotifier(this.snapshot);

  @override
  Future<AdminDashboardSnapshot> build() async {
    return snapshot;
  }
}
