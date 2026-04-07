import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/core/repositories/admin_verification_repository.dart'
    as avr;
import 'package:admin/src/features/auth/presentation/admin_login_screen.dart';
import 'package:admin/src/features/auth/providers/admin_auth_provider.dart';
import 'package:admin/src/features/dashboard/presentation/admin_dashboard_screen.dart';
import 'package:admin/src/features/verification/providers/verification_detail_provider.dart';
import 'package:admin/src/features/verification/providers/verification_queue_provider.dart';
import 'package:admin/src/features/verification/presentation/verification_queue_screen.dart';
import 'package:admin/src/features/verification/presentation/verification_detail_screen.dart';
import 'package:admin/src/features/users/presentation/user_list_screen.dart';
import 'package:admin/src/features/users/presentation/user_detail_screen.dart';
import 'package:admin/src/features/users/providers/user_detail_provider.dart';
import 'package:admin/src/features/users/providers/user_list_provider.dart';
import 'package:admin/src/features/support/presentation/support_ticket_queue_screen.dart';
import 'package:admin/src/features/support/presentation/support_ticket_detail_screen.dart';
import 'package:admin/src/features/support/providers/support_queue_provider.dart';
import 'package:admin/src/features/support/providers/support_ticket_detail_provider.dart';
import 'package:admin/src/features/super_ops/presentation/super_ops_console_screen.dart';
import 'package:admin/src/features/super_ops/presentation/super_ops_load_detail_screen.dart';
import 'package:admin/src/features/super_ops/providers/super_ops_queue_provider.dart';
import 'package:admin/src/features/super_ops/providers/super_ops_detail_provider.dart';
import 'package:admin/src/features/admin_management/presentation/admin_management_screen.dart';
import 'package:admin/src/features/admin_management/providers/admin_management_provider.dart';
import 'package:admin/src/features/audit_logs/presentation/audit_logs_screen.dart';
import 'package:admin/src/features/audit_logs/providers/audit_logs_provider.dart';
import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:admin/src/core/repositories/splitted/super_ops_models.dart';
import 'package:admin/src/core/repositories/admin_user_management_repository.dart';
import 'package:admin/src/core/repositories/admin_management_repository.dart';
import 'package:admin/src/core/repositories/audit_logs_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin flow integration tests', () {
    testWidgets('5.1: Admin login to Dashboard renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: AdminLoginScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Admin Login'), findsOneWidget);
      expect(find.text('TranZfort Admin'), findsOneWidget);
    });

    testWidgets('5.2: Admin Dashboard renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('5.3: Admin Verification queue renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: VerificationQueueScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(VerificationQueueScreen), findsOneWidget);
    });

    testWidgets('A-VER-01: verification queue render with pending supplier item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationQueuesProvider.overrideWith(
              () => _FakeVerificationQueuesNotifier(_fixtureQueues()),
            ),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.supplier,
                'supplier-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureSupplierVerificationDetail()),
          ],
          child: MaterialApp.router(routerConfig: _buildVerificationRouter()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Verification Queues'), findsOneWidget);
      expect(find.text('Fixture Supplier Queue Item'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
    });

    testWidgets('A-VER-02: open supplier verification case from queue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationQueuesProvider.overrideWith(
              () => _FakeVerificationQueuesNotifier(_fixtureQueues()),
            ),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.supplier,
                'supplier-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureSupplierVerificationDetail()),
          ],
          child: MaterialApp.router(routerConfig: _buildVerificationRouter()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('Fixture Supplier Queue Item'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Verify Supplier'), findsOneWidget);
      expect(find.text('Profile Information'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('A-VER-02A: admin can preview uploaded supplier document', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.supplier,
                'supplier-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureSupplierVerificationDetail()),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: avr.VerificationEntityType.supplier,
              id: 'supplier-queue-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));
      expect(find.text('Verify Supplier'), findsOneWidget);
      expect(find.text('Aadhaar Front'), findsOneWidget);
      await tester.ensureVisible(find.text('Aadhaar Front'));
      await tester.tap(find.text('Aadhaar Front'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('A-VER-02B: missing document URL shows safe fallback state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.supplier,
                'supplier-queue-1',
              ),
            ).overrideWith(
              (ref) async => _fixtureSupplierVerificationDetailMissingDocUrl(),
            ),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: avr.VerificationEntityType.supplier,
              id: 'supplier-queue-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Aadhaar Front'), findsOneWidget);
      expect(find.text('Not uploaded'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('A-VER-03: approve supplier verification', (
      WidgetTester tester,
    ) async {
      final capture = _VerificationActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationActionProvider.overrideWith(
              (ref) => _FakeVerificationActionNotifier(ref, capture),
            ),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.supplier,
                'supplier-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureSupplierVerificationDetail()),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: avr.VerificationEntityType.supplier,
              id: 'supplier-queue-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      final approveButton = find.widgetWithText(FilledButton, 'Approve');
      final approveWidget = tester.widget<FilledButton>(approveButton);
      approveWidget.onPressed?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.approveCalled, isTrue);
      expect(capture.approveType, avr.VerificationEntityType.supplier);
      expect(capture.approveId, 'supplier-queue-1');
    });

    testWidgets('A-VER-04: reject supplier verification with reason', (
      WidgetTester tester,
    ) async {
      final capture = _VerificationActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationActionProvider.overrideWith(
              (ref) => _FakeVerificationActionNotifier(ref, capture),
            ),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.supplier,
                'supplier-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureSupplierVerificationDetail()),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: avr.VerificationEntityType.supplier,
              id: 'supplier-queue-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.enterText(
        find.byType(TextField),
        'Aadhaar image is unclear, please re-upload.',
      );
      final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');
      final rejectWidget = tester.widget<OutlinedButton>(rejectButton);
      rejectWidget.onPressed?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.rejectCalled, isTrue);
      expect(capture.rejectType, avr.VerificationEntityType.supplier);
      expect(capture.rejectId, 'supplier-queue-1');
      expect(capture.rejectReason, 'Aadhaar image is unclear, please re-upload.');
    });

    testWidgets('A-VER-05: open trucker verification case from queue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationQueuesProvider.overrideWith(
              () => _FakeVerificationQueuesNotifier(_fixtureQueues()),
            ),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.trucker,
                'trucker-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureTruckerVerificationDetail()),
          ],
          child: MaterialApp.router(routerConfig: _buildVerificationRouter()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.textContaining('Truckers'));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.tap(find.text('Fixture Trucker Queue Item'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Verify Trucker'), findsOneWidget);
      expect(find.text('DL Front'), findsOneWidget);
    });

    testWidgets('A-VER-05A: admin can preview uploaded trucker document', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.trucker,
                'trucker-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureTruckerVerificationDetail()),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: avr.VerificationEntityType.trucker,
              id: 'trucker-queue-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('DL Front'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('A-VER-06: approve/reject trucker case', (
      WidgetTester tester,
    ) async {
      final capture = _VerificationActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationActionProvider.overrideWith(
              (ref) => _FakeVerificationActionNotifier(ref, capture),
            ),
            verificationDetailProvider(
              const VerificationDetailArgs(
                avr.VerificationEntityType.trucker,
                'trucker-queue-1',
              ),
            ).overrideWith((ref) async => _fixtureTruckerVerificationDetail()),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: avr.VerificationEntityType.trucker,
              id: 'trucker-queue-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      final approveButton = find.widgetWithText(FilledButton, 'Approve');
      expect(approveButton, findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'DL photo is unclear, please re-upload.',
      );
      final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');
      tester.widget<OutlinedButton>(rejectButton).onPressed?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(capture.rejectCalled, isTrue);
      expect(capture.rejectType, avr.VerificationEntityType.trucker);
      expect(capture.rejectId, 'trucker-queue-1');
      expect(capture.rejectReason, 'DL photo is unclear, please re-upload.');
    });

    testWidgets('5.4: Admin User list renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: UserListScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(UserListScreen), findsOneWidget);
    });

    testWidgets('A-USR-01: user list render/filter/search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            userListProvider.overrideWith(
              (ref, query) async => _fixtureUsersForQuery(query),
            ),
          ],
          child: const MaterialApp(home: UserListScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('User Management'), findsAtLeastNWidgets(1));
      expect(find.text('Search by name, mobile, or email'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Banned'), findsOneWidget);
      expect(find.text('Fixture Supplier User'), findsOneWidget);
      expect(find.text('Fixture Banned Trucker'), findsOneWidget);

      await tester.tap(find.text('Banned'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.text('Fixture Banned Trucker'), findsOneWidget);
      expect(find.text('Fixture Supplier User'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await tester.enterText(
        find.byType(TextField),
        'fixture supplier',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.text('Fixture Supplier User'), findsOneWidget);
      expect(find.text('Fixture Banned Trucker'), findsNothing);
    });

    testWidgets('A-USR-02: user detail render', (WidgetTester tester) async {
      const userId = 'user-1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            userDetailProvider(
              userId,
            ).overrideWith((ref) async => _fixtureUserDetail()),
          ],
          child: const MaterialApp(home: UserDetailScreen(userId: userId)),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('User Detail'), findsOneWidget);
      expect(find.text('Fixture User'), findsOneWidget);
      expect(find.text('Role-specific Information'), findsOneWidget);
      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('A-USR-03: ban action with mandatory reason', (
      WidgetTester tester,
    ) async {
      const userId = 'user-1';
      final capture = _UserActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            userActionProvider.overrideWith(
              (ref) => _FakeUserActionNotifier(ref, capture),
            ),
            userDetailProvider(
              userId,
            ).overrideWith((ref) async => _fixtureUserDetail()),
          ],
          child: const MaterialApp(home: UserDetailScreen(userId: userId)),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.enterText(find.byType(TextField), 'short');
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Ban User'))
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('Ban reason must be at least 10 characters.'), findsOneWidget);
      expect(capture.called, isFalse);
    });

    testWidgets('A-USR-04: unban action', (WidgetTester tester) async {
      const userId = 'user-banned-1';
      final capture = _UserActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            userActionProvider.overrideWith(
              (ref) => _FakeUserActionNotifier(ref, capture),
            ),
            userDetailProvider(
              userId,
            ).overrideWith((ref) async => _fixtureBannedUserDetail()),
          ],
          child: const MaterialApp(home: UserDetailScreen(userId: userId)),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.enterText(
        find.byType(TextField),
        'Issue resolved after review.',
      );
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unban User'))
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.called, isTrue);
      expect(capture.userId, 'user-banned-1');
      expect(capture.banned, isFalse);
      expect(capture.reason, 'Issue resolved after review.');
    });

    testWidgets('5.5: Admin Support queue renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: SupportTicketQueueScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SupportTicketQueueScreen), findsOneWidget);
    });

    testWidgets('A-SUP-01: ticket queue render', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            supportTicketCountsProvider.overrideWith(
              (ref) async => const SupportTicketCounts(
                open: 1,
                inProgress: 1,
                resolved: 1,
              ),
            ),
            supportQueueProvider.overrideWith(
              (ref, query) async => _fixtureSupportQueueForQuery(query),
            ),
          ],
          child: const MaterialApp(home: SupportTicketQueueScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Support Tickets'), findsOneWidget);
      expect(find.text('Support Control Center'), findsOneWidget);
      expect(find.text('Fixture Support Ticket 1'), findsOneWidget);
    });

    testWidgets('A-SUP-02: assign ticket', (WidgetTester tester) async {
      const ticketId = 'ticket-1';
      final capture = _SupportActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            supportTicketActionProvider.overrideWith(
              (ref) => _FakeSupportTicketActionNotifier(ref, capture),
            ),
            supportTicketDetailProvider(
              ticketId,
            ).overrideWith((ref) async => _fixtureSupportTicketDetail()),
          ],
          child: const MaterialApp(
            home: SupportTicketDetailScreen(ticketId: ticketId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.scrollUntilVisible(
        find.text('Assign to Me'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Assign to Me'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.assignTicketId, ticketId);
    });

    testWidgets('A-SUP-03: reply ticket', (WidgetTester tester) async {
      const ticketId = 'ticket-1';
      final capture = _SupportActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            supportTicketActionProvider.overrideWith(
              (ref) => _FakeSupportTicketActionNotifier(ref, capture),
            ),
            supportTicketDetailProvider(
              ticketId,
            ).overrideWith((ref) async => _fixtureSupportTicketDetail()),
          ],
          child: const MaterialApp(
            home: SupportTicketDetailScreen(ticketId: ticketId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.scrollUntilVisible(
        find.text('Send Reply'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Type a reply for the user',
        ),
        'We are reviewing this issue now.',
      );
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send Reply'))
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.replyTicketId, ticketId);
      expect(capture.replyText, 'We are reviewing this issue now.');
    });

    testWidgets('A-SUP-04: resolve/close ticket', (WidgetTester tester) async {
      const ticketId = 'ticket-1';
      final capture = _SupportActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            supportTicketActionProvider.overrideWith(
              (ref) => _FakeSupportTicketActionNotifier(ref, capture),
            ),
            supportTicketDetailProvider(
              ticketId,
            ).overrideWith((ref) async => _fixtureSupportTicketDetail()),
          ],
          child: const MaterialApp(
            home: SupportTicketDetailScreen(ticketId: ticketId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.scrollUntilVisible(
        find.text('Mark Resolved'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText ==
                  'Resolution notes (required to mark resolved)',
        ),
        'Issue resolved after validating account state.',
      );
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Mark Resolved'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.resolveTicketId, ticketId);
      expect(
        capture.resolveNotes,
        'Issue resolved after validating account state.',
      );
    });

    testWidgets('A-SUP-05: priority update path', (WidgetTester tester) async {
      const ticketId = 'ticket-1';
      final capture = _SupportActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            supportTicketActionProvider.overrideWith(
              (ref) => _FakeSupportTicketActionNotifier(ref, capture),
            ),
            supportTicketDetailProvider(
              ticketId,
            ).overrideWith((ref) async => _fixtureSupportTicketDetail()),
          ],
          child: const MaterialApp(
            home: SupportTicketDetailScreen(ticketId: ticketId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.scrollUntilVisible(
        find.text('Mark Resolved'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final priorityDropdown =
          find.byType(DropdownButtonFormField<SupportTicketPriority>).first;
      tester
          .widget<DropdownButtonFormField<SupportTicketPriority>>(
            priorityDropdown,
          )
          .onChanged
          ?.call(SupportTicketPriority.high);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.priorityTicketId, ticketId);
      expect(capture.priority, SupportTicketPriority.high);
    });

    testWidgets('5.6: Admin Super Ops console renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: SuperOpsConsoleScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SuperOpsConsoleScreen), findsOneWidget);
    });

    testWidgets('A-SOPS-01: super-ops queue render', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsQueueCountsProvider.overrideWith(
              (ref) async => const SuperOpsQueueCounts(requests: 1),
            ),
            superOpsQueueProvider.overrideWith(
              (ref, query) async => _fixtureSuperOpsQueueForQuery(query),
            ),
          ],
          child: const MaterialApp(home: SuperOpsConsoleScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Super Ops Console'), findsAtLeastNWidgets(1));
      expect(find.text('Super Load Operations'), findsOneWidget);
      expect(find.text('Requests (1)'), findsOneWidget);
      expect(find.text('Fixture Route -> Destination'), findsOneWidget);
    });

    testWidgets('A-SOPS-02: accept request', (WidgetTester tester) async {
      const loadId = 'load-1';
      final capture = _SuperOpsActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsActionProvider.overrideWith(
              (ref) => _FakeSuperOpsActionNotifier(ref, capture),
            ),
            superOpsDispatchCandidatesProvider.overrideWith(
              (ref, query) async => const [],
            ),
            superOpsLoadDetailProvider(
              loadId,
            ).overrideWith((ref) async => _fixtureSuperOpsLoadDetail()),
          ],
          child: const MaterialApp(
            home: SuperOpsLoadDetailScreen(loadId: loadId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.scrollUntilVisible(
        find.text('Accept Request'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Accept Request'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.acceptLoadId, loadId);
    });

    testWidgets('A-SOPS-03: force assign request', (WidgetTester tester) async {
      const loadId = 'load-2'; // Requires processing state
      final capture = _SuperOpsActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsActionProvider.overrideWith(
              (ref) => _FakeSuperOpsActionNotifier(ref, capture),
            ),
            superOpsDispatchCandidatesProvider.overrideWith(
              (ref, query) async => _fixtureDispatchCandidates(),
            ),
            superOpsLoadDetailProvider(
              loadId,
            ).overrideWith((ref) async => _fixtureSuperOpsLoadDetailProcessing()),
          ],
          child: const MaterialApp(
            home: SuperOpsLoadDetailScreen(loadId: loadId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      
      // Select trucker
      await tester.scrollUntilVisible(
        find.textContaining('Fixture Candidate'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final truckerRadio = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(Icons.radio_button_unchecked),
      ).first;
      tester.widget<IconButton>(find.ancestor(of: truckerRadio, matching: find.byType(IconButton)).first).onPressed?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Select truck
      final truckRadio = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(Icons.radio_button_unchecked),
      ).last;
      tester.widget<IconButton>(find.ancestor(of: truckRadio, matching: find.byType(IconButton)).first).onPressed?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Force Assign
      await tester.scrollUntilVisible(
        find.text('Force Assign'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Force Assign'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.forceAssignLoadId, loadId);
      expect(capture.forceAssignTruckerId, 'trucker-candidate-1');
      expect(capture.forceAssignTruckId, 'truck-1');
    });

    testWidgets('A-SOPS-04: payout confirmation path', (WidgetTester tester) async {
      const loadId = 'load-3'; // Requires pod_uploaded state
      final capture = _SuperOpsActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsActionProvider.overrideWith(
              (ref) => _FakeSuperOpsActionNotifier(ref, capture),
            ),
            superOpsDispatchCandidatesProvider.overrideWith(
              (ref, query) async => const [],
            ),
            superOpsLoadDetailProvider(
              loadId,
            ).overrideWith((ref) async => _fixtureSuperOpsLoadDetailPod()),
          ],
          child: const MaterialApp(
            home: SuperOpsLoadDetailScreen(loadId: loadId),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.scrollUntilVisible(
        find.text('Confirm & Mark Payout'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirm & Mark Payout'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.confirmPayoutLoadId, loadId);
    });

    testWidgets('A-MGMT-01: admin management screen render', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            adminAccountsProvider.overrideWith(
              (ref) async => _fixtureAdminAccounts(),
            ),
          ],
          child: const MaterialApp(home: AdminManagementScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Admin Management'), findsAtLeastNWidgets(1));
      expect(find.text('Invite New Admin'), findsOneWidget);
      expect(find.text('Fixture Admin 1'), findsOneWidget);
      expect(find.text('Fixture Admin 2'), findsOneWidget);
    });

    testWidgets('A-MGMT-02: invite admin', (WidgetTester tester) async {
      final capture = _AdminManagementActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            adminManagementActionProvider.overrideWith(
              (ref) => _FakeAdminManagementActionNotifier(ref, capture),
            ),
            adminAccountsProvider.overrideWith(
              (ref) async => const [],
            ),
          ],
          child: const MaterialApp(home: AdminManagementScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Full Name',
        ),
        'New Agent',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Email',
        ),
        'new.agent@example.com',
      );

      final dropdown = find.byType(DropdownButtonFormField<AdminRole>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.tap(find.text('Support Agent').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      await tester.scrollUntilVisible(
        find.text('Invite Admin'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Invite Admin'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.inviteFullName, 'New Agent');
      expect(capture.inviteEmail, 'new.agent@example.com');
      expect(capture.inviteRole, AdminRole.supportAgent);
    });

    testWidgets('A-MGMT-03: activate/deactivate admin', (WidgetTester tester) async {
      final capture = _AdminManagementActionCapture();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            adminManagementActionProvider.overrideWith(
              (ref) => _FakeAdminManagementActionNotifier(ref, capture),
            ),
            adminAccountsProvider.overrideWith(
              (ref) async => _fixtureAdminAccounts(),
            ),
          ],
          child: const MaterialApp(home: AdminManagementScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      
      final switchWidget = find.byType(Switch).first;
      tester.widget<Switch>(switchWidget).onChanged?.call(false);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(capture.targetAdminId, 'admin-1');
      expect(capture.targetActiveState, isFalse);
    });

    testWidgets('A-AUD-01/02: audit logs render and filter', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            auditLogsProvider.overrideWith(
              (ref, query) async => _fixtureAuditLogsForQuery(query),
            ),
          ],
          child: const MaterialApp(home: AuditLogsScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Audit Logs'), findsAtLeastNWidgets(1));
      expect(find.text('Security & Change History'), findsOneWidget);
      expect(find.text('assign_ticket • support_ticket'), findsOneWidget);
      expect(find.text('ban_user • profile'), findsOneWidget);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Action',
        ),
        'ban',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('ban_user • profile'), findsOneWidget);
      expect(find.text('assign_ticket • support_ticket'), findsNothing);
    });

    testWidgets('5.7: Support Agent sees read-only user detail', (
      WidgetTester tester,
    ) async {
      const userId = 'user-1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-support',
                authUserId: 'auth-support',
                fullName: 'Support Agent',
                email: 'support@example.com',
                role: AdminRole.supportAgent,
                isActive: true,
              ),
            ),
            userDetailProvider(
              userId,
            ).overrideWith((ref) async => _fixtureUserDetail()),
          ],
          child: const MaterialApp(home: UserDetailScreen(userId: userId)),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.text(
          'Read-only mode: Support Agent can review user profile and documents only.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ban User'), findsNothing);
      expect(find.text('Unban User'), findsNothing);
    });

    testWidgets('5.8: Super Admin can access user mutation controls', (
      WidgetTester tester,
    ) async {
      const userId = 'user-1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            currentAdminAccessProvider.overrideWith(
              (ref) async => const AdminAccessUser(
                id: 'admin-super',
                authUserId: 'auth-super',
                fullName: 'Super Admin',
                email: 'super@example.com',
                role: AdminRole.superAdmin,
                isActive: true,
              ),
            ),
            userDetailProvider(
              userId,
            ).overrideWith((ref) async => _fixtureUserDetail()),
          ],
          child: const MaterialApp(home: UserDetailScreen(userId: userId)),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Ban User'), findsOneWidget);
      expect(
        find.text('Mandatory ban reason (min 10 characters)'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Read-only mode: Support Agent can review user profile and documents only.',
        ),
        findsNothing,
      );
    });
  });
}

