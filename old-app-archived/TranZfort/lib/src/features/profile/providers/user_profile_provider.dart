import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/error/result.dart';

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>(
  (
  ref,
) async {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return null;

  final role = (profile['user_role_type'] ?? '').toString();
  if (role != 'trucker') {
    return profile;
  }

  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) {
    return profile;
  }

  final truckerResult = await ref
      .read(authRepositoryProvider)
      .fetchTruckerDlExpiryDate(user.id);

  return switch (truckerResult) {
    Success(data: final dlExpiryDate) => {
      ...profile,
      'dl_expiry_date': dlExpiryDate,
    },
    Failure() => profile,
  };
});
