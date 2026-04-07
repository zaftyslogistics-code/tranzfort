import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_super_ops_repository.dart';
import '../../../core/repositories/splitted/super_ops_models.dart';
import '../../../core/services/admin_trucker_matching_service.dart';
import 'super_ops_queue_provider.dart';

final superOpsLoadDetailProvider =
    FutureProvider.family<SuperOpsLoadDetail?, String>((ref, loadId) {
      return ref.read(adminSuperOpsRepositoryProvider).fetchLoadDetail(loadId);
    });

class SuperOpsDispatchSearchQuery {
  final String loadId;
  final String text;
  final String requiredTruckType;
  final List<int> requiredTyres;

  const SuperOpsDispatchSearchQuery({
    required this.loadId,
    required this.text,
    required this.requiredTruckType,
    required this.requiredTyres,
  });

  @override
  bool operator ==(Object other) {
    return other is SuperOpsDispatchSearchQuery &&
        other.loadId == loadId &&
        other.text == text &&
        other.requiredTruckType == requiredTruckType &&
        _listEquals(other.requiredTyres, requiredTyres);
  }

  @override
  int get hashCode =>
      Object.hash(loadId, text, requiredTruckType, Object.hashAll(requiredTyres));
}

final superOpsDispatchCandidatesProvider =
    FutureProvider.family<
      List<DispatchTruckerCandidate>,
      SuperOpsDispatchSearchQuery
    >((ref, query) async {
      final repository = ref.read(adminSuperOpsRepositoryProvider);
      final candidates = await repository.searchDispatchCandidates(
        loadId: query.loadId,
        requiredTruckType: query.requiredTruckType,
        requiredTyres: query.requiredTyres,
      );
      final detail = await repository.fetchLoadDetail(query.loadId);
      return ref.read(adminTruckerMatchingServiceProvider).rankByProximity(
            candidates: candidates,
            originLat: detail?.originLat,
            originLng: detail?.originLng,
          );
    });

final superOpsSuppliersProvider = FutureProvider<List<SuperOpsSupplierOption>>((
  ref,
) {
  return ref.read(adminSuperOpsRepositoryProvider).fetchSuppliers();
});

final superOpsActionProvider =
    StateNotifierProvider<SuperOpsActionNotifier, AsyncValue<void>>(
      (ref) => SuperOpsActionNotifier(ref),
    );

class SuperOpsActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SuperOpsActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> acceptRequest(String loadId) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSuperOpsRepositoryProvider)
        .acceptRequest(loadId);
    state = const AsyncData(null);
    if (ok) _refreshAfterMutation(loadId);
    return ok;
  }

  Future<bool> rejectRequest(String loadId) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSuperOpsRepositoryProvider)
        .rejectRequest(loadId);
    state = const AsyncData(null);
    if (ok) _refreshAfterMutation(loadId);
    return ok;
  }

  Future<bool> forceAssign({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSuperOpsRepositoryProvider)
        .forceAssign(
          loadId: loadId,
          truckerId: truckerId,
          truckId: truckId,
        );
    state = const AsyncData(null);
    if (ok) _refreshAfterMutation(loadId);
    return ok;
  }

  Future<bool> confirmPayout(String loadId) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSuperOpsRepositoryProvider)
        .confirmPayout(loadId);
    state = const AsyncData(null);
    if (ok) _refreshAfterMutation(loadId);
    return ok;
  }

  Future<bool> disputePod(String loadId) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSuperOpsRepositoryProvider)
        .disputePod(loadId);
    state = const AsyncData(null);
    if (ok) _refreshAfterMutation(loadId);
    return ok;
  }

  Future<bool> postOnBehalf(SuperOpsPostLoadPayload payload) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSuperOpsRepositoryProvider)
        .postLoadOnBehalf(payload);
    state = const AsyncData(null);
    if (ok) {
      _ref.invalidate(superOpsQueueCountsProvider);
      _ref.invalidate(superOpsQueueProvider);
    }
    return ok;
  }

  void _refreshAfterMutation(String loadId) {
    _ref.invalidate(superOpsQueueCountsProvider);
    for (final tab in SuperOpsTab.values) {
      _ref.invalidate(
        superOpsQueueProvider(SuperOpsQueueQuery(tab: tab, search: '')),
      );
    }
    _ref.invalidate(superOpsLoadDetailProvider(loadId));
  }
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
