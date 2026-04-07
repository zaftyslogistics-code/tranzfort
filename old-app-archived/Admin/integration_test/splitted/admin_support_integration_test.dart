import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:admin/src/features/support/presentation/support_ticket_queue_screen.dart';
import 'package:admin/src/features/support/presentation/support_ticket_detail_screen.dart';
import 'package:admin/src/features/support/providers/support_ticket_detail_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin support integration tests', () {
    testWidgets('A-SUP-01: ticket queue shell render', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: SupportTicketQueueScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Support tickets'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });

    testWidgets('A-SUP-02: detail screen renders fallback state safely', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            supportTicketDetailProvider('ticket-1').overrideWith(
              (ref) async => const SupportTicketDetail(
                ticket: SupportTicketListItem(
                  id: 'ticket-1',
                  subject: 'Login Issue',
                  userName: 'Test User',
                  priority: SupportTicketPriority.medium,
                  status: SupportTicketStatus.open,
                  createdAt: null,
                  assignedAdminId: '',
                  assignedAdminName: '',
                ),
                description: 'Cannot login to the app',
                category: 'auth',
                userMobile: '+919999999999',
                userEmail: 'test@example.com',
                userRole: 'trucker',
                resolutionNotes: '',
                resolvedAt: null,
                messages: [],
              ),
            ),
          ],
          child: const MaterialApp(home: SupportTicketDetailScreen(ticketId: 'ticket-1')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Login Issue'), findsOneWidget);
      expect(find.text('Cannot login to the app'), findsOneWidget);
      expect(find.text('No messages yet.'), findsOneWidget);
    });
  });
}
