import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_super_load_repository.dart';

class AdminSuperLoadQueueState {
  final AdminSuperLoadQuery query;
  final bool isLoading;
  final List<AdminSuperLoadItem> items;
  final AdminSuperLoadCounts counts;

  const AdminSuperLoadQueueState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.counts,
  });

  factory AdminSuperLoadQueueState.initial() {
    return AdminSuperLoadQueueState(
      query: const AdminSuperLoadQuery(statusFilter: AdminSuperLoadStatusFilter.all, search: ''),
      isLoading: false,
      items: const [],
      counts: AdminSuperLoadCounts.empty(),
    );
  }

  AdminSuperLoadQueueState copyWith({
    AdminSuperLoadQuery? query,
    bool? isLoading,
    List<AdminSuperLoadItem>? items,
    AdminSuperLoadCounts? counts,
  }) {
    return AdminSuperLoadQueueState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      counts: counts ?? this.counts,
    );
  }
}

class AdminSuperLoadActionState {
  final bool isLoading;

  const AdminSuperLoadActionState({this.isLoading = false});
}

class AdminSuperLoadQueueController extends AutoDisposeAsyncNotifier<AdminSuperLoadQueueState> {
  @override
  Future<AdminSuperLoadQueueState> build() async {
    final query = AdminSuperLoadQueueState.initial().query;
    final page = await ref.read(adminSuperLoadRepositoryProvider).getSuperLoads(query);
    return AdminSuperLoadQueueState.initial().copyWith(
      query: query,
      items: page.items,
      counts: page.counts,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminSuperLoadQueueState.initial();
    await _reload(current.query.copyWith(search: value));
  }

  Future<void> updateStatusFilter(AdminSuperLoadStatusFilter filter) async {
    final current = state.value ?? AdminSuperLoadQueueState.initial();
    await _reload(current.query.copyWith(statusFilter: filter));
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminSuperLoadQueueState.initial();
    await _reload(current.query);
  }

  Future<void> _reload(AdminSuperLoadQuery query) async {
    final current = state.value ?? AdminSuperLoadQueueState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    final page = await ref.read(adminSuperLoadRepositoryProvider).getSuperLoads(query);
    state = AsyncData(current.copyWith(query: query, isLoading: false, items: page.items, counts: page.counts));
  }
}

class AdminSuperLoadActionController extends AutoDisposeNotifier<AdminSuperLoadActionState> {
  @override
  AdminSuperLoadActionState build() => const AdminSuperLoadActionState();

  Future<bool> markUnderReview(String loadId) async {
    state = const AdminSuperLoadActionState(isLoading: true);
    final ok = await ref.read(adminSuperLoadRepositoryProvider).markUnderReview(loadId);
    state = const AdminSuperLoadActionState(isLoading: false);
    return ok;
  }

  Future<bool> approveRequest(String loadId) async {
    state = const AdminSuperLoadActionState(isLoading: true);
    final ok = await ref.read(adminSuperLoadRepositoryProvider).approveRequest(loadId);
    state = const AdminSuperLoadActionState(isLoading: false);
    return ok;
  }

  Future<bool> rejectRequest(String loadId, {String? reason}) async {
    state = const AdminSuperLoadActionState(isLoading: true);
    final ok = await ref.read(adminSuperLoadRepositoryProvider).rejectRequest(loadId, reason: reason);
    state = const AdminSuperLoadActionState(isLoading: false);
    return ok;
  }

  Future<bool> activateSuperLoad(String loadId) async {
    state = const AdminSuperLoadActionState(isLoading: true);
    final ok = await ref.read(adminSuperLoadRepositoryProvider).activateSuperLoad(loadId);
    state = const AdminSuperLoadActionState(isLoading: false);
    return ok;
  }

  Future<bool> forceAssignSuperLoad({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) async {
    state = const AdminSuperLoadActionState(isLoading: true);
    final ok = await ref.read(adminSuperLoadRepositoryProvider).forceAssignSuperLoad(
          loadId: loadId,
          truckerId: truckerId,
          truckId: truckId,
        );
    state = const AdminSuperLoadActionState(isLoading: false);
    return ok;
  }
}

final adminSuperLoadQueueProvider = AutoDisposeAsyncNotifierProvider<AdminSuperLoadQueueController, AdminSuperLoadQueueState>(
  AdminSuperLoadQueueController.new,
);

final adminSuperLoadActionProvider = AutoDisposeNotifierProvider<AdminSuperLoadActionController, AdminSuperLoadActionState>(
  AdminSuperLoadActionController.new,
);

final adminSuperLoadDispatchCandidatesProvider =
    FutureProvider.autoDispose.family<List<AdminSuperLoadDispatchCandidate>, String>((ref, search) async {
  return ref.watch(adminSuperLoadRepositoryProvider).getDispatchCandidates(search);
});

final adminSuperLoadPodReviewProvider = FutureProvider.autoDispose<List<AdminSuperLoadPodReviewItem>>((ref) async {
  return ref.watch(adminSuperLoadRepositoryProvider).getPodReviewItems();
});
