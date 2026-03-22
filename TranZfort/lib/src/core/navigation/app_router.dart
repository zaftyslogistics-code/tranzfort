import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screens.dart';
import '../../features/auth/presentation/onboarding_screens.dart';
import '../../features/communication/presentation/chat_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/shell/presentation/delete_account_screen.dart';
import '../../features/supplier/presentation/post_load_screen.dart';
import '../../features/supplier/presentation/raise_dispute_screen.dart';
import '../../features/supplier/presentation/supplier_trip_detail_screen.dart';
import '../../features/support/presentation/create_support_ticket_screen.dart';
import '../../features/support/presentation/report_issue_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/support/providers/support_compose_providers.dart';
import '../../features/trucker/presentation/trucker_dashboard_screen.dart';
import '../../features/trucker/presentation/trucker_fleet_screen.dart';
import '../../features/trucker/presentation/trucker_find_loads_screen.dart';
import '../../features/trucker/presentation/trucker_load_detail_screen.dart';
import '../../features/trucker/presentation/trucker_trip_detail_screen.dart';
import '../../features/trucker/presentation/trucker_trips_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../features/shell/presentation/shell_destinations.dart';
import '../../features/shell/presentation/supplier_shell_screens.dart';
import '../providers/app_state_providers.dart';
import 'auth_router_refresh_notifier.dart';
import '../../features/shell/presentation/user_app_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublicRoute = path == AppRoutes.splashPath ||
          path == AppRoutes.authPath ||
          path == AppRoutes.authPasswordPath;
      final authStateAsync = ref.read(authStateProvider);
      final authState = ref.read(currentAuthStateProvider);
      final hasSession = authState.hasSession;
      final isBannedRoute = path == AppRoutes.bannedPath;
      final isDeleteAccountRoute = path == AppRoutes.deleteAccountPath;
      final isOnboardingRoute = path == AppRoutes.onboardingPath ||
          path == AppRoutes.onboardingRolePath ||
          path == AppRoutes.onboardingProfilePath;
      final isSupplier = authState.role == AppUserRole.supplier;
      final isRestrictedAccount = authState.isBanned;

      if (hasSession && !authState.isResolved) {
        if (authStateAsync.isLoading) {
          if (path == AppRoutes.splashPath || isPublicRoute || isOnboardingRoute || isBannedRoute) {
            return null;
          }
          return AppRoutes.onboardingPath;
        }
        return null;
      }

      if (!hasSession && !isPublicRoute) {
        return AppRoutes.authPath;
      }

      if (!hasSession && path == AppRoutes.splashPath) {
        return AppRoutes.authPath;
      }

      if (!hasSession) {
        return null;
      }

      if (path == AppRoutes.onboardingPath) {
        if (hasSession && !authState.isResolved) {
          return null;
        }

        final profile = authState.profile;
        final hasKnownRole = (profile?.hasRole ?? false) || authState.role != AppUserRole.unknown;
        if (!hasKnownRole) {
          return AppRoutes.onboardingRolePath;
        }

        if (!authState.isProfileComplete) {
          return AppRoutes.onboardingProfilePath;
        }

        return isSupplier ? AppRoutes.supplierDashboardPath : AppRoutes.truckerDashboardPath;
      }

      if (authState.isDeactivated && !isDeleteAccountRoute) {
        return AppRoutes.deleteAccountPath;
      }

      if (isRestrictedAccount && !isBannedRoute) {
        return AppRoutes.bannedPath;
      }

      if (!isRestrictedAccount && isBannedRoute) {
        return authState.role == AppUserRole.supplier
            ? AppRoutes.supplierDashboardPath
            : AppRoutes.truckerDashboardPath;
      }

      if (!authState.isProfileComplete && !isOnboardingRoute && !isPublicRoute) {
        return AppRoutes.onboardingPath;
      }

      if (authState.isProfileComplete && isOnboardingRoute) {
        return authState.role == AppUserRole.supplier
            ? AppRoutes.supplierDashboardPath
            : AppRoutes.truckerDashboardPath;
      }

      if (path == AppRoutes.authPath) {
        if (isRestrictedAccount) {
          return AppRoutes.bannedPath;
        }

        if (authState.isDeactivated) {
          return AppRoutes.deleteAccountPath;
        }

        if (!authState.isProfileComplete) {
          return AppRoutes.onboardingPath;
        }

        return isSupplier ? AppRoutes.supplierDashboardPath : AppRoutes.truckerDashboardPath;
      }

      if (isSupplier) {
        if (path == AppRoutes.dashboardPath) {
          return AppRoutes.supplierDashboardPath;
        }

        if (path == AppRoutes.findLoadsPath) {
          return AppRoutes.myLoadsPath;
        }

        if (path == AppRoutes.tripsPath) {
          return AppRoutes.supplierTripsPath;
        }

        if (path == AppRoutes.fleetPath) {
          return AppRoutes.supplierDashboardPath;
        }
      } else {
        if (path == AppRoutes.dashboardPath) {
          return AppRoutes.truckerDashboardPath;
        }

        if (path == AppRoutes.supplierDashboardPath) {
          return AppRoutes.truckerDashboardPath;
        }

        if (path == AppRoutes.truckerDashboardPath) {
          return null;
        }

        if (path == AppRoutes.myLoadsPath) {
          return AppRoutes.findLoadsPath;
        }

        if (path == AppRoutes.supplierTripsPath) {
          return AppRoutes.tripsPath;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.rootPath,
        redirect: (context, state) => AppRoutes.splashPath,
      ),
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.authPath,
        name: AppRoutes.auth,
        builder: (context, state) => const AuthEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.authPasswordPath,
        name: AppRoutes.authPassword,
        builder: (context, state) => const EmailPasswordAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingRolePath,
        name: AppRoutes.onboardingRole,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingProfilePath,
        name: AppRoutes.onboardingProfile,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.bannedPath,
        name: AppRoutes.banned,
        builder: (context, state) => const AccessRestrictedScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return UserAppShell(
            currentLocation: state.uri.path,
            role: ref.read(currentAuthStateProvider).role,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.supplierDashboardPath,
            name: AppRoutes.supplierDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SupplierDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.dashboardPath,
            name: AppRoutes.dashboard,
            redirect: (context, state) => AppRoutes.truckerDashboardPath,
          ),
          GoRoute(
            path: AppRoutes.truckerDashboardPath,
            name: AppRoutes.truckerDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TruckerDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.postLoadPath,
            name: AppRoutes.postLoad,
            builder: (context, state) => const PostLoadScreen(),
          ),
          GoRoute(
            path: AppRoutes.myLoadsPath,
            name: AppRoutes.myLoads,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SupplierMyLoadsScreen(),
            ),
          ),
          GoRoute(
            path: '${AppRoutes.loadDetailPath}/:loadId',
            name: AppRoutes.loadDetail,
            builder: (context, state) {
              final loadId = state.pathParameters['loadId'] ?? '';
              final authState = ref.read(currentAuthStateProvider);
              if (authState.role == AppUserRole.supplier) {
                return SupplierLoadDetailScreen(loadId: loadId);
              }
              return TruckerLoadDetailScreen(loadId: loadId);
            },
          ),
          GoRoute(
            path: AppRoutes.findLoadsPath,
            name: AppRoutes.findLoads,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TruckerFindLoadsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.fleetPath,
            name: AppRoutes.fleet,
            builder: (context, state) => TruckerFleetScreen(
              returnToVerification: state.uri.queryParameters['returnTo'] == 'verification',
            ),
          ),
          GoRoute(
            path: AppRoutes.tripsPath,
            name: AppRoutes.trips,
            redirect: (context, state) {
              final authState = ref.read(currentAuthStateProvider);
              return authState.role == AppUserRole.supplier ? AppRoutes.supplierTripsPath : null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TruckerTripsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.supplierTripsPath,
            name: AppRoutes.supplierTrips,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SupplierTripsScreen(),
            ),
          ),
          GoRoute(
            path: '${AppRoutes.tripDetailPath}/:tripId',
            name: AppRoutes.tripDetail,
            builder: (context, state) {
              final tripId = state.pathParameters['tripId'] ?? '';
              final authState = ref.read(currentAuthStateProvider);
              if (authState.role == AppUserRole.supplier) {
                return SupplierTripDetailScreen(tripId: tripId);
              }
              return TruckerTripDetailScreen(tripId: tripId);
            },
          ),
          GoRoute(
            path: AppRoutes.messagesPath,
            name: AppRoutes.messages,
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountPath,
            name: AppRoutes.account,
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: AppRoutes.notificationsPath,
            name: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profilePath,
            name: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.verificationPath,
            name: AppRoutes.verification,
            redirect: (context, state) {
              final authState = ref.read(currentAuthStateProvider);
              return authState.role == AppUserRole.supplier
                  ? AppRoutes.supplierVerificationPath
                  : AppRoutes.truckerVerificationPath;
            },
          ),
          GoRoute(
            path: AppRoutes.supplierVerificationPath,
            name: AppRoutes.supplierVerification,
            builder: (context, state) => const VerificationScreen(),
          ),
          GoRoute(
            path: AppRoutes.truckerVerificationPath,
            name: AppRoutes.truckerVerification,
            builder: (context, state) => const VerificationScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsPath,
            name: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.supportPath,
            name: AppRoutes.support,
            builder: (context, state) => SupportScreen(
              initialSelectedTicketId: state.extra is String ? state.extra as String : null,
            ),
          ),
          GoRoute(
            path: AppRoutes.createSupportTicketPath,
            name: AppRoutes.createSupportTicket,
            builder: (context, state) => const CreateSupportTicketScreen(),
          ),
          GoRoute(
            path: AppRoutes.reportIssuePath,
            name: AppRoutes.reportIssue,
            builder: (context, state) => ReportIssueScreen(
              contextData: state.extra is ReportIssueContext
                  ? state.extra as ReportIssueContext
                  : ReportIssueContext.empty(),
            ),
          ),
          GoRoute(
            path: AppRoutes.deleteAccountPath,
            name: AppRoutes.deleteAccount,
            builder: (context, state) => const DeleteAccountScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.raiseDisputePath}/:tripId',
            name: AppRoutes.raiseDispute,
            builder: (context, state) => RaiseDisputeScreen(
              tripId: state.pathParameters['tripId'] ?? '',
            ),
          ),
          GoRoute(
            path: '${AppRoutes.chatPath}/:conversationId',
            name: AppRoutes.chat,
            builder: (context, state) => ChatScreen(
              conversationId: state.pathParameters['conversationId'] ?? '',
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => AppRouteErrorScreen(
      attemptedPath: state.uri.toString(),
    ),
  );
});
