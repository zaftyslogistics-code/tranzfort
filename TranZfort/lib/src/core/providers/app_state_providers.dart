import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../error/app_failure.dart';
import '../../features/auth/data/auth_repository.dart';

enum AppUserRole {
  supplier,
  trucker,
  unknown,
}

class AppConfigState {
  final SupabaseConfig supabaseConfig;

  const AppConfigState({required this.supabaseConfig});

  bool get isSupabaseConfigured => supabaseConfig.isConfigured;
}

class ProfileCompletenessState {
  final bool hasName;
  final bool hasMobile;
  final bool hasRole;

  const ProfileCompletenessState({
    required this.hasName,
    required this.hasMobile,
    required this.hasRole,
  });

  bool get isComplete => hasName && hasMobile && hasRole;
}

class AuthStateSnapshot {
  final bool hasSession;
  final AppUserRole role;
  final bool isBanned;
  final bool isDeactivated;
  final bool isProfileComplete;
  final bool isResolved;
  final UserProfile? profile;

  const AuthStateSnapshot({
    required this.hasSession,
    required this.role,
    required this.isBanned,
    required this.isDeactivated,
    required this.isProfileComplete,
    required this.isResolved,
    required this.profile,
  });

  factory AuthStateSnapshot.signedOut() {
    return const AuthStateSnapshot(
      hasSession: false,
      role: AppUserRole.unknown,
      isBanned: false,
      isDeactivated: false,
      isProfileComplete: false,
      isResolved: true,
      profile: null,
    );
  }

  factory AuthStateSnapshot.fromSessionAndProfile(
    Session? session,
    UserProfile? profile,
    {
    bool isResolved = true,
  }
  ) {
    if (session == null) {
      return AuthStateSnapshot.signedOut();
    }

    final user = session.user;
    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata ?? <String, dynamic>{};
    final mergedMetadata = <String, dynamic>{
      ...appMetadata,
      ...userMetadata,
    };

    final role = profile?.role ?? _parseRole(mergedMetadata);
    final isBanned = profile?.hasRestrictedTrustState ?? _parseBannedState(mergedMetadata);
    final isDeactivated = profile?.isDeactivated ?? _parseDeactivatedState(mergedMetadata);
    final isProfileComplete = profile?.isProfileComplete ?? _parseProfileCompletion(mergedMetadata);

    return AuthStateSnapshot(
      hasSession: true,
      role: role,
      isBanned: isBanned,
      isDeactivated: isDeactivated,
      isProfileComplete: isProfileComplete,
      isResolved: isResolved,
      profile: profile,
    );
  }

  factory AuthStateSnapshot.fromClient(SupabaseClient? client) {
    final session = client?.auth.currentSession;
    return AuthStateSnapshot.fromSessionAndProfile(
      session,
      null,
      isResolved: session == null,
    );
  }

  static AppUserRole _parseRole(Map<String, dynamic> metadata) {
    final rawRole = (metadata['user_role'] ?? metadata['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return switch (rawRole) {
      'supplier' => AppUserRole.supplier,
      'trucker' => AppUserRole.trucker,
      _ => AppUserRole.unknown,
    };
  }

  static bool _parseBannedState(Map<String, dynamic> metadata) {
    final bannedFlag = metadata['is_banned'];
    if (bannedFlag is bool) {
      return bannedFlag;
    }

    final trustState = (metadata['trust_safety_status'] ?? metadata['account_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return trustState == 'banned' || trustState == 'suspended';
  }

  static bool _parseProfileCompletion(Map<String, dynamic> metadata) {
    final completionFlag = metadata['profile_complete'] ?? metadata['onboarding_complete'];
    if (completionFlag is bool) {
      return completionFlag;
    }

    return false;
  }

  static bool _parseDeactivatedState(Map<String, dynamic> metadata) {
    final accountDeletionStatus = (metadata['account_deletion_status'] ?? metadata['deletion_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return accountDeletionStatus == 'deactivated_pending_cleanup';
  }
}

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final appConfigProvider = Provider<AppConfigState>((ref) {
  return AppConfigState(
    supabaseConfig: SupabaseConfig.fromEnvironment(),
  );
});

final authStateProvider = StreamProvider<AuthStateSnapshot>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  final sessionResult = repository.getCurrentSession();
  final session = sessionResult.valueOrNull;
  yield await _resolveAuthSnapshot(
    repository: repository,
    session: session,
  );

  await for (final authState in repository.onAuthStateChange()) {
    yield await _resolveAuthSnapshot(
      repository: repository,
      session: authState.session,
    );
  }
});

Future<AuthStateSnapshot> _resolveAuthSnapshot({
  required AuthRepository repository,
  required Session? session,
}) async {
  if (session == null) {
    return AuthStateSnapshot.signedOut();
  }

  final profileResult = await repository.getCurrentProfile();
  final failure = profileResult.failureOrNull;
  if (failure is UnauthorizedFailure) {
    await repository.signOut();
    return AuthStateSnapshot.signedOut();
  }

  if (failure != null && failure is! UnauthorizedFailure) {
    debugPrint('_resolveAuthSnapshot: profile fetch failed with non-auth error, preserving session: $failure');
    return AuthStateSnapshot.fromSessionAndProfile(
      session,
      null,
      isResolved: false,
    );
  }

  return AuthStateSnapshot.fromSessionAndProfile(
    session,
    profileResult.valueOrNull,
  );
}

final currentProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  return authStateAsync.whenData((snapshot) => snapshot.profile);
});

final profileCompletenessProvider = Provider<ProfileCompletenessState>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final authSnapshot = ref.watch(currentAuthStateProvider);

  return ProfileCompletenessState(
    hasName: profile?.hasName ?? false,
    hasMobile: profile?.hasMobile ?? false,
    hasRole: profile?.hasRole ?? authSnapshot.role != AppUserRole.unknown,
  );
});

final currentAuthStateProvider = Provider<AuthStateSnapshot>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull ??
      AuthStateSnapshot.fromClient(ref.watch(supabaseClientProvider));
});
