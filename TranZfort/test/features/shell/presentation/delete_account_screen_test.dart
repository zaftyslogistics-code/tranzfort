import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/shell/presentation/delete_account_screen.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:tranzfort/src/shared/widgets/action_buttons.dart';

class _FakeAuthRepository extends AuthRepository {
  Result<AccountDeletionRequestOutcome> deletionResult;
  Result<AccountDeletionRequestOutcome> cancelDeletionResult;
  int signOutCalls = 0;

  _FakeAuthRepository({
    required this.deletionResult,
    Result<AccountDeletionRequestOutcome>? cancelDeletionResult,
  }) : cancelDeletionResult = cancelDeletionResult ?? deletionResult,
       super(null);

  @override
  Future<Result<AccountDeletionRequestOutcome>> requestAccountDeletion() async {
    return deletionResult;
  }

  @override
  Future<Result<AccountDeletionRequestOutcome>> cancelAccountDeletion() async {
    return cancelDeletionResult;
  }

  @override
  Future<Result<void>> signOutAndClearLocalState() async {
    signOutCalls += 1;
    return const Success<void>(null);
  }
}

Widget _buildApp({
  required AuthRepository repository,
  required UserProfile profile,
  required AuthStateSnapshot authState,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.deleteAccountPath,
    routes: [
      GoRoute(
        path: AppRoutes.deleteAccountPath,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.authPath,
        builder: (context, state) => const Scaffold(body: Text('Auth screen opened')),
      ),
      GoRoute(
        path: AppRoutes.supportPath,
        builder: (context, state) => const Scaffold(body: Text('Support screen opened')),
      ),
      GoRoute(
        path: AppRoutes.supplierTripsPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier trips opened')),
      ),
      GoRoute(
        path: AppRoutes.tripsPath,
        builder: (context, state) => const Scaffold(body: Text('Trucker trips opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      currentAuthStateProvider.overrideWithValue(authState),
      currentProfileProvider.overrideWith((ref) => AsyncValue<UserProfile?>.data(profile)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

UserProfile _profile({
  String deletionStatus = 'active',
  DateTime? deletionRequestedAt,
}) {
  return UserProfile(
    id: 'user-1',
    fullName: 'Aarav Singh',
    mobile: '9999999999',
    email: 'aarav@example.com',
    roleType: 'supplier',
    isBanned: false,
    accountDeletionStatus: deletionStatus,
    trustSafetyStatus: 'normal',
    dataDeletionRequestedAt: deletionRequestedAt,
  );
}

String _expectedLifecycleDate(WidgetTester tester, DateTime value) {
  final context = tester.element(find.byType(DeleteAccountScreen).first);
  return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
}

String _expectedGracePeriodRemainingLabel(WidgetTester tester, DateTime requestedAt) {
  final context = tester.element(find.byType(DeleteAccountScreen).first);
  final l10n = AppLocalizations.of(context);
  final remaining = requestedAt.add(const Duration(days: 30)).difference(DateTime.now());
  if (remaining.isNegative) {
    return l10n.deleteAccountGracePeriodPassedLabel;
  }
  final remainingDays = remaining.inDays;
  if (remainingDays <= 0) {
    return l10n.deleteAccountGracePeriodLessThanOneDayLabel;
  }
  return l10n.deleteAccountGracePeriodRemainingDaysLabel(remainingDays);
}

void main() {
  testWidgets('delete account screen shows sanitized lifecycle failure copy', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Failure<AccountDeletionRequestOutcome>(
        UnknownFailure(message: 'PostgrestException: leaked detail'),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Account deletion unavailable'), findsOneWidget);
    expect(
      find.text('We could not process this deletion request right now. Review the current account status and retry shortly.'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('delete account screen shows blocker result and does not sign out', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'active trips',
          message: 'PostgrestException: blocked by active trips raw detail',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Deletion blocked'), findsOneWidget);
    expect(
      find.text(
        'This deletion request cannot proceed yet because another account dependency still needs attention. Finish or cancel every active trip first, then retry the deletion request.',
      ),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: blocked by active trips raw detail'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Finish active trips first'), 200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Finish active trips first'), findsOneWidget);
    expect(find.text('This account still has active trip work attached to it. Review the current trip list, complete any legitimate active work, and then retry the deletion request.'), findsOneWidget);
    expect(find.text('Open trips'), findsWidgets);
    expect(repository.signOutCalls, 0);

    await tester.scrollUntilVisible(find.text('Open trips').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open trips').first);
    await tester.pumpAndSettle();

    expect(find.text('Supplier trips opened'), findsOneWidget);
  });

  testWidgets('delete account screen routes truckers with active-trip blockers to the trucker trips screen', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'active trips',
          message: 'Account deletion is blocked by active trips',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Open trips').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open trips').first);
    await tester.pumpAndSettle();

    expect(find.text('Trucker trips opened'), findsOneWidget);
    expect(repository.signOutCalls, 0);
  });

  testWidgets('delete account screen shows dispute-specific blocker guidance and routes to support', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'unresolved dispute',
          message: 'Account deletion is blocked by an unresolved dispute',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Resolve the open dispute first'), findsOneWidget);
    expect(
      find.text('This account still has an unresolved dispute or review dependency. Use support to follow the current case until the blocking dispute is resolved.'),
      findsOneWidget,
    );
    expect(find.text('Open support'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Open support').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support screen opened'), findsOneWidget);
    expect(repository.signOutCalls, 0);
  });

  testWidgets('delete account screen hides raw backend status for unknown deletion status', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'active',
          blocked: false,
          blocker: null,
          message: 'Account state loaded',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(deletionStatus: 'some_unknown_backend_status'),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account state'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('Some unknown backend status'), findsNothing);
    expect(find.text('some_unknown_backend_status'), findsNothing);
  });

  testWidgets('delete account screen routes trucker dispute blockers to support', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'unresolved dispute',
          message: 'Account deletion is blocked by an unresolved dispute',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Resolve the open dispute first'), findsOneWidget);
    expect(find.text('Open support'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Open support').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support screen opened'), findsOneWidget);
    expect(repository.signOutCalls, 0);
  });

  testWidgets('delete account screen shows compliance-hold blocker guidance and routes to support', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'compliance retention hold',
          message: 'Account deletion is blocked by a compliance retention hold',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Wait for the compliance hold to clear'), findsOneWidget);
    expect(
      find.text('This account is still under a compliance or retention hold. Support can clarify the current hold, but the platform cannot bypass the retention requirement.'),
      findsOneWidget,
    );
    expect(find.text('Open support'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Open support').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support screen opened'), findsOneWidget);
    expect(repository.signOutCalls, 0);
  });

  testWidgets('delete account screen routes trucker compliance-hold blockers to support', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'compliance retention hold',
          message: 'Account deletion is blocked by a compliance retention hold',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Wait for the compliance hold to clear'), findsOneWidget);
    expect(find.text('Open support'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Open support').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support screen opened'), findsOneWidget);
    expect(repository.signOutCalls, 0);
  });

  testWidgets('delete account screen signs out and returns to auth when deletion is accepted', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'rpc deletion accepted raw detail',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Auth screen opened'), findsOneWidget);
    expect(
      find.text('Your deletion request was accepted. You have been signed out while the account enters pending cleanup.'),
      findsOneWidget,
    );
    expect(find.text('rpc deletion accepted raw detail'), findsNothing);
    expect(repository.signOutCalls, 1);
  });

  testWidgets('delete account screen signs out truckers and returns to auth when deletion is accepted', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'Account deletion requested and account deactivated pending cleanup',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Auth screen opened'), findsOneWidget);
    expect(repository.signOutCalls, 1);
  });

  testWidgets('delete account screen allows cancelling pending cleanup deletion', (tester) async {
    final deletionRequestedAt = DateTime.now().subtract(const Duration(days: 5));
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'Account deletion requested and account deactivated pending cleanup',
        ),
      ),
      cancelDeletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'active',
          blocked: false,
          blocker: null,
          message: 'rpc cancellation detail leaked',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(
          deletionStatus: 'deactivated_pending_cleanup',
          deletionRequestedAt: deletionRequestedAt,
        ),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cancelButton = find.widgetWithText(OutlineButton, 'Cancel deletion request');
    await tester.scrollUntilVisible(
      cancelButton,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(cancelButton, findsOneWidget);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Deletion request cancelled'), findsOneWidget);
    expect(
      find.text('Your deletion request was cancelled. Account access can be restored while the lifecycle returns to active.'),
      findsWidgets,
    );
    expect(find.text('rpc cancellation detail leaked'), findsNothing);
    expect(repository.signOutCalls, 0);
  });

  testWidgets('delete account screen hides cancel action after the grace period has passed', (tester) async {
    final deletionRequestedAt = DateTime.now().subtract(const Duration(days: 31));
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'Account deletion requested and account deactivated pending cleanup',
        ),
      ),
      cancelDeletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'active',
          blocked: false,
          blocker: null,
          message: 'Account deletion request cancelled and account restored to active',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(
          deletionStatus: 'deactivated_pending_cleanup',
          deletionRequestedAt: deletionRequestedAt,
        ),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_expectedGracePeriodRemainingLabel(tester, deletionRequestedAt)), findsWidgets);
    expect(find.text('Deletion already requested'), findsOneWidget);
    expect(find.text('Cancel deletion request'), findsNothing);
  });

  testWidgets('delete account screen shows grace-period-passed warning copy after the cancellation window expires', (tester) async {
    final deletionRequestedAt = DateTime.now().subtract(const Duration(days: 31));
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'Account deletion requested and account deactivated pending cleanup',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(
          deletionStatus: 'deactivated_pending_cleanup',
          deletionRequestedAt: deletionRequestedAt,
        ),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_expectedGracePeriodRemainingLabel(tester, deletionRequestedAt)), findsWidgets);
    expect(find.text('Grace-period end date has passed. Permanent deletion processing may happen at any time.'), findsWidgets);
  });

  testWidgets('delete account screen localizes the current account-state row', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'Account deletion requested and account deactivated pending cleanup',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(deletionStatus: 'deactivated_pending_cleanup'),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account state'), findsOneWidget);
    expect(find.text('Deactivated pending cleanup'), findsOneWidget);
  });

  testWidgets('delete account screen shows the grace-period timeline for pending cleanup accounts', (tester) async {
    final deletionRequestedAt = DateTime.now().subtract(const Duration(days: 5));
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'deactivated_pending_cleanup',
          blocked: false,
          blocker: null,
          message: 'Account deletion requested and account deactivated pending cleanup',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(
          deletionStatus: 'deactivated_pending_cleanup',
          deletionRequestedAt: deletionRequestedAt,
        ),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deletion requested on'), findsOneWidget);
    expect(find.text('Grace period ends'), findsOneWidget);
    expect(find.text(_expectedLifecycleDate(tester, deletionRequestedAt)), findsOneWidget);
    expect(find.text(_expectedLifecycleDate(tester, deletionRequestedAt.add(const Duration(days: 30)))), findsOneWidget);
    expect(find.text(_expectedGracePeriodRemainingLabel(tester, deletionRequestedAt)), findsOneWidget);
  });

  testWidgets('delete account screen offers support guidance before deletion', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'compliance hold',
          message: 'Account deletion is blocked by compliance records',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Need help first?'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Need help first?'), findsOneWidget);
    expect(
      find.text('Use support if you expect blockers like active trips, unresolved disputes, or compliance holds and need clarification before retrying the deletion request.'),
      findsOneWidget,
    );
    expect(
      find.text('Support can explain the current blocker or retention requirement, but they cannot bypass required cleanup, dispute review, or compliance policy.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Open support').first, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support screen opened'), findsOneWidget);
  });

  testWidgets('delete account screen offers truckers support guidance before deletion', (tester) async {
    final repository = _FakeAuthRepository(
      deletionResult: const Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome(
          status: 'blocked_by_dependency',
          blocked: true,
          blocker: 'compliance hold',
          message: 'Account deletion is blocked by compliance records',
        ),
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        profile: _profile(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Need help first?'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Need help first?'), findsOneWidget);

    await tester.tap(find.text('Open support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support screen opened'), findsOneWidget);
  });
}
