import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/support_repository.dart';

class SupportTicketsState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final List<SupportTicket> tickets;
  final AppFailure? failure;

  const SupportTicketsState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.tickets,
    required this.failure,
  });

  factory SupportTicketsState.initial() {
    return const SupportTicketsState(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      tickets: <SupportTicket>[],
      failure: null,
    );
  }

  SupportTicketsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    List<SupportTicket>? tickets,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return SupportTicketsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      tickets: tickets ?? this.tickets,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class SupportTicketsController extends StateNotifier<SupportTicketsState> {
  static const int _pageSize = 20;

  final SupportRepository _repository;

  SupportTicketsController(this._repository) : super(SupportTicketsState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getTickets(limit: _pageSize);
    result.when(
      success: (tickets) {
        state = state.copyWith(
          isLoading: false,
          tickets: tickets,
          hasMore: tickets.length >= _pageSize,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore || state.tickets.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final lastUpdatedAt = state.tickets.last.updatedAt;
    final result = await _repository.getTickets(
      limit: _pageSize,
      before: lastUpdatedAt,
    );
    result.when(
      success: (tickets) {
        state = state.copyWith(
          isLoadingMore: false,
          tickets: _mergeTickets(
            incoming: tickets,
            existing: state.tickets,
          ),
          hasMore: tickets.length >= _pageSize,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          failure: failure,
        );
      },
    );
  }

  List<SupportTicket> _mergeTickets({
    required List<SupportTicket> incoming,
    required List<SupportTicket> existing,
  }) {
    final mergedById = <String, SupportTicket>{
      for (final ticket in existing) ticket.id: ticket,
    };
    for (final ticket in incoming) {
      mergedById[ticket.id] = ticket;
    }
    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }
}

final supportTicketsProvider =
    StateNotifierProvider.autoDispose<SupportTicketsController, SupportTicketsState>((ref) {
  return SupportTicketsController(ref.watch(supportRepositoryProvider));
});

final supportSelectedTicketIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final supportTicketDetailProvider = FutureProvider.autoDispose.family<SupportTicketDetail, String>((ref, ticketId) async {
  final result = await ref.watch(supportRepositoryProvider).getTicketDetail(ticketId);
  return result.when(
    success: (detail) => detail,
    failure: (failure) => throw failure,
  );
});

class SupportTicketMessagesState {
  final bool isLoading;
  final bool isLoadingOlder;
  final List<SupportTicketMessage> messages;
  final bool hasMoreOlderMessages;
  final AppFailure? failure;

  const SupportTicketMessagesState({
    required this.isLoading,
    required this.isLoadingOlder,
    required this.messages,
    required this.hasMoreOlderMessages,
    required this.failure,
  });

  factory SupportTicketMessagesState.initial() {
    return const SupportTicketMessagesState(
      isLoading: true,
      isLoadingOlder: false,
      messages: <SupportTicketMessage>[],
      hasMoreOlderMessages: true,
      failure: null,
    );
  }

  SupportTicketMessagesState copyWith({
    bool? isLoading,
    bool? isLoadingOlder,
    List<SupportTicketMessage>? messages,
    bool? hasMoreOlderMessages,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return SupportTicketMessagesState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      messages: messages ?? this.messages,
      hasMoreOlderMessages: hasMoreOlderMessages ?? this.hasMoreOlderMessages,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class SupportTicketMessagesController extends StateNotifier<SupportTicketMessagesState> {
  final SupportRepository _repository;
  final String _ticketId;

  SupportTicketMessagesController(this._repository, this._ticketId)
      : super(SupportTicketMessagesState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getTicketMessagesPaginated(
      _ticketId,
      limit: 50,
    );
    result.when(
      success: (messages) {
        state = state.copyWith(
          isLoading: false,
          messages: messages,
          hasMoreOlderMessages: messages.length >= 50,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  Future<void> loadOlderMessages() async {
    if (state.isLoadingOlder || !state.hasMoreOlderMessages || state.messages.isEmpty) {
      return;
    }

    final oldestMessage = state.messages.first;
    state = state.copyWith(isLoadingOlder: true, clearFailure: true);

    final result = await _repository.getTicketMessagesPaginated(
      _ticketId,
      limit: 50,
      beforeCreatedAt: oldestMessage.createdAt,
      beforeMessageId: oldestMessage.id,
    );

    result.when(
      success: (olderMessages) {
        final merged = <SupportTicketMessage>[...olderMessages, ...state.messages];
        state = state.copyWith(
          isLoadingOlder: false,
          messages: merged,
          hasMoreOlderMessages: olderMessages.length == 50,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoadingOlder: false,
          failure: failure,
        );
      },
    );
  }
}

final supportTicketMessagesProvider = StateNotifierProvider.autoDispose
    .family<SupportTicketMessagesController, SupportTicketMessagesState, String>((ref, ticketId) {
  return SupportTicketMessagesController(ref.watch(supportRepositoryProvider), ticketId);
});
