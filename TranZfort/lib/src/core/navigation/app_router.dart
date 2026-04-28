import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screens.dart';
import '../../features/auth/presentation/onboarding_screens.dart';
import '../../features/auth/presentation/onboarding_profile_completion.dart';
import '../../features/communication/presentation/chat_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/providers/public_profile_providers.dart';
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
import '../../features/trucker/presentation/trucker_route_preview_screen.dart';
import '../../features/trucker/presentation/trucker_trip_detail_screen.dart';
import '../../features/trucker/presentation/trucker_trips_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../features/profile/presentation/supplier_public_profile_screen.dart';
import '../../features/profile/presentation/trucker_public_profile_screen.dart';
import '../../features/shell/presentation/shell_destinations.dart';
import '../../features/shell/presentation/supplier_shell_screens.dart';
import '../services/maps_launcher_service.dart';
import '../providers/app_state_providers.dart';
import 'auth_router_refresh_notifier.dart';
import '../../features/shell/presentation/user_app_shell.dart';
import 'app_routes.dart';
import 'route_metadata_helper.dart';

part 'app_router_redirect.dart';

/// Initialize route metadata
/// 
/// This function registers metadata for all routes in the app.
/// Call this function when the app initializes to ensure route metadata
/// is available for navigation behavior control.
void _initializeRouteMetadata() {
  // Auth Routes
  RouteMetadataHelper.registerMetadata(AppRoutes.rootPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'root_redirect',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.splashPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'splash_screen',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.authPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'auth_entry_screen',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.authPasswordPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'email_password_auth',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.onboardingPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'onboarding_gate',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.onboardingRolePath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'role_selection',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.onboardingProfilePath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'onboarding_profile_completion',
  });

  // Shell Routes
  RouteMetadataHelper.registerMetadata(AppRoutes.supplierDashboardPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'supplier_dashboard',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.truckerDashboardPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'trucker_dashboard',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.messagesPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'messages',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.profilePath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'profile',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.settingsPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'settings',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.accountPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'account',
  });

  // Supplier Routes
  RouteMetadataHelper.registerMetadata(AppRoutes.myLoadsPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'my_loads',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.postLoadPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'post_load',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.supplierTripsPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'supplier_trips',
  });

  // Trucker Routes
  RouteMetadataHelper.registerMetadata(AppRoutes.findLoadsPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'find_loads',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.fleetPath, {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': true,
    'testId': 'trucker_fleet',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.tripsPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'trips',
  });

  // Detail Routes
  RouteMetadataHelper.registerMetadata('${AppRoutes.loadDetailPath}/:loadId', {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': false,
    'testId': 'load_detail',
  });

  RouteMetadataHelper.registerMetadata('${AppRoutes.tripDetailPath}/:tripId', {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': false,
    'testId': 'trip_detail',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.routePreviewPath, {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': false,
    'testId': 'route_preview',
  });

  RouteMetadataHelper.registerMetadata('${AppRoutes.chatPath}/:conversationId', {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': false,
    'testId': 'chat',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.publicProfilePath, {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': false,
    'testId': 'public_profile',
  });

  // Form & Modal Routes
  RouteMetadataHelper.registerMetadata(AppRoutes.supplierVerificationPath, {
    'type': RouteType.subFlow,
    'showBackArrow': true,
    'requirePopScope': true,
    'testId': 'supplier_verification',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.truckerVerificationPath, {
    'type': RouteType.subFlow,
    'showBackArrow': true,
    'requirePopScope': true,
    'testId': 'trucker_verification',
  });

  RouteMetadataHelper.registerMetadata('${AppRoutes.raiseDisputePath}/:tripId', {
    'type': RouteType.nested,
    'showBackArrow': true,
    'requirePopScope': true,
    'testId': 'raise_dispute',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.createSupportTicketPath, {
    'type': RouteType.modal,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'create_support_ticket',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.reportIssuePath, {
    'type': RouteType.modal,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'report_issue',
  });

  // Special Routes
  RouteMetadataHelper.registerMetadata(AppRoutes.bannedPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'banned',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.notificationsPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'notifications',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.supportPath, {
    'type': RouteType.topLevel,
    'showBackArrow': false,
    'requirePopScope': false,
    'testId': 'support',
  });

  RouteMetadataHelper.registerMetadata(AppRoutes.deleteAccountPath, {
    'type': RouteType.standalone,
    'showBackArrow': false,
    'requirePopScope': true,
    'testId': 'delete_account',
  });

  // All routes now have metadata registered
}

// Flag to ensure metadata is initialized only once
bool _routeMetadataInitialized = false;

final appRouterProvider = Provider<GoRouter>((ref) {
  // Initialize route metadata on first access
  if (!_routeMetadataInitialized) {
    _initializeRouteMetadata();
    _routeMetadataInitialized = true;
  }

  final refreshNotifier = AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    refreshListenable: refreshNotifier,
    redirect: _createRedirectHandler(ref),
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
            path: AppRoutes.routePreviewPath,
            name: AppRoutes.routePreview,
            builder: (context, state) {
              final query = state.uri.queryParameters;
              final originLat = double.tryParse(query['originLat'] ?? '');
              final originLng = double.tryParse(query['originLng'] ?? '');
              final destinationLat = double.tryParse(query['destinationLat'] ?? '');
              final destinationLng = double.tryParse(query['destinationLng'] ?? '');
              if (originLat == null || originLng == null || destinationLat == null || destinationLng == null) {
                return const TruckerDashboardScreen();
              }
              return TruckerRoutePreviewScreen(
                args: TruckerRoutePreviewArgs(
                  routeLabel: query['routeLabel'] ?? '',
                  destinationLabel: query['destinationLabel'] ?? '',
                  originLat: originLat,
                  originLng: originLng,
                  destinationLat: destinationLat,
                  destinationLng: destinationLng,
                ),
                mapsLauncher: ref.read(mapsLauncherServiceProvider),
              );
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
          // NOTE: /profile must be registered BEFORE /profile/:userId.
          // GoRouter matches routes in declaration order; if the parameterized
          // route came first, "/profile" would never match.
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
          GoRoute(
            path: AppRoutes.publicProfilePath,
            name: AppRoutes.publicProfile,
            redirect: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              if (userId.trim().isEmpty) {
                return AppRoutes.profilePath;
              }
              return null;
            },
            builder: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              return _PublicProfileRouteScreen(userId: userId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => AppRouteErrorScreen(
      attemptedPath: state.uri.toString(),
    ),
  );
});

class _PublicProfileRouteScreen extends ConsumerWidget {
  final String userId;

  const _PublicProfileRouteScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));

    return profileAsync.when(
      data: (result) => result.when(
        success: (profile) {
          if (profile == null) {
            return const _PublicProfileRouteNotFoundScreen();
          }

          if (profile.role.trim().toLowerCase() == 'supplier') {
            return SupplierPublicProfileScreen(supplierId: userId);
          }

          return TruckerPublicProfileScreen(truckerId: userId);
        },
        failure: (failure) => _PublicProfileRouteErrorScreen(message: failure.message),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _PublicProfileRouteErrorScreen(message: error.toString()),
    );
  }
}

class _PublicProfileRouteErrorScreen extends StatelessWidget {
  final String message;

  const _PublicProfileRouteErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicProfileRouteNotFoundScreen extends StatelessWidget {
  const _PublicProfileRouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Profile not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
