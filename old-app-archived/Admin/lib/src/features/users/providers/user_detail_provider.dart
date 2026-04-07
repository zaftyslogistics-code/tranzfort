import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_user_management_repository.dart';
import 'user_list_provider.dart';

final userDetailProvider = FutureProvider.family<AdminUserDetail?, String>((
  ref,
  userId,
) {
  return ref
      .read(adminUserManagementRepositoryProvider)
      .fetchUserDetail(userId);
});

final userActionProvider =
    StateNotifierProvider<UserActionNotifier, AsyncValue<void>>(
      (ref) => UserActionNotifier(ref),
    );

class UserActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  UserActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> setBanStatus({
    required String userId,
    required bool banned,
    String? reason,
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminUserManagementRepositoryProvider)
        .setBanStatus(userId: userId, banned: banned, reason: reason);
    state = const AsyncData(null);

    if (ok) {
      _ref.invalidate(userDetailProvider(userId));
      _ref.read(userListRefreshProvider.notifier).state++;
    }
    return ok;
  }
}
