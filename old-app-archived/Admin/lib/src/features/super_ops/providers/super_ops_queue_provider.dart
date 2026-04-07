import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_super_ops_repository.dart';
import '../../../core/repositories/splitted/super_ops_models.dart';

final superOpsQueueCountsProvider = FutureProvider<SuperOpsQueueCounts>((ref) {
  return ref.read(adminSuperOpsRepositoryProvider).fetchQueueCounts();
});

final superOpsQueueProvider =
    FutureProvider.family<List<SuperOpsLoadSummary>, SuperOpsQueueQuery>((
      ref,
      query,
    ) {
      return ref.read(adminSuperOpsRepositoryProvider).fetchQueue(query);
    });
