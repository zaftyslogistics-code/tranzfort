import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_support_repository.dart';

class AdminSupportQueueState {
  final SupportQueueQuery query;
  final bool isLoading;
  final List<AdminSupportTicketItem> items;
  final bool hasMore;
  final SupportQueueCounts counts;

  const AdminSupportQueueState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.hasMore,
    required this.counts,
  });

  factory AdminSupportQueueState.initial() {
    return AdminSupportQueueState(
      query: const SupportQueueQuery(tab: SupportQueueTab.open, search: ''),
      isLoading: false,
      items: const [],
      hasMore: false,
      counts: SupportQueueCounts.empty(),
    );
  }

  AdminSupportQueueState copyWith({
    SupportQueueQuery? query,
    bool? isLoading,
    List<AdminSupportTicketItem>? items,
    bool? hasMore,
    SupportQueueCounts? counts,
  }) {
    return AdminSupportQueueState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      counts: counts ?? this.counts,
    );
  }
}

class AdminSupportReplyState {
  final bool isLoading;

  const AdminSupportReplyState({this.isLoading = false});
}

class AdminSupportQueueController extends AutoDisposeAsyncNotifier<AdminSupportQueueState> {
  @override
  Future<AdminSupportQueueState> build() async {
    final query = AdminSupportQueueState.initial().query;
    final page = await ref.read(adminSupportRepositoryProvider).getSupportQueue(query);
    return AdminSupportQueueState.initial().copyWith(
      query: query,
      items: page.items,
      hasMore: page.hasMore,
      counts: page.counts,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminSupportQueueState.initial();
    await _reload(current.query.copyWith(search: value, page: 0));
  }

  Future<void> updateTab(SupportQueueTab tab) async {
    final current = state.value ?? AdminSupportQueueState.initial();
    await _reload(current.query.copyWith(tab: tab, page: 0));
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminSupportQueueState.initial();
    await _reload(current.query.copyWith(page: 0));
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoading: true));
    final nextQuery = current.query.copyWith(page: current.query.page + 1);
    try {
      final page = await ref.read(adminSupportRepositoryProvider).getSupportQueue(nextQuery);
      state = AsyncData(
        current.copyWith(
          query: nextQuery,
          isLoading: false,
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          counts: page.counts,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _reload(SupportQueueQuery query) async {
    final current = state.value ?? AdminSupportQueueState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    try {
      final page = await ref.read(adminSupportRepositoryProvider).getSupportQueue(query);
      state = AsyncData(
        current.copyWith(
          query: query,
          isLoading: false,
          items: page.items,
          hasMore: page.hasMore,
          counts: page.counts,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

class AdminSupportReplyController extends AutoDisposeNotifier<AdminSupportReplyState> {
  @override
  AdminSupportReplyState build() => const AdminSupportReplyState();

  Future<bool> replyToTicket({
    required String ticketId,
    required String messageBody,
  }) async {
    state = const AdminSupportReplyState(isLoading: true);
    try {
      return await ref.read(adminSupportRepositoryProvider).replyToSupportTicket(
            ticketId: ticketId,
            messageBody: messageBody,
          );
    } finally {
      state = const AdminSupportReplyState(isLoading: false);
    }
  }
}

final adminSupportQueueProvider = AutoDisposeAsyncNotifierProvider<
    AdminSupportQueueController,
    AdminSupportQueueState>(
  AdminSupportQueueController.new,
);

final adminSupportTicketDetailProvider =
    FutureProvider.autoDispose.family<AdminSupportTicketDetail?, String>((ref, ticketId) async {
  return ref.watch(adminSupportRepositoryProvider).getSupportTicketDetail(ticketId);
});

final adminSupportReplyProvider =
    AutoDisposeNotifierProvider<AdminSupportReplyController, AdminSupportReplyState>(
  AdminSupportReplyController.new,
);
