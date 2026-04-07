import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:admin/src/features/support/providers/support_ticket_detail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminSupportRepository extends Mock implements AdminSupportRepository {}

void main() {
  group('SupportTicketActionNotifier', () {
    test('assignToMe success returns true', () async {
      final repository = MockAdminSupportRepository();
      when(() => repository.assignToMe('ticket-1'))
          .thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [adminSupportRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(supportTicketActionProvider.notifier);
      final ok = await notifier.assignToMe('ticket-1');

      expect(ok, isTrue);
      expect(container.read(supportTicketActionProvider), isA<AsyncData<void>>());
    });

    test('changePriority failure returns false', () async {
      final repository = MockAdminSupportRepository();
      when(
        () => repository.changePriority(
          ticketId: 'ticket-1',
          priority: SupportTicketPriority.high,
        ),
      ).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [adminSupportRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(supportTicketActionProvider.notifier);
      final ok = await notifier.changePriority(
        ticketId: 'ticket-1',
        priority: SupportTicketPriority.high,
      );

      expect(ok, isFalse);
      expect(container.read(supportTicketActionProvider), isA<AsyncData<void>>());
    });

    test('sendReply success returns true', () async {
      final repository = MockAdminSupportRepository();
      when(
        () => repository.sendReply(ticketId: 'ticket-1', text: 'Working on it'),
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [adminSupportRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(supportTicketActionProvider.notifier);
      final ok = await notifier.sendReply(
        ticketId: 'ticket-1',
        text: 'Working on it',
      );

      expect(ok, isTrue);
      expect(container.read(supportTicketActionProvider), isA<AsyncData<void>>());
    });

    test('resolveTicket failure returns false', () async {
      final repository = MockAdminSupportRepository();
      when(
        () => repository.resolveTicket(
          ticketId: 'ticket-1',
          notes: 'Resolved',
        ),
      ).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [adminSupportRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(supportTicketActionProvider.notifier);
      final ok = await notifier.resolveTicket(
        ticketId: 'ticket-1',
        notes: 'Resolved',
      );

      expect(ok, isFalse);
      expect(container.read(supportTicketActionProvider), isA<AsyncData<void>>());
    });
  });
}
