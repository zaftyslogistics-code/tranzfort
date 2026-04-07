import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/services/database_service.dart';
import '../../../core/error/result.dart';

final payoutDbProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(supabaseClientProvider));
});

final payoutProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) return null;

  final result = await ref
      .watch(payoutDbProvider)
      .getSingle(
        'payout_profiles',
        filterColumn: 'profile_id',
        filterValue: user.id,
      );

  return switch (result) {
    Success(data: final data) => data,
    Failure() => null,
  };
});
