import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/repositories/admin_user_repository.dart';
import 'package:admin/src/features/users/presentation/admin_user_detail_screen.dart';
import 'package:admin/src/features/users/providers/admin_user_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminUserActionController extends AdminUserActionController {
  bool called = false;
  String? lastUserId;
  bool? lastBanValue;
  String? lastReason;

  _FakeAdminUserActionController(super.ref);

  @override
  Future<bool> setBanStatus({required String userId, required bool isBanned, String? reason}) async {
    called = true;
    lastUserId = userId;
    lastBanValue = isBanned;
    lastReason = reason;
    return true;
  }
}

Widget _buildRoutedDetailApp({required AdminUserDetail detail}) {
  final router = GoRouter(
    initialLocation: AdminRoutes.userDetailPathFor(detail.profile.id),
    routes: [
      GoRoute(
        path: AdminRoutes.userDetailPath,
        builder: (context, state) => Scaffold(body: AdminUserDetailScreen(userId: state.pathParameters['userId']!)),
      ),
      GoRoute(
        path: AdminRoutes.verificationDetailPath,
        builder: (context, state) => Scaffold(body: Text('Verification detail opened: ${state.pathParameters['caseId']}')),
      ),
      GoRoute(
        path: AdminRoutes.loadDetailPath,
        builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
      ),
      GoRoute(
        path: AdminRoutes.supportDetailPath,
        builder: (context, state) => Scaffold(body: Text('Support detail opened: ${state.pathParameters['ticketId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminUserDetailProvider(detail.profile.id).overrideWith((ref) async => detail),
      adminUserActionProvider.overrideWith((ref) => _FakeAdminUserActionController(ref)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('admin user detail renders profile sections and ban action', (tester) async {
    late _FakeAdminUserActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserDetailProvider('user-1').overrideWith((ref) async {
            return AdminUserDetail(
              profile: const AdminUserListItem(
                id: 'user-1',
                fullName: 'Supplier One',
                mobile: '9999999999',
                email: 'supplier@example.com',
                role: 'supplier',
                verificationStatus: 'approved',
                isBanned: false,
                banReason: '',
                activityCount: 8,
                createdAt: null,
                lastLoginAt: null,
              ),
              roleMetadata: const {
                'Company': 'S1 Logistics',
                'Verification location': 'Mumbai, Maharashtra',
                'Verification coordinates': '19.076, 72.8777',
              },
              stats: const {
                'Loads posted': '8',
                'Active loads': '3',
              },
              verificationRejectionReason: 'Profile documents need correction before approval.',
              verificationFeedbackSummary: 'GST certificate mismatch',
              verificationFeedbackNextStep: 'Upload the correct GST certificate and resubmit.',
              latestVerificationCase: const AdminVerificationCaseSummary(
                id: 'case-1',
                status: 'waiting_for_resubmission',
                decisionSummary: 'Documents need correction',
                reviewFeedbackSummary: 'Business licence details do not match',
                reviewFeedbackNextStep: 'Upload the corrected business licence copy.',
                lastReviewedAt: null,
              ),
              documents: const [
                VerificationDocument(
                  label: 'PAN Card',
                  path: 'user-1/pan/pan.jpg',
                  signedUrl: 'https://signed/pan',
                ),
              ],
              recentItems: [
                AdminRecentItem(
                  id: 'load-1',
                  title: 'Mumbai -> Pune',
                  status: 'active',
                  createdAt: DateTime(2026, 3, 12, 20, 15),
                ),
              ],
              auditEntries: [
                AdminAuditEntry(
                  id: 'audit-1',
                  actionType: 'user_verification_rejected',
                  summary: 'Verification rejected for missing GST proof',
                  targetObjectType: 'verification_case',
                  targetObjectId: 'case-1',
                  createdAt: DateTime(2026, 3, 12, 21, 30),
                ),
              ],
            );
          }),
          adminUserActionProvider.overrideWith((ref) {
            actionController = _FakeAdminUserActionController(ref);
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminUserDetailScreen(userId: 'user-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Supplier One'), findsOneWidget);
    expect(find.text('User user-1'), findsOneWidget);
    expect(find.text('Profile summary'), findsOneWidget);
    expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Stats overview'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Stats overview'), findsOneWidget);
    expect(find.text('Loads posted'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    expect(find.text('Active loads'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Verification feedback'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification feedback'), findsOneWidget);
    expect(find.text('Profile documents need correction before approval.'), findsOneWidget);
    expect(find.text('GST certificate mismatch'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Latest verification case'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Latest verification case'), findsOneWidget);
    expect(find.text('case-1'), findsOneWidget);
    expect(find.text('Documents need correction'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-user-open-verification-case-button')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Verification documents'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification documents'), findsOneWidget);
    expect(find.text('View document'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent activity'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Activity load-1'), findsOneWidget);
    expect(find.text('Created 2026-03-12'), findsWidgets);
    final supplierRecentActivityTile = tester.widget<ListTile>(
      find.byKey(const ValueKey('admin-user-recent-activity-load-1')),
    );
    expect(supplierRecentActivityTile.onTap, isNotNull);
    await tester.scrollUntilVisible(
      find.text('Audit history'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Audit history'), findsOneWidget);
    expect(find.text('Verification rejected for missing GST proof'), findsOneWidget);
    expect(find.text('Audit audit-1'), findsOneWidget);
    expect(find.text('verification_case • case-1'), findsOneWidget);
    expect(find.text('Created 2026-03-12'), findsWidgets);
    final supplierAuditTile = tester.widget<ListTile>(
      find.byKey(const ValueKey('admin-user-audit-entry-audit-1')),
    );
    expect(supplierAuditTile.onTap, isNotNull);
    final banButtonFinder = find.byKey(const ValueKey('admin-user-ban-toggle-button'));
    await tester.scrollUntilVisible(
      banButtonFinder,
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(banButtonFinder, findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Repeated fraud reports');
    await tester.tap(banButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Confirm ban'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm ban').last);
    await tester.pumpAndSettle();

    expect(actionController.called, isTrue);
    expect(actionController.lastUserId, 'user-1');
    expect(actionController.lastBanValue, isTrue);
    expect(actionController.lastReason, 'Repeated fraud reports');
  });

  testWidgets('admin user detail opens the signed document preview dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserDetailProvider('user-1').overrideWith((ref) async {
            return AdminUserDetail(
              profile: const AdminUserListItem(
                id: 'user-1',
                fullName: 'Supplier One',
                mobile: '9999999999',
                email: 'supplier@example.com',
                role: 'supplier',
                verificationStatus: 'approved',
                isBanned: false,
                banReason: '',
                activityCount: 8,
                createdAt: null,
                lastLoginAt: null,
              ),
              roleMetadata: const {'Company': 'S1 Logistics'},
              documents: const [
                VerificationDocument(
                  label: 'PAN Card',
                  path: 'user-1/pan/pan.jpg',
                  signedUrl: 'https://signed/pan',
                ),
              ],
              recentItems: const [],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminUserDetailScreen(userId: 'user-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Verification documents'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View document'));
    await tester.pumpAndSettle();

    expect(find.text('PAN Card'), findsWidgets);
    expect(find.text('user-1/pan/pan.jpg'), findsWidgets);
  });

  testWidgets('admin user detail does not dispatch ban action when confirmation is cancelled', (tester) async {
    late _FakeAdminUserActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserDetailProvider('user-1').overrideWith((ref) async {
            return AdminUserDetail(
              profile: const AdminUserListItem(
                id: 'user-1',
                fullName: 'Supplier One',
                mobile: '9999999999',
                email: 'supplier@example.com',
                role: 'supplier',
                verificationStatus: 'approved',
                isBanned: false,
                banReason: '',
                activityCount: 8,
                createdAt: null,
                lastLoginAt: null,
              ),
              roleMetadata: const {'Company': 'S1 Logistics'},
              documents: const [],
              recentItems: const [],
            );
          }),
          adminUserActionProvider.overrideWith((ref) {
            actionController = _FakeAdminUserActionController(ref);
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminUserDetailScreen(userId: 'user-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final banButtonFinder = find.byKey(const ValueKey('admin-user-ban-toggle-button'));
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      banButtonFinder,
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Repeated fraud reports');
    await tester.tap(banButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(actionController.called, isFalse);
  });

  testWidgets('admin user detail dispatches the unban flow for banned users', (tester) async {
    late _FakeAdminUserActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserDetailProvider('user-3').overrideWith((ref) async {
            return AdminUserDetail(
              profile: const AdminUserListItem(
                id: 'user-3',
                fullName: 'Banned Supplier',
                mobile: '7777777777',
                email: 'banned@example.com',
                role: 'supplier',
                verificationStatus: 'approved',
                isBanned: true,
                banReason: 'Repeated fraud reports',
                activityCount: 5,
                createdAt: null,
                lastLoginAt: null,
              ),
              roleMetadata: const {'Company': 'Blocked Logistics'},
              documents: const [],
              recentItems: const [],
            );
          }),
          adminUserActionProvider.overrideWith((ref) {
            actionController = _FakeAdminUserActionController(ref);
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminUserDetailScreen(userId: 'user-3'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final unbanButtonFinder = find.byKey(const ValueKey('admin-user-ban-toggle-button'));
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      unbanButtonFinder,
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Unban account'), findsWidgets);
    expect(find.text('Optional unban note'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Restored after manual review');
    await tester.tap(unbanButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Confirm unban'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm unban').last);
    await tester.pumpAndSettle();

    expect(actionController.called, isTrue);
    expect(actionController.lastUserId, 'user-3');
    expect(actionController.lastBanValue, isFalse);
    expect(actionController.lastReason, 'Restored after manual review');
  });

  testWidgets('admin user detail renders trucker fleet section when fleet rows exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserDetailProvider('user-2').overrideWith((ref) async {
            return AdminUserDetail(
              profile: const AdminUserListItem(
                id: 'user-2',
                fullName: 'Trucker One',
                mobile: '8888888888',
                email: 'trucker@example.com',
                role: 'trucker',
                verificationStatus: 'approved',
                isBanned: false,
                banReason: '',
                activityCount: 16,
                createdAt: null,
                lastLoginAt: null,
              ),
              roleMetadata: const {
                'DL Number': 'DL123',
                'Rating': '4.8',
                'Completed trips': '12',
                'Super Trucker': 'eligible',
              },
              stats: const {
                'Trips total': '16',
                'Completed trips': '12',
                'Rating': '4.8',
                'Fleet size': '1',
              },
              documents: const [
                VerificationDocument(
                  label: 'DL Front',
                  path: 'https://files.example.com/dl-front.jpg',
                  signedUrl: 'https://files.example.com/dl-front.jpg',
                ),
                VerificationDocument(
                  label: 'DL Back',
                  path: 'https://files.example.com/dl-back.jpg',
                  signedUrl: 'https://files.example.com/dl-back.jpg',
                ),
              ],
              recentItems: const [
                AdminRecentItem(
                  id: 'trip-1',
                  title: 'Trip trip-1',
                  status: 'in_transit',
                  createdAt: null,
                ),
              ],
              auditEntries: const [
                AdminAuditEntry(
                  id: 'audit-2',
                  actionType: 'user_status_checked',
                  summary: 'Profile trust state reviewed',
                  targetObjectType: 'profile',
                  targetObjectId: 'user-2',
                  createdAt: null,
                ),
              ],
              fleetTrucks: [
                AdminFleetTruck(
                  id: 'truck-1',
                  truckNumber: 'MH12AB1234',
                  bodyType: 'Open Body',
                  tyres: 10,
                  capacityTonnes: '21',
                  status: 'rejected',
                  verificationCaseId: 'case-truck-1',
                  verificationCaseStatus: 'submitted',
                  rejectionReason: 'RC copy is blurry',
                  feedbackSummary: 'RC document could not be verified',
                  feedbackNextStep: 'Upload a clearer RC photo and resubmit.',
                  modelLabel: 'Tata Signa',
                  verifiedAt: DateTime(2026, 3, 10, 13, 20),
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminUserDetailScreen(userId: 'user-2'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Verification documents'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification documents'), findsOneWidget);
    expect(find.text('DL Front'), findsOneWidget);
    expect(find.text('DL Back'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fleet'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Fleet'), findsOneWidget);
    expect(find.text('MH12AB1234'), findsOneWidget);
    expect(find.text('Truck truck-1'), findsOneWidget);
    expect(find.text('Verification case case-truck-1'), findsOneWidget);
    expect(find.text('Verified 2026-03-10'), findsOneWidget);
    expect(find.textContaining('Tata Signa'), findsOneWidget);
    expect(find.textContaining('RC copy is blurry'), findsOneWidget);
    expect(find.textContaining('RC document could not be verified'), findsOneWidget);
    final fleetTile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'MH12AB1234'));
    expect(fleetTile.onTap, isNotNull);
  });

  testWidgets('admin user detail leaves fleet row non-interactive when linked truck case is absent', (tester) async {
    final detail = AdminUserDetail(
      profile: const AdminUserListItem(
        id: 'user-4',
        fullName: 'Trucker Two',
        mobile: '7777777777',
        email: 'trucker2@example.com',
        role: 'trucker',
        verificationStatus: 'pending',
        isBanned: false,
        banReason: '',
        activityCount: 3,
        createdAt: null,
        lastLoginAt: null,
      ),
      roleMetadata: const {},
      stats: const {'Fleet size': '1'},
      documents: const [],
      recentItems: const [],
      fleetTrucks: const [
        AdminFleetTruck(
          id: 'truck-2',
          truckNumber: 'DL01AB6788',
          bodyType: 'Tanker',
          tyres: 12,
          capacityTonnes: '23',
          status: 'pending',
          rejectionReason: '',
          feedbackSummary: '',
          feedbackNextStep: '',
          modelLabel: 'Tanker',
          verifiedAt: null,
        ),
      ],
    );

    await tester.pumpWidget(_buildRoutedDetailApp(detail: detail));
    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Fleet'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    final fleetTile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'DL01AB6788'));
    expect(fleetTile.onTap, isNull);
  });

  testWidgets('admin user detail routes to recent load activity', (tester) async {
    final detail = AdminUserDetail(
      profile: const AdminUserListItem(
        id: 'user-1',
        fullName: 'Supplier One',
        mobile: '9999999999',
        email: 'supplier@example.com',
        role: 'supplier',
        verificationStatus: 'approved',
        isBanned: false,
        banReason: '',
        activityCount: 8,
        createdAt: null,
        lastLoginAt: null,
      ),
      roleMetadata: const {},
      stats: const {},
      verificationRejectionReason: '',
      verificationFeedbackSummary: '',
      verificationFeedbackNextStep: '',
      latestVerificationCase: null,
      documents: const [],
      recentItems: [
        AdminRecentItem(
          id: 'load-1',
          title: 'Mumbai -> Pune',
          status: 'active',
          createdAt: DateTime(2026, 3, 12, 20, 15),
        ),
      ],
      auditEntries: [],
    );

    await tester.pumpWidget(_buildRoutedDetailApp(detail: detail));
    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-user-recent-activity-load-1')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.byKey(const ValueKey('admin-user-recent-activity-load-1')));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });
}
