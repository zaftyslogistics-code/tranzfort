import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/repositories/admin_management_repository.dart';

final adminAccountsProvider = FutureProvider<List<AdminAccountItem>>((ref) {
  return ref.read(adminManagementRepositoryProvider).fetchAdmins();
});

final adminManagementActionProvider =
    StateNotifierProvider<AdminManagementActionNotifier, AsyncValue<void>>(
      (ref) => AdminManagementActionNotifier(ref),
    );

class AdminManagementActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AdminManagementActionNotifier(this._ref) : super(const AsyncData(null));

  Future<AdminInviteResult> inviteAdmin({
    required String fullName,
    required String email,
    required AdminRole role,
  }) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(adminManagementRepositoryProvider)
        .inviteAdmin(fullName: fullName, email: email, role: role);
    state = const AsyncData(null);
    if (result.ok) {
      _ref.invalidate(adminAccountsProvider);
    }
    return result;
  }

  Future<AdminActionResult> setAdminActive({
    required String adminId,
    required bool isActive,
  }) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(adminManagementRepositoryProvider)
        .setAdminActive(adminId: adminId, isActive: isActive);
    state = const AsyncData(null);
    if (result.ok) {
      _ref.invalidate(adminAccountsProvider);
    }
    return result;
  }
}
