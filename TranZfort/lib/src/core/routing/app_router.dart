import 'package:flutter/material.dart';
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
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/bot/presentation/bot_chat_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/navigation/presentation/route_preview_screen.dart';
import '../../shared/widgets/dashboard_verification_banner.dart';
import '../config/supabase_config.dart';

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

  final authStateAsync = ref.watch(authSessionProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
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
        return '/dashboard'; // Redirect to dashboard
      }

      return null; // Proceed to target route
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/auth/phone-entry',
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return BanCheckWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              final profile = userProfileAsync.value;
              final role = (profile?['user_role_type'] ?? '').toString();
              final verificationStatus =
                  (profile?['verification_status'] ?? 'unverified').toString();
              final rejectionReason = profile?['verification_rejection_reason']
                  ?.toString();

              return Scaffold(
                appBar: AppBar(title: const Text('Dashboard')),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DashboardVerificationBanner(
                      status: verificationStatus,
                      rejectionReason: rejectionReason,
                    ),
                    const SizedBox(height: 16),
                    if (role == 'supplier')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                context.push('/verification/supplier'),
                            child: const Text('Supplier Verification'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => context.push('/post-load'),
                            child: const Text('Post Load'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => context.push('/my-loads'),
                            child: const Text('My Loads'),
                          ),
                        ],
                      ),
                    if (role == 'trucker') ...[
                      ElevatedButton(
                        onPressed: () => context.push('/verification/trucker'),
                        child: const Text('Trucker Verification'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push('/my-fleet'),
                        child: const Text('My Fleet'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push('/find-loads'),
                        child: const Text('Find Loads'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push('/my-trips'),
                        child: const Text('My Trips'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push('/messages'),
                        child: const Text('Messages'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push('/my-loads'),
                        child: const Text('My Loads'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => context.push('/payout-profile'),
                      child: const Text('Payout Profile'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => context.push('/profile'),
                      child: const Text('Profile'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => context.push('/notifications'),
                      child: const Text('Notifications'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('Settings'),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () async {
                         await ref.read(authRepositoryProvider).signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
          GoRoute(
            path: '/verification/supplier',
            builder: (context, state) => const SupplierVerificationScreen(),
          ),
          GoRoute(
            path: '/verification/trucker',
            builder: (context, state) => const TruckerVerificationScreen(),
          ),
          GoRoute(
            path: '/my-fleet',
            builder: (context, state) => const MyFleetScreen(),
          ),
          GoRoute(
            path: '/my-fleet/add',
            builder: (context, state) => const AddTruckScreen(),
          ),
          GoRoute(
            path: '/payout-profile',
            builder: (context, state) => const PayoutProfileScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/post-load',
            builder: (context, state) => const PostLoadScreen(),
          ),
          GoRoute(
            path: '/find-loads',
            builder: (context, state) => const FindLoadsScreen(),
          ),
          GoRoute(
            path: '/my-loads',
            builder: (context, state) => const MyLoadsScreen(),
          ),
          GoRoute(
            path: '/load-detail/:loadId',
            builder: (context, state) {
              final loadId = state.pathParameters['loadId'] ?? '';
              return LoadDetailScreen(loadId: loadId);
            },
          ),
          GoRoute(
            path: '/my-trips',
            builder: (context, state) => const MyTripsScreen(),
          ),
          GoRoute(
            path: '/trip-detail/:tripId',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId'] ?? '';
              return TripDetailScreen(tripId: tripId);
            },
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/chat/:conversationId',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId'] ?? '';
              return ChatScreen(conversationId: conversationId);
            },
          ),
          GoRoute(
            path: '/bot-chat',
            builder: (context, state) => const BotChatScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/route-preview/:loadId',
            builder: (context, state) {
              final loadId = state.pathParameters['loadId'] ?? '';
              return RoutePreviewScreen(loadId: loadId);
            },
          ),
        ],
      ),
    ],
  );
});