class _FakeVerificationQueuesNotifier extends VerificationQueuesNotifier {
  _FakeVerificationQueuesNotifier(this._queues);

  final avr.VerificationQueues _queues;

  @override
  Future<avr.VerificationQueues> build() async {
    return _queues;
  }
}

class _SupportActionCapture {
  String? assignTicketId;
  String? replyTicketId;
  String? replyText;
  String? resolveTicketId;
  String? resolveNotes;
  String? priorityTicketId;
  SupportTicketPriority? priority;
}

class _FakeSupportTicketActionNotifier extends SupportTicketActionNotifier {
  _FakeSupportTicketActionNotifier(this._ref, this._capture) : super(_ref);

  final Ref _ref;
  final _SupportActionCapture _capture;

  @override
  Future<bool> assignToMe(String ticketId) async {
    state = const AsyncLoading();
    _capture.assignTicketId = ticketId;
    _refresh(ticketId);
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> changePriority({
    required String ticketId,
    required SupportTicketPriority priority,
  }) async {
    state = const AsyncLoading();
    _capture.priorityTicketId = ticketId;
    _capture.priority = priority;
    _refresh(ticketId);
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> sendReply({
    required String ticketId,
    required String text,
  }) async {
    state = const AsyncLoading();
    _capture.replyTicketId = ticketId;
    _capture.replyText = text;
    _refresh(ticketId);
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> resolveTicket({
    required String ticketId,
    required String notes,
  }) async {
    state = const AsyncLoading();
    _capture.resolveTicketId = ticketId;
    _capture.resolveNotes = notes;
    _refresh(ticketId);
    state = const AsyncData(null);
    return true;
  }

  void _refresh(String ticketId) {
    _ref.invalidate(supportTicketCountsProvider);
    for (final status in SupportTicketStatus.values) {
      _ref.invalidate(
        supportQueueProvider(SupportTicketQueueQuery(status: status, search: '')),
      );
    }
    _ref.invalidate(supportTicketDetailProvider(ticketId));
  }
}

class _SuperOpsActionCapture {
  String? acceptLoadId;
  String? forceAssignLoadId;
  String? forceAssignTruckerId;
  String? forceAssignTruckId;
  String? confirmPayoutLoadId;
}

class _FakeSuperOpsActionNotifier extends SuperOpsActionNotifier {
  _FakeSuperOpsActionNotifier(super.ref, this._capture);

  final _SuperOpsActionCapture _capture;

  @override
  Future<bool> acceptRequest(String loadId) async {
    state = const AsyncLoading();
    _capture.acceptLoadId = loadId;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> forceAssign({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) async {
    state = const AsyncLoading();
    _capture.forceAssignLoadId = loadId;
    _capture.forceAssignTruckerId = truckerId;
    _capture.forceAssignTruckId = truckId;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> confirmPayout(String loadId) async {
    state = const AsyncLoading();
    _capture.confirmPayoutLoadId = loadId;
    state = const AsyncData(null);
    return true;
  }
}

class _UserActionCapture {
  bool called = false;
  String? userId;
  bool? banned;
  String? reason;
}

class _FakeUserActionNotifier extends UserActionNotifier {
  _FakeUserActionNotifier(this._ref, this._capture) : super(_ref);

  final Ref _ref;
  final _UserActionCapture _capture;

  @override
  Future<bool> setBanStatus({
    required String userId,
    required bool banned,
    String? reason,
  }) async {
    state = const AsyncLoading();
    _capture.called = true;
    _capture.userId = userId;
    _capture.banned = banned;
    _capture.reason = reason;
    _ref.invalidate(userDetailProvider(userId));
    _ref.invalidate(userListProvider);
    state = const AsyncData(null);
    return true;
  }
}

class _VerificationActionCapture {
  bool approveCalled = false;
  avr.VerificationEntityType? approveType;
  String? approveId;

  bool rejectCalled = false;
  avr.VerificationEntityType? rejectType;
  String? rejectId;
  String? rejectReason;
}

class _FakeVerificationActionNotifier extends VerificationActionNotifier {
  _FakeVerificationActionNotifier(this._ref, this._capture) : super(_ref);

  final Ref _ref;
  final _VerificationActionCapture _capture;

  @override
  Future<bool> approve({
    required avr.VerificationEntityType type,
    required String id,
  }) async {
    state = const AsyncLoading();
    _capture.approveCalled = true;
    _capture.approveType = type;
    _capture.approveId = id;
    _ref.invalidate(verificationQueuesProvider);
    _ref.invalidate(verificationDetailProvider(VerificationDetailArgs(type, id)));
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> reject({
    required avr.VerificationEntityType type,
    required String id,
    required String reason,
    List<String> reasonCodes = const [],
  }) async {
    state = const AsyncLoading();
    _capture.rejectCalled = true;
    _capture.rejectType = type;
    _capture.rejectId = id;
    _capture.rejectReason = reason;
    _ref.invalidate(verificationQueuesProvider);
    _ref.invalidate(verificationDetailProvider(VerificationDetailArgs(type, id)));
    state = const AsyncData(null);
    return true;
  }
}

class _AdminManagementActionCapture {
  String? inviteFullName;
  String? inviteEmail;
  AdminRole? inviteRole;
  
  String? targetAdminId;
  bool? targetActiveState;
}

class _FakeAdminManagementActionNotifier extends AdminManagementActionNotifier {
  _FakeAdminManagementActionNotifier(this._ref, this._capture) : super(_ref);

  final Ref _ref;
  final _AdminManagementActionCapture _capture;

  @override
  Future<AdminInviteResult> inviteAdmin({
    required String fullName,
    required String email,
    required AdminRole role,
  }) async {
    state = const AsyncLoading();
    _capture.inviteFullName = fullName;
    _capture.inviteEmail = email;
    _capture.inviteRole = role;
    _ref.invalidate(adminAccountsProvider);
    state = const AsyncData(null);
    return const AdminInviteResult(ok: true, message: 'ok');
  }

  @override
  Future<AdminActionResult> setAdminActive({
    required String adminId,
    required bool isActive,
  }) async {
    state = const AsyncLoading();
    _capture.targetAdminId = adminId;
    _capture.targetActiveState = isActive;
    _ref.invalidate(adminAccountsProvider);
    state = const AsyncData(null);
    return const AdminActionResult(ok: true, message: 'ok');
  }
}

GoRouter _buildVerificationRouter() {
  return GoRouter(
    initialLocation: '/verifications',
    routes: [
      GoRoute(
        path: '/verifications',
        builder: (context, state) => const VerificationQueueScreen(),
      ),
      GoRoute(
        path: '/verification/:type/:id',
        builder: (context, state) {
          final typePath = state.pathParameters['type'] ?? '';
          final type = avr.verificationTypeFromPath(typePath);
          final id = state.pathParameters['id'] ?? '';
          if (type == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid verification route.')),
            );
          }

          return VerificationDetailScreen(type: type, id: id);
        },
      ),
    ],
  );
}

List<SupportTicketListItem> _fixtureSupportQueueForQuery(
  SupportTicketQueueQuery query,
) {
  final all = <SupportTicketListItem>[
    SupportTicketListItem(
      id: 'ticket-1',
      subject: 'Fixture Support Ticket 1',
      userName: 'Fixture User',
      priority: SupportTicketPriority.medium,
      status: SupportTicketStatus.open,
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 4)),
      assignedAdminId: '',
      assignedAdminName: '',
    ),
    SupportTicketListItem(
      id: 'ticket-2',
      subject: 'Fixture In Progress Ticket',
      userName: 'Fixture Supplier User',
      priority: SupportTicketPriority.high,
      status: SupportTicketStatus.inProgress,
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      assignedAdminId: 'admin-2',
      assignedAdminName: 'Admin Ops',
    ),
    SupportTicketListItem(
      id: 'ticket-3',
      subject: 'Fixture Resolved Ticket',
      userName: 'Fixture Banned Trucker',
      priority: SupportTicketPriority.low,
      status: SupportTicketStatus.resolved,
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      assignedAdminId: 'admin-3',
      assignedAdminName: 'Admin Support',
    ),
  ];

  final byStatus = all.where((ticket) => ticket.status == query.status);
  final search = query.search.trim().toLowerCase();
  if (search.isEmpty) return byStatus.toList();
  return byStatus.where((ticket) {
    final haystack = '${ticket.id} ${ticket.subject} ${ticket.userName}'.toLowerCase();
    return haystack.contains(search);
  }).toList();
}

SupportTicketDetail _fixtureSupportTicketDetail() {
  return SupportTicketDetail(
    ticket: SupportTicketListItem(
      id: 'ticket-1',
      subject: 'Fixture Support Ticket 1',
      userName: 'Fixture User (trucker)',
      priority: SupportTicketPriority.medium,
      status: SupportTicketStatus.open,
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 4)),
      assignedAdminId: '',
      assignedAdminName: '',
    ),
    description: 'Unable to update trip stage from in_transit.',
    category: 'trip',
    userMobile: '9000000000',
    userEmail: 'fixture.user@example.com',
    userRole: 'trucker',
    resolutionNotes: '',
    resolvedAt: null,
    messages: [
      SupportTicketMessage(
        id: 'message-1',
        senderRole: 'user',
        senderName: 'Fixture User',
        content: 'App shows an error when I mark delivered.',
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
      ),
    ],
  );
}

List<SuperOpsLoadSummary> _fixtureSuperOpsQueueForQuery(SuperOpsQueueQuery query) {
  if (query.tab != SuperOpsTab.requests) return const [];
  return [
    SuperOpsLoadSummary(
      id: 'load-1',
      routeLabel: 'Fixture Route -> Destination',
      material: 'Coal',
      weightTonnes: 20,
      price: 25000,
      requiredTruckType: 'open',
      trucksNeeded: 2,
      trucksBooked: 0,
      supplierName: 'Fixture Supplier',
      status: 'active',
      superStatus: 'requested',
      pickupDate: DateTime.now().toUtc().add(const Duration(days: 1)),
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    ),
  ];
}

SuperOpsLoadDetail _fixtureSuperOpsLoadDetail() {
  return SuperOpsLoadDetail(
    id: 'load-1',
    routeLabel: 'Fixture Route -> Destination',
    originLat: null,
    originLng: null,
    material: 'Coal',
    weightTonnes: 20,
    price: 25000,
    priceType: 'fixed',
    advancePercentage: 10,
    pickupDate: DateTime.now().toUtc().add(const Duration(days: 1)),
    requiredTruckType: 'open',
    requiredTyres: [],
    trucksNeeded: 2,
    trucksBooked: 0,
    status: 'active',
    superStatus: 'requested',
    podPhotoUrl: '',
    lrPhotoUrl: '',
    createdAt: DateTime.now().toUtc(),
    supplier: const SuperOpsSupplierInfo(
      id: 'supp-1',
      fullName: 'Fixture Supplier',
      companyName: 'Fixture Co',
      mobile: '9000000000',
      email: 'supp@test.com',
      verificationStatus: 'approved',
      gstNumber: 'GST123',
    ),
    payout: const SuperOpsPayoutInfo(
      accountHolderName: 'Fixture Holder',
      bankName: 'Test Bank',
      accountNumberLast4: '1234',
      ifscCode: 'TEST0001',
      status: 'verified',
    ),
    assignments: [],
  );
}

SuperOpsLoadDetail _fixtureSuperOpsLoadDetailProcessing() {
  final detail = _fixtureSuperOpsLoadDetail();
  return SuperOpsLoadDetail(
    id: 'load-2',
    routeLabel: detail.routeLabel,
    originLat: detail.originLat,
    originLng: detail.originLng,
    material: detail.material,
    weightTonnes: detail.weightTonnes,
    price: detail.price,
    priceType: detail.priceType,
    advancePercentage: detail.advancePercentage,
    pickupDate: detail.pickupDate,
    requiredTruckType: detail.requiredTruckType,
    requiredTyres: detail.requiredTyres,
    trucksNeeded: detail.trucksNeeded,
    trucksBooked: detail.trucksBooked,
    status: detail.status,
    superStatus: 'processing',
    podPhotoUrl: detail.podPhotoUrl,
    lrPhotoUrl: detail.lrPhotoUrl,
    createdAt: detail.createdAt,
    supplier: detail.supplier,
    payout: detail.payout,
    assignments: detail.assignments,
  );
}

SuperOpsLoadDetail _fixtureSuperOpsLoadDetailPod() {
  final detail = _fixtureSuperOpsLoadDetail();
  return SuperOpsLoadDetail(
    id: 'load-3',
    routeLabel: detail.routeLabel,
    originLat: detail.originLat,
    originLng: detail.originLng,
    material: detail.material,
    weightTonnes: detail.weightTonnes,
    price: detail.price,
    priceType: detail.priceType,
    advancePercentage: detail.advancePercentage,
    pickupDate: detail.pickupDate,
    requiredTruckType: detail.requiredTruckType,
    requiredTyres: detail.requiredTyres,
    trucksNeeded: detail.trucksNeeded,
    trucksBooked: detail.trucksBooked,
    status: detail.status,
    superStatus: 'pod_uploaded',
    podPhotoUrl: 'https://example.com/pod.png',
    lrPhotoUrl: '',
    createdAt: detail.createdAt,
    supplier: detail.supplier,
    payout: detail.payout,
    assignments: detail.assignments,
  );
}

List<DispatchTruckerCandidate> _fixtureDispatchCandidates() {
  return [
    const DispatchTruckerCandidate(
      truckerId: 'trucker-candidate-1',
      truckerName: 'Fixture Candidate Trucker',
      mobile: '9800000000',
      rating: 4.8,
      completedTrips: 12,
      superTruckerStatus: 'gold',
      lastKnownLat: null,
      lastKnownLng: null,
      isFallbackMatch: false,
      distanceKm: null,
      trucks: [
        DispatchTruckOption(
          id: 'truck-1',
          truckNumber: 'MH01AB1234',
          bodyType: 'open',
          tyres: 6,
        ),
      ],
    ),
  ];
}

List<AdminAccountItem> _fixtureAdminAccounts() {
  return [
    AdminAccountItem(
      id: 'admin-1',
      authUserId: 'auth-1',
      fullName: 'Fixture Admin 1',
      email: 'admin1@example.com',
      role: AdminRole.superAdmin,
      isActive: true,
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
    ),
    AdminAccountItem(
      id: 'admin-2',
      authUserId: 'auth-2',
      fullName: 'Fixture Admin 2',
      email: 'admin2@example.com',
      role: AdminRole.opsAdmin,
      isActive: false,
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 15)),
    ),
  ];
}

