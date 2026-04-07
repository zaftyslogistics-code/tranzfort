import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/presentation/ban_check_wrapper.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/phone_entry_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/verification/presentation/supplier_verification_screen.dart';
import '../../features/verification/presentation/trucker_verification_screen.dart';
import '../../features/fleet/presentation/my_fleet_screen.dart';
import '../../features/fleet/presentation/add_truck_screen.dart';
import '../../features/payout/presentation/payout_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/marketplace/presentation/post_load_screen.dart';
import '../../features/marketplace/presentation/find_loads_screen.dart';
import '../../features/marketplace/presentation/my_loads_screen.dart';
import '../../features/marketplace/presentation/load_detail_screen.dart';
import '../../features/trips/presentation/my_trips_screen.dart';
import '../../features/trips/presentation/trucker_dashboard_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/bot/presentation/bot_chat_screen.dart';
import '../../features/support/presentation/support_ticket_detail_screen.dart';
import '../../features/support/presentation/support_tickets_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/navigation/presentation/route_preview_screen.dart';
import '../config/supabase_config.dart';
import '../utils/animations.dart';
import 'package:flutter/foundation.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;
  RouterNotifier(this.ref) {
    ref.listen(authSessionProvider, (_, next) => notifyListeners());
    ref.listen(userProfileProvider, (_, next) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isConfigured = ref.watch(supabaseConfiguredProvider);

  if (!isConfigured) {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
      ],
      redirect: (context, state) {
        return state.uri.path == '/splash' ? null : '/splash';
      },
    );
  }

  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authStateAsync = ref.read(authSessionProvider);
      final userProfileAsync = ref.read(userProfileProvider);

      final isLoggingIn =
          state.uri.path == '/auth' ||
          state.uri.path == '/auth/phone-entry' ||
          state.uri.path == '/otp' ||
          state.uri.path == '/role-selection';
      final isSplash = state.uri.path == '/splash';

      if (authStateAsync.isLoading) {
        return isSplash ? null : '/splash';
      }

      final session = authStateAsync.value?.session;

      if (session == null) {
        if (!isLoggingIn) return '/auth';
        return null; // Let them login
      }

      if (userProfileAsync.isLoading) {
        return isSplash ? null : '/splash';
      }

      final profile = userProfileAsync.value;

      if (profile == null) {
        // Wait for profile to load (should happen via trigger in DB)
        return isSplash ? null : '/splash';
      }

      // Check Profile Completeness Gate
      final role = profile['user_role_type'] as String?;
      final phone = profile['mobile'] as String?;

      if (phone == null || phone.isEmpty) {
        if (state.uri.path != '/auth/phone-entry' && state.uri.path != '/otp') {
          return '/auth/phone-entry'; // Needs phone capture
        }
        return null;
      }

      if (role == null || role.isEmpty) {
        if (state.uri.path != '/role-selection') {
          return '/role-selection'; // Needs to select role
        }
        return null;
      }

      // Fully onboarded user trying to access login screens
      if (isLoggingIn || isSplash) {
        return role == 'supplier' ? '/my-loads' : '/trucker-dashboard';
      }

      if (state.uri.path == '/dashboard') {
        return role == 'supplier' ? '/my-loads' : '/trucker-dashboard';
      }

      return null; // Proceed to target route
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/phone-entry',
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          key: state.pageKey,
          child: const PhoneEntryScreen(),
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          return fadeSlideTransitionPage(
            key: state.pageKey,
            child: OtpScreen(phone: phone),
          );
        },
      ),
      GoRoute(
        path: '/role-selection',
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          key: state.pageKey,
          child: const RoleSelectionScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return BanCheckWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            redirect: (context, state) {
              final role = (ref.read(userProfileProvider).value?['user_role_type'] ?? '').toString();
              return role == 'supplier' ? '/my-loads' : '/trucker-dashboard';
            },
          ),
          GoRoute(
            path: '/verification/supplier',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const SupplierVerificationScreen(),
            ),
          ),
          GoRoute(
            path: '/verification/trucker',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const TruckerVerificationScreen(),
            ),
          ),
          GoRoute(
            path: '/my-fleet',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const MyFleetScreen(),
            ),
          ),
          GoRoute(
            path: '/my-fleet/add',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const AddTruckScreen(),
            ),
          ),
          GoRoute(
            path: '/payout-profile',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const PayoutProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/supplier-dashboard',
            redirect: (context, state) => '/my-loads',
          ),
          GoRoute(
            path: '/trucker-dashboard',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const TruckerDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/post-load',
            pageBuilder: (context, state) {
              final draft = state.extra is Map<String, dynamic>
                  ? state.extra as Map<String, dynamic>
                  : null;
              return fadeSlideTransitionPage(
                key: state.pageKey,
                child: PostLoadScreen(initialDraft: draft),
              );
            },
          ),
          GoRoute(
            path: '/find-loads',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const FindLoadsScreen(),
            ),
          ),
          GoRoute(
            path: '/my-loads',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const MyLoadsScreen(),
            ),
          ),
          GoRoute(
            path: '/load-detail/:loadId',
            pageBuilder: (context, state) {
              final loadId = state.pathParameters['loadId'] ?? '';
              return fadeSlideTransitionPage(
                key: state.pageKey,
                child: LoadDetailScreen(loadId: loadId),
              );
            },
          ),
          GoRoute(
            path: '/my-trips',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const MyTripsScreen(),
            ),
          ),
          GoRoute(
            path: '/trip-detail/:tripId',
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId'] ?? '';
              return fadeSlideTransitionPage(
                key: state.pageKey,
                child: TripDetailScreen(tripId: tripId),
              );
            },
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const ChatListScreen(),
            ),
          ),
          GoRoute(
            path: '/chat/:conversationId',
            pageBuilder: (context, state) {
              final conversationId =
                  state.pathParameters['conversationId'] ?? '';
              return fadeSlideTransitionPage(
                key: state.pageKey,
                child: ChatScreen(conversationId: conversationId),
              );
            },
          ),
          GoRoute(
            path: '/bot-chat',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const BotChatScreen(),
            ),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const SupportTicketsScreen(),
            ),
          ),
          GoRoute(
            path: '/support/:ticketId',
            pageBuilder: (context, state) {
              final ticketId = state.pathParameters['ticketId'] ?? '';
              return fadeSlideTransitionPage(
                key: state.pageKey,
                child: SupportTicketDetailScreen(ticketId: ticketId),
              );
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => fadeSlideTransitionPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/route-preview/:loadId',
            pageBuilder: (context, state) {
              final loadId = state.pathParameters['loadId'] ?? '';
              return fadeSlideTransitionPage(
                key: state.pageKey,
                child: RoutePreviewScreen(loadId: loadId),
              );
            },
          ),
        ],
      ),
    ],
  );
});
