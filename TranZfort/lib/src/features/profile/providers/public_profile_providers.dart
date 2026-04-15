import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../data/public_profile_models.dart';
import '../data/public_profile_repository.dart';

/// Provider for fetching a public profile by user ID.
final publicProfileProvider = FutureProvider.family<Result<PublicProfile?>, String>((ref, userId) async {
  final result = await ref.watch(publicProfileRepositoryProvider).getPublicProfile(userId);
  return result;
});