List<AuditLogEntry> _fixtureAuditLogsForQuery(AuditLogQuery query) {
  final all = [
    AuditLogEntry(
      id: 'log-1',
      adminId: 'admin-1',
      adminName: 'Super Admin',
      action: 'assign_ticket',
      entityType: 'support_ticket',
      entityId: 'ticket-1',
      metadata: const {'assigned_to': 'admin-2'},
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    ),
    AuditLogEntry(
      id: 'log-2',
      adminId: 'admin-2',
      adminName: 'Ops Admin',
      action: 'ban_user',
      entityType: 'profile',
      entityId: 'user-banned-1',
      metadata: const {'reason': 'Policy violation'},
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    ),
  ];

  return all.where((log) {
    if (query.action.isNotEmpty && !log.action.toLowerCase().contains(query.action.toLowerCase())) {
      return false;
    }
    if (query.entityType.isNotEmpty && !log.entityType.toLowerCase().contains(query.entityType.toLowerCase())) {
      return false;
    }
    if (query.keyword.isNotEmpty) {
      final kw = query.keyword.toLowerCase();
      final haystack = '${log.adminName} ${log.action} ${log.entityType} ${log.entityId} ${log.metadata}'.toLowerCase();
      if (!haystack.contains(kw)) return false;
    }
    return true;
  }).toList();
}

