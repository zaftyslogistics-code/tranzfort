import 'package:admin/src/core/repositories/admin_management_repository.dart';
import 'package:admin/src/features/admin_management/presentation/admin_management_screen.dart';
import 'package:admin/src/features/admin_management/providers/admin_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminManagementController extends AdminManagementController {
  final AdminManagementState initialState;

  _FakeAdminManagementController(this.initialState);

  @override
  Future<AdminManagementState> build() async => initialState;
}

void main() {
  testWidgets('admin management screen renders summary and admin rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminManagementProvider.overrideWith(
            () => _FakeAdminManagementController(
              AdminManagementState.initial().copyWith(
                items: [
                  AdminManagementListItem(
                    id: 'admin-1',
                    authUserId: 'auth-1',
                    fullName: 'Super Admin One',
                    email: 'super@example.com',
                    role: 'super_admin',
                    isActive: true,
                    createdBy: '',
                    createdAt: DateTime(2026, 3, 12, 10, 0),
                  ),
                ],
                summary: const AdminManagementSummary(
                  totalCount: 1,
                  activeCount: 1,
                  inactiveCount: 0,
                  superAdminCount: 1,
                  opsAdminCount: 0,
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminManagementScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin management'), findsOneWidget);
    expect(find.text('Super Admin One'), findsOneWidget);
    expect(find.text('super@example.com'), findsOneWidget);
    expect(find.text('Admin id admin-1'), findsOneWidget);
    expect(find.text('Super admin • Active'), findsOneWidget);
    expect(find.text('Created in current admin identity table'), findsOneWidget);
    expect(find.text('Super admin'), findsOneWidget);
    expect(find.text('Created 2026-03-12 10:00'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
  });
}
