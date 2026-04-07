import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_support_repository.dart';

final supportTicketCountsProvider = FutureProvider<SupportTicketCounts>((ref) {
  return ref.read(adminSupportRepositoryProvider).fetchCounts();
});

final supportQueueProvider =
    FutureProvider.family<List<SupportTicketListItem>, SupportTicketQueueQuery>(
      (ref, query) {
        return ref.read(adminSupportRepositoryProvider).fetchQueue(query);
      },
    );
