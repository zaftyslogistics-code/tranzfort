import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'splitted/index.dart';

final adminSuperOpsRepositoryProvider = Provider<AdminSuperOpsRepository>(
  (ref) => AdminSuperOpsRepository(ref),
);

class AdminSuperOpsRepository {
  final Ref _ref;
  late final SuperOpsQueueRepository _queueRepo;
  late final SuperOpsDispatchRepository _dispatchRepo;

  AdminSuperOpsRepository(this._ref) {
    _queueRepo = SuperOpsQueueRepository(_ref);
    _dispatchRepo = SuperOpsDispatchRepository(_ref);
  }

  // Queue operations
  Future<SuperOpsQueueCounts> fetchQueueCounts() => _queueRepo.fetchQueueCounts();
  Future<List<SuperOpsLoadSummary>> fetchQueue(SuperOpsQueueQuery query) => 
      _queueRepo.fetchQueue(query);
  Future<SuperOpsLoadDetail?> fetchLoadDetail(String loadId) => 
      _queueRepo.fetchLoadDetail(loadId);
  Future<bool> acceptRequest(String loadId) => _queueRepo.acceptRequest(loadId);
  Future<bool> rejectRequest(String loadId) => _queueRepo.rejectRequest(loadId);
  Future<bool> confirmPayout(String loadId) => _queueRepo.confirmPayout(loadId);
  Future<bool> disputePod(String loadId) => _queueRepo.disputePod(loadId);

  // Dispatch operations
  Future<List<DispatchTruckerCandidate>> searchDispatchCandidates({
    required String loadId,
    double? originLat,
    double? originLng,
    String? requiredTruckType,
    List<int>? requiredTyres,
    int? trucksNeeded,
    bool fallback = false,
  }) => _dispatchRepo.searchDispatchCandidates(
    loadId: loadId,
    originLat: originLat,
    originLng: originLng,
    requiredTruckType: requiredTruckType,
    requiredTyres: requiredTyres,
    trucksNeeded: trucksNeeded,
    fallback: fallback,
  );

  Future<bool> forceAssign({
    required String loadId,
    required String truckerId,
    required String truckId,
    int? truckCount = 1,
  }) => _dispatchRepo.forceAssign(
    loadId: loadId,
    truckerId: truckerId,
    truckId: truckId,
    truckCount: truckCount,
  );

  Future<List<SuperOpsSupplierOption>> fetchSuppliers() => 
      _dispatchRepo.fetchSuppliers();

  Future<bool> postLoadOnBehalf(SuperOpsPostLoadPayload payload) => 
      _dispatchRepo.postLoadOnBehalf(payload);
}
