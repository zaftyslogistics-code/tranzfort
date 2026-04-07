import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/repositories/user_support_repository.dart';
import '../../auth/providers/auth_providers.dart';

final userSupportRepositoryProvider = Provider<UserSupportRepository>((ref) {
  return UserSupportRepository(ref.watch(supabaseClientProvider));
});

final mySupportTicketsProvider = FutureProvider<List<UserSupportTicketListItem>>((
  ref,
) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) {
    return const [];
  }

  final result = await ref
      .watch(userSupportRepositoryProvider)
      .fetchMyTickets(user.id);

  return switch (result) {
    Success(data: final tickets) => tickets,
    Failure() => const <UserSupportTicketListItem>[],
  };
});

final supportTicketDetailProvider =
    FutureProvider.family<UserSupportTicketDetail?, String>((ref, ticketId) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) {
    return null;
  }

  final result = await ref
      .watch(userSupportRepositoryProvider)
      .fetchTicketDetail(ticketId: ticketId, userId: user.id);

  return switch (result) {
    Success(data: final detail) => detail,
    Failure() => null,
  };
});

class UserSupportActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  UserSupportActionNotifier(this._ref) : super(const AsyncData(null));

  Future<String?> createTicket({
    required String subject,
    required String description,
    required String category,
  }) async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      return null;
    }

    state = const AsyncLoading();
    final result = await _ref.read(userSupportRepositoryProvider).createTicket(
          userId: user.id,
          subject: subject,
          description: description,
          category: category,
        );

    switch (result) {
      case Success(data: final ticketId):
        state = const AsyncData(null);
        _ref.invalidate(mySupportTicketsProvider);
        _ref.invalidate(supportTicketDetailProvider(ticketId));
        return ticketId;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to create support ticket', StackTrace.current);
        return null;
    }
  }

  Future<bool> sendReply({
    required String ticketId,
    required String text,
  }) async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      return false;
    }

    state = const AsyncLoading();
    final result = await _ref.read(userSupportRepositoryProvider).sendReply(
          ticketId: ticketId,
          userId: user.id,
          text: text,
        );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(mySupportTicketsProvider);
        _ref.invalidate(supportTicketDetailProvider(ticketId));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to send support reply', StackTrace.current);
        return false;
    }
  }
}

final userSupportActionProvider =
    StateNotifierProvider<UserSupportActionNotifier, AsyncValue<void>>((ref) {
  return UserSupportActionNotifier(ref);
});
