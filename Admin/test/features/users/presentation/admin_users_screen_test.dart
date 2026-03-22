import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/repositories/admin_user_repository.dart';
import 'package:admin/src/features/users/presentation/admin_users_screen.dart';
import 'package:admin/src/features/users/providers/admin_user_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminUsersController extends AdminUsersController {
  final AdminUsersState initialState;

  _FakeAdminUsersController(this.initialState);

  @override
  Future<AdminUsersState> build() async => initialState;
}

Widget _buildRoutedUsersApp({required AdminUsersState state}) {
  final router = GoRouter(
    initialLocation: AdminRoutes.usersPath,
    routes: [
      GoRoute(
        path: AdminRoutes.usersPath,
        builder: (context, state) => const Scaffold(body: AdminUsersScreen()),
      ),
      GoRoute(
        path: AdminRoutes.userDetailPath,
        builder: (context, state) => Scaffold(body: Text('User detail opened: ${state.pathParameters['userId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminUsersProvider.overrideWith(() => _FakeAdminUsersController(state)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('admin users screen renders search filters and user rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUsersProvider.overrideWith(
            () => _FakeAdminUsersController(
              AdminUsersState.initial().copyWith(
                items: [
                  AdminUserListItem(
                    id: 'user-1',
                    fullName: 'Supplier One',
                    mobile: '9999999999',
                    email: 'supplier@example.com',
                    role: 'supplier',
                    verificationStatus: 'approved',
                    isBanned: false,
                    banReason: '',
                    activityCount: 5,
                    createdAt: DateTime(2026, 3, 1, 9, 30),
                    lastLoginAt: DateTime(2026, 3, 12, 18, 45),
                  ),
                  AdminUserListItem(
                    id: 'user-2',
                    fullName: 'Trucker Two',
                    mobile: '8888888888',
                    email: 'trucker@example.com',
                    role: 'trucker',
                    verificationStatus: 'rejected',
                    isBanned: true,
                    banReason: 'Repeated fraud reports',
                    activityCount: 2,
                    createdAt: DateTime(2026, 2, 15, 8, 0),
                    lastLoginAt: DateTime(2026, 3, 5, 11, 10),
                  ),
                ],
                hasMore: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminUsersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('User management'), findsOneWidget);
    expect(find.text('Search users'), findsOneWidget);
    expect(find.text('Name, user id, mobile, email, role, or state'), findsOneWidget);
    expect(find.text('Suppliers'), findsOneWidget);
    expect(find.text('Supplier One'), findsOneWidget);
    expect(find.textContaining('Supplier • approved'), findsOneWidget);
    expect(find.text('User user-1'), findsOneWidget);
    expect(find.text('Joined 2026-03-01 09:30 • Last login 2026-03-12 18:45'), findsOneWidget);
    expect(find.text('Ban reason: Repeated fraud reports'), findsOneWidget);
  });

  testWidgets('admin users screen routes to user detail on tap', (tester) async {
    await tester.pumpWidget(
      _buildRoutedUsersApp(
        state: AdminUsersState.initial().copyWith(
          items: [
            AdminUserListItem(
              id: 'user-1',
              fullName: 'Supplier One',
              mobile: '9999999999',
              email: 'supplier@example.com',
              role: 'supplier',
              verificationStatus: 'approved',
              isBanned: false,
              banReason: '',
              activityCount: 5,
              createdAt: DateTime(2026, 3, 1, 9, 30),
              lastLoginAt: DateTime(2026, 3, 12, 18, 45),
            ),
          ],
          hasMore: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Supplier One'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Supplier One'));
    await tester.pumpAndSettle();

    expect(find.text('User detail opened: user-1'), findsOneWidget);
  });
}
