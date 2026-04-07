import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_user_management_repository.dart';

final userListRefreshProvider = StateProvider<int>((ref) => 0);

final userListProvider =
    FutureProvider.family<List<AdminUserListItem>, UserListQuery>((ref, query) {
      ref.watch(userListRefreshProvider);
      return ref.read(adminUserManagementRepositoryProvider).fetchUsers(query);
    });