AdminUserDetail _fixtureBannedUserDetail() {
  return const AdminUserDetail(
    profile: AdminUserListItem(
      id: 'user-banned-1',
      fullName: 'Fixture Banned Trucker',
      mobile: '9000000002',
      email: 'fixture.banned.trucker@example.com',
      role: 'trucker',
      verificationStatus: 'pending',
      isBanned: true,
      banReason: 'Policy violation',
      loadsCount: 1,
    ),
    roleMetadata: {'DL Number': 'DL-98765'},
    documents: [
      VerificationDocument(label: 'Aadhaar Front', url: ''),
      VerificationDocument(label: 'DL Front', url: ''),
    ],
    recentItems: [
      AdminRecentItem(
        id: 'trip-2',
        title: 'Trip trip-2',
        status: 'pending',
        createdAt: null,
      ),
    ],
  );
}

List<AdminUserListItem> _fixtureUsersForQuery(UserListQuery query) {
  final all = <AdminUserListItem>[
    const AdminUserListItem(
      id: 'user-1',
      fullName: 'Fixture Supplier User',
      mobile: '9000000001',
      email: 'fixture.supplier.user@example.com',
      role: 'supplier',
      verificationStatus: 'approved',
      isBanned: false,
      banReason: '',
      loadsCount: 3,
    ),
    const AdminUserListItem(
      id: 'user-banned-1',
      fullName: 'Fixture Banned Trucker',
      mobile: '9000000002',
      email: 'fixture.banned.trucker@example.com',
      role: 'trucker',
      verificationStatus: 'pending',
      isBanned: true,
      banReason: 'Policy violation',
      loadsCount: 1,
    ),
  ];

  final byFilter = all.where((user) {
    switch (query.filter) {
      case UserFilter.all:
        return true;
      case UserFilter.supplier:
        return user.role == 'supplier';
      case UserFilter.trucker:
        return user.role == 'trucker';
      case UserFilter.banned:
        return user.isBanned;
    }
  });

  final search = query.search.trim().toLowerCase();
  if (search.isEmpty) return byFilter.toList();

  return byFilter.where((user) {
    final haystack = '${user.fullName} ${user.mobile} ${user.email}'.toLowerCase();
    return haystack.contains(search);
  }).toList();
}

