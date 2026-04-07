import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_support_repository.dart';
import 'support_queue_provider.dart';

final supportTicketDetailProvider =
    FutureProvider.family<SupportTicketDetail?, String>((ref, ticketId) {
      return ref
          .read(adminSupportRepositoryProvider)
          .fetchTicketDetail(ticketId);
    });

final supportTicketActionProvider =
    StateNotifierProvider<SupportTicketActionNotifier, AsyncValue<void>>(
      (ref) => SupportTicketActionNotifier(ref),
    );

class SupportTicketActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SupportTicketActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> assignToMe(String ticketId) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSupportRepositoryProvider)
        .assignToMe(ticketId);
    state = const AsyncData(null);
    if (ok) {
      _refreshAfterMutation(ticketId);
    }
    return ok;
  }

  Future<bool> changePriority({
    required String ticketId,
    required SupportTicketPriority priority,
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSupportRepositoryProvider)
        .changePriority(ticketId: ticketId, priority: priority);
    state = const AsyncData(null);
    if (ok) {
      _refreshAfterMutation(ticketId);
    }
    return ok;
  }

  Future<bool> sendReply({
    required String ticketId,
    required String text,
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSupportRepositoryProvider)
        .sendReply(ticketId: ticketId, text: text);
    state = const AsyncData(null);
    if (ok) {
      _refreshAfterMutation(ticketId);
    }
    return ok;
  }

  Future<bool> resolveTicket({
    required String ticketId,
    required String notes,
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminSupportRepositoryProvider)
        .resolveTicket(ticketId: ticketId, notes: notes);
    state = const AsyncData(null);
    if (ok) {
      _refreshAfterMutation(ticketId);
    }
    return ok;
  }

  void _refreshAfterMutation(String ticketId) {
    _ref.invalidate(supportTicketCountsProvider);
    for (final status in SupportTicketStatus.values) {
      _ref.invalidate(
        supportQueueProvider(
          SupportTicketQueueQuery(status: status, search: ''),
        ),
      );
    }
    _ref.invalidate(supportTicketDetailProvider(ticketId));
  }
}
