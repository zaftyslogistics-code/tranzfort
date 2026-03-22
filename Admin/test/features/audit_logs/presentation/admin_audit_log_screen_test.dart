import 'package:admin/src/core/repositories/admin_audit_log_repository.dart';
import 'package:admin/src/features/audit_logs/presentation/admin_audit_log_screen.dart';
import 'package:admin/src/features/audit_logs/providers/admin_audit_log_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminAuditLogController extends AdminAuditLogController {
  final AdminAuditLogState initialState;

  _FakeAdminAuditLogController(this.initialState);

  @override
  Future<AdminAuditLogState> build() async => initialState;
}

void main() {
  testWidgets('admin audit log screen renders rows and opens detail dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminAuditLogProvider.overrideWith(
            () => _FakeAdminAuditLogController(
              AdminAuditLogState.initial().copyWith(
                items: [
                  AdminAuditLogEntry(
                    id: 'audit-1',
                    actorAdminUserId: 'admin-1',
                    actorAdminLabel: 'Super Ops One (super_admin)',
                    actorType: 'admin',
                    actorRole: 'super_admin',
                    actionType: 'case_escalated',
                    targetObjectType: 'operational_case',
                    targetObjectId: 'case-1',
                    secondaryObjectType: 'profile',
                    secondaryObjectId: 'user-1',
                    summary: 'Operational case escalated to super admin',
                    payload: {'reason': 'manual escalation'},
                    visibilityClass: 'internal',
                    createdAt: DateTime(2026, 3, 12, 21, 30),
                  ),
                ],
                summary: const AdminAuditLogSummary(
                  totalCount: 1,
                  internalCount: 1,
                  userActionCount: 1,
                  adminActionCount: 0,
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminAuditLogScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Audit logs'), findsOneWidget);
    expect(find.text('Action, summary, actor admin, or object id'), findsOneWidget);
    expect(find.text('Search audit logs'), findsOneWidget);
    expect(find.text('Actor type'), findsOneWidget);
    expect(find.text('Object type'), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-log-start-date-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-log-end-date-button')), findsOneWidget);

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Operational case escalated to super admin'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Operational case escalated to super admin'), findsOneWidget);
    expect(find.text('Actor type admin • Visibility internal • Target operational_case'), findsOneWidget);
    expect(find.text('Actor Super Ops One (super_admin) • admin-1'), findsOneWidget);
    expect(find.text('Target operational_case • case-1'), findsOneWidget);
    expect(find.text('Audit audit-1'), findsOneWidget);
    expect(find.text('Created 2026-03-12 21:30'), findsOneWidget);
    expect(find.text('Secondary profile • user-1'), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-log-entry-audit-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-open-related-audit-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-open-secondary-audit-1')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('case escalated'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audit-log-entry-audit-1')));
    await tester.pumpAndSettle();

    expect(find.text('case escalated'), findsWidgets);
    expect(find.text('Audit id'), findsOneWidget);
    expect(find.text('audit-1'), findsWidgets);
    expect(find.text('Actor type'), findsOneWidget);
    expect(find.text('admin'), findsWidgets);
    expect(find.text('Actor admin'), findsOneWidget);
    expect(find.text('Super Ops One (super_admin)'), findsWidgets);
    expect(find.byKey(const ValueKey('audit-dialog-open-related-audit-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-dialog-open-secondary-audit-1')), findsOneWidget);
    expect(find.textContaining('manual escalation'), findsWidgets);
  });
}