avr.VerificationQueues _fixtureQueues() {
  return avr.VerificationQueues(
    suppliers: [
      avr.VerificationQueueItem(
        id: 'supplier-queue-1',
        type: avr.VerificationEntityType.supplier,
        primaryLabel: 'Fixture Supplier Queue Item',
        secondaryLabel: '+919000000001',
        submittedAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
      ),
    ],
    truckers: [
      avr.VerificationQueueItem(
        id: 'trucker-queue-1',
        type: avr.VerificationEntityType.trucker,
        primaryLabel: 'Fixture Trucker Queue Item',
        secondaryLabel: '+919000000002',
        submittedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      ),
    ],
  );
}

avr.VerificationDetail _fixtureSupplierVerificationDetail() {
  return const avr.VerificationDetail(
    id: 'supplier-queue-1',
    type: avr.VerificationEntityType.supplier,
    title: 'Fixture Supplier Queue Item',
    status: 'pending',
    rejectionReason: '',
    metadata: {
      'Name': 'Fixture Supplier Queue Item',
      'Mobile': '+919000000001',
      'Email': 'fixture.supplier@example.com',
    },
    documents: [
      avr.VerificationDocument(
        label: 'Aadhaar Front',
        url: 'https://example.com/fixture-aadhaar-front.png',
      ),
      avr.VerificationDocument(
        label: 'Aadhaar Back',
        url: 'https://example.com/fixture-aadhaar-back.png',
      ),
      avr.VerificationDocument(label: 'PAN Card', url: ''),
    ],
  );
}

