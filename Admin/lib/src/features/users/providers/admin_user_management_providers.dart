import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_user_repository.dart';

class AdminUsersState {
  final AdminUserListQuery query;
  final bool isLoading;
  final List<AdminUserListItem> items;
  final bool hasMore;

  const AdminUsersState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.hasMore,
  });

  factory AdminUsersState.initial() {
    return const AdminUsersState(
      query: AdminUserListQuery(filter: AdminUserFilter.all, search: ''),
      isLoading: false,
      items: [],
      hasMore: false,
    );
  }

  AdminUsersState copyWith({
    AdminUserListQuery? query,
    bool? isLoading,
    List<AdminUserListItem>? items,
    bool? hasMore,
  }) {
    return AdminUsersState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminUsersController extends AutoDisposeAsyncNotifier<AdminUsersState> {
  @override
  Future<AdminUsersState> build() async {
    final query = const AdminUserListQuery(filter: AdminUserFilter.all, search: '');
    final page = await ref.read(adminUserRepositoryProvider).searchUsers(query);
    return AdminUsersState.initial().copyWith(
      query: query,
      items: page.items,
      hasMore: page.hasMore,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminUsersState.initial();
    await _reload(current.query.copyWith(search: value, page: 0));
  }

  Future<void> updateFilter(AdminUserFilter filter) async {
    final current = state.value ?? AdminUsersState.initial();
    await _reload(current.query.copyWith(filter: filter, page: 0));
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoading: true));
    final nextQuery = current.query.copyWith(page: current.query.page + 1);
    try {
      final nextPage = await ref.read(adminUserRepositoryProvider).searchUsers(nextQuery);
      state = AsyncData(
        current.copyWith(
          query: nextQuery,
          isLoading: false,
          items: [...current.items, ...nextPage.items],
          hasMore: nextPage.hasMore,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminUsersState.initial();
    await _reload(current.query.copyWith(page: 0));
  }

  Future<void> _reload(AdminUserListQuery query) async {
    final current = state.value ?? AdminUsersState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    try {
      final page = await ref.read(adminUserRepositoryProvider).searchUsers(query);
      state = AsyncData(
        current.copyWith(
          query: query,
          isLoading: false,
          items: page.items,
          hasMore: page.hasMore,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final adminUsersProvider = AutoDisposeAsyncNotifierProvider<AdminUsersController, AdminUsersState>(
  AdminUsersController.new,
);

final adminUserDetailProvider = FutureProvider.family<AdminUserDetail?, String>((ref, userId) {
  return ref.read(adminUserRepositoryProvider).getUserDetail(userId);
});

class AdminUserActionState {
  final bool isLoading;

  const AdminUserActionState({required this.isLoading});

  factory AdminUserActionState.initial() {
    return const AdminUserActionState(isLoading: false);
  }

  AdminUserActionState copyWith({bool? isLoading}) {
    return AdminUserActionState(isLoading: isLoading ?? this.isLoading);
  }
}

class AdminUserActionController extends StateNotifier<AdminUserActionState> {
  final Ref ref;

  AdminUserActionController(this.ref) : super(AdminUserActionState.initial());

  Future<bool> setBanStatus({
    required String userId,
    required bool isBanned,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      return await ref.read(adminUserRepositoryProvider).setBanStatus(
            userId: userId,
            isBanned: isBanned,
            reason: reason,
          );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final adminUserActionProvider = StateNotifierProvider<AdminUserActionController, AdminUserActionState>((ref) {
  return AdminUserActionController(ref);
});
