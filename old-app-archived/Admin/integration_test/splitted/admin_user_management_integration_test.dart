import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/core/repositories/admin_user_management_repository.dart';
import 'package:admin/src/features/users/presentation/user_list_screen.dart';
import 'package:admin/src/features/users/presentation/user_detail_screen.dart';
import 'package:admin/src/features/users/providers/user_detail_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin user management integration tests', () {
    testWidgets('A-USR-01: user list shell render', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: UserListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User management'), findsOneWidget);
      expect(find.text('All users'), findsOneWidget);
      expect(find.text('Suppliers only'), findsOneWidget);
      expect(find.text('Truckers only'), findsOneWidget);
      expect(find.text('Banned users'), findsOneWidget);
    });

    testWidgets('A-USR-02: user detail render', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            userDetailProvider('user-1').overrideWith(
              (ref) async => const AdminUserDetail(
                profile: AdminUserListItem(
                  id: 'user-1',
                  fullName: 'Test User 1',
                  mobile: '+919999999999',
                  email: 'test1@example.com',
                  role: 'trucker',
                  verificationStatus: 'verified',
                  isBanned: false,
                  banReason: '',
                  loadsCount: 1,
                ),
                roleMetadata: {
                  'DL Number': 'DL-123',
                  'Rating': '4.8',
                },
                documents: [
                  VerificationDocument(
                    label: 'DL Front',
                    url: 'https://example.com/dl-front.jpg',
                  ),
                ],
                recentItems: [
                  AdminRecentItem(
                    id: 'trip-1',
                    title: 'Mumbai → Pune',
                    status: 'completed',
                    createdAt: null,
                  ),
                ],
              ),
            ),
          ],
          child: const MaterialApp(home: UserDetailScreen(userId: 'user-1')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test User 1'), findsOneWidget);
      expect(find.text('test1@example.com'), findsOneWidget);
      expect(find.text('+919999999999'), findsOneWidget);
      expect(find.text('DL Number'), findsOneWidget);
      expect(find.text('DL-123'), findsOneWidget);
      expect(find.text('DL Front'), findsOneWidget);
      expect(find.text('Mumbai → Pune'), findsOneWidget);
    });
  });
}
