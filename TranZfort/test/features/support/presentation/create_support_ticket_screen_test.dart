import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/support/data/support_attachment_upload_service.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';
import 'package:tranzfort/src/features/support/presentation/create_support_ticket_screen.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/features/support/providers/support_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _CreateTicketBackend implements SupportBackend {
  String? lastCategory;
  String? lastMessageBody;
  String? lastRelatedLoadId;
  String? lastRelatedTripId;
  String? lastAttachmentPath;
  Object? error;

  @override
  Future<String> createTicket({
    required String category,
    required String messageBody,
    String? relatedLoadId,
    String? relatedTripId,
    String? attachmentPath,
    SupportTicketPriority? priority,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastCategory = category;
    lastMessageBody = messageBody;
    lastRelatedLoadId = relatedLoadId;
    lastRelatedTripId = relatedTripId;
    lastAttachmentPath = attachmentPath;
    return 'ticket-created';
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({required String ticketId}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessagesPaginated({
    required String userId,
    required String ticketId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> fetchTicket({required String userId, required String ticketId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({required String userId, int limit = 20, DateTime? before}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<String> replyToTicket({required String ticketId, required String messageBody, String? attachmentPath}) async {
    return 'reply-created';
  }
}

class _TestSupportTicketsController extends SupportTicketsController {
  int loadCalls = 0;

  _TestSupportTicketsController(super.repository) : super();

  @override
  Future<void> load() async {
    loadCalls += 1;
  }
}

class _FakeSupportAttachmentUploadService extends SupportAttachmentUploadService {
  String? lastRelocateCurrentPath;
  String? lastRelocateTargetPathSegment;
  Result<String> relocateResult;

  _FakeSupportAttachmentUploadService({Result<String>? relocateResult})
      : relocateResult = relocateResult ?? const Success<String>('user-1/support_ticket/ticket-created/evidence_99.jpg'),
        super(null);

  @override
  Future<Result<String>> relocateAttachment({required String currentPath, required String targetPathSegment}) async {
    lastRelocateCurrentPath = currentPath;
    lastRelocateTargetPathSegment = targetPathSegment;
    return relocateResult;
  }
}

void main() {
  testWidgets('create support ticket screen shows sanitized submission failure copy', (tester) async {
    final backend = _CreateTicketBackend()..error = Exception('PostgrestException: leaked detail');
    final repository = SupportRepository(backend, () => 'user-1');
    final router = GoRouter(
      initialLocation: AppRoutes.createSupportTicketPath,
      routes: [
        GoRoute(
          path: AppRoutes.createSupportTicketPath,
          builder: (context, state) => const CreateSupportTicketScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(2), 'The support inbox is missing the expected dispute follow-up entry.');
    await tester.scrollUntilVisible(find.text('Submit ticket'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit ticket'));
    await tester.pumpAndSettle();

    expect(find.text('We could not create this support ticket right now. Review the details and retry shortly.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('create support ticket screen submits and navigates to support route', (tester) async {
    final backend = _CreateTicketBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final supportTicketsController = _TestSupportTicketsController(repository);
    final uploadService = _FakeSupportAttachmentUploadService();
    Object? receivedExtra;
    final router = GoRouter(
      initialLocation: AppRoutes.createSupportTicketPath,
      routes: [
        GoRoute(
          path: AppRoutes.createSupportTicketPath,
          builder: (context, state) => const CreateSupportTicketScreen(),
        ),
        GoRoute(
          path: AppRoutes.supportPath,
          builder: (context, state) {
            receivedExtra = state.extra;
            return const Scaffold(body: Text('Support route opened'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
          supportTicketsProvider.overrideWith((ref) => supportTicketsController),
          supportAttachmentUploadServiceProvider.overrideWithValue(uploadService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No evidence image attached yet.'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateSupportTicketScreen)));
    container.read(createSupportTicketProvider.notifier).setAttachmentPath('user-1/report_issue/evidence_99.jpg');
    await tester.pumpAndSettle();
    expect(find.text('Remove attachment'), findsOneWidget);
    expect(container.read(createSupportTicketProvider).attachmentPath, 'user-1/report_issue/evidence_99.jpg');
    await tester.enterText(find.byType(TextField).at(0), 'load-77');
    await tester.enterText(find.byType(TextField).at(1), 'trip-77');
    await tester.enterText(find.byType(TextField).at(2), 'The support inbox is missing the expected dispute follow-up entry.');
    await tester.scrollUntilVisible(find.text('Submit ticket'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Support route opened'), findsOneWidget);
    expect(receivedExtra, 'ticket-created');
    expect(backend.lastCategory, 'general');
    expect(backend.lastRelatedLoadId, 'load-77');
    expect(backend.lastRelatedTripId, 'trip-77');
    expect(backend.lastAttachmentPath, 'user-1/report_issue/evidence_99.jpg');
    expect(backend.lastMessageBody, 'The support inbox is missing the expected dispute follow-up entry.');
    expect(supportTicketsController.loadCalls, greaterThanOrEqualTo(1));
    expect(uploadService.lastRelocateCurrentPath, 'user-1/report_issue/evidence_99.jpg');
    expect(uploadService.lastRelocateTargetPathSegment, 'support_ticket/ticket-created');
  });

  testWidgets('create support ticket screen allows removing an attached image before submit', (tester) async {
    final backend = _CreateTicketBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final router = GoRouter(
      initialLocation: AppRoutes.createSupportTicketPath,
      routes: [
        GoRoute(
          path: AppRoutes.createSupportTicketPath,
          builder: (context, state) => const CreateSupportTicketScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(CreateSupportTicketScreen)));
    container.read(createSupportTicketProvider.notifier).setAttachmentPath('user-1/report_issue/evidence_remove.jpg');
    await tester.pumpAndSettle();

    expect(find.text('Remove attachment'), findsOneWidget);
    expect(container.read(createSupportTicketProvider).attachmentPath, 'user-1/report_issue/evidence_remove.jpg');

    await tester.scrollUntilVisible(find.text('Remove attachment'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove attachment'));
    await tester.pumpAndSettle();

    expect(find.text('No evidence image attached yet.'), findsOneWidget);
    expect(container.read(createSupportTicketProvider).attachmentPath, isEmpty);
  });
}