avr.VerificationDetail _fixtureSupplierVerificationDetailMissingDocUrl() {
  return const avr.VerificationDetail(
    id: 'supplier-queue-1',
    type: avr.VerificationEntityType.supplier,
    title: 'Fixture Supplier Queue Item',
    status: 'pending',
    rejectionReason: '',
    metadata: {
      'Name': 'Fixture Supplier Queue Item',
      'Mobile': '+919000000001',
      'Email': 'fixture.supplier@example.com',
    },
    documents: [avr.VerificationDocument(label: 'Aadhaar Front', url: '')],
  );
}

avr.VerificationDetail _fixtureTruckerVerificationDetail() {
  return const avr.VerificationDetail(
    id: 'trucker-queue-1',
    type: avr.VerificationEntityType.trucker,
    title: 'Fixture Trucker Queue Item',
    status: 'pending',
    rejectionReason: '',
    metadata: {
      'Name': 'Fixture Trucker Queue Item',
      'Mobile': '+919000000002',
      'Email': 'fixture.trucker@example.com',
      'DL Number': 'DL-TRUCKER-12345',
    },
    documents: [
      avr.VerificationDocument(
        label: 'DL Front',
        url: 'https://example.com/fixture-dl-front.png',
      ),
      avr.VerificationDocument(
        label: 'DL Back',
        url: 'https://example.com/fixture-dl-back.png',
      ),
      avr.VerificationDocument(label: 'Aadhaar Front', url: ''),
    ],
  );
}

AdminUserDetail _fixtureUserDetail() {
  return const AdminUserDetail(
    profile: AdminUserListItem(
      id: 'user-1',
      fullName: 'Fixture User',
      mobile: '9000000000',
      email: 'fixture.user@example.com',
      role: 'trucker',
      verificationStatus: 'approved',
      isBanned: false,
      banReason: '',
      loadsCount: 2,
    ),
    roleMetadata: {'DL Number': 'DL-12345'},
    documents: [
      VerificationDocument(label: 'Aadhaar Front', url: ''),
      VerificationDocument(label: 'PAN Card', url: ''),
    ],
    recentItems: [
      AdminRecentItem(
        id: 'trip-1',
        title: 'Trip trip-1',
        status: 'in_transit',
        createdAt: null,
      ),
    ],
  );
}
