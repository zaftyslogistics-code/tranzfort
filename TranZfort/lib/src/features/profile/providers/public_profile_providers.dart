import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../data/public_profile_models.dart';
import '../data/public_profile_repository.dart';

/// Provider for fetching a public profile by user ID.
/// Passes the current user's ID as [viewerId] so the backend can return
/// relationship-aware capability flags (canViewContact, canReview, canMessage).
final publicProfileProvider = FutureProvider.family<Result<PublicProfile?>, String>((ref, userId) async {
  final viewerId = ref.watch(currentAuthStateProvider).hasSession
      ? ref.watch(supabaseClientProvider)?.auth.currentUser?.id
      : null;
  final result = await ref.watch(publicProfileRepositoryProvider).getPublicProfile(
    userId,
    viewerId: viewerId,
  );
  return result;
});
