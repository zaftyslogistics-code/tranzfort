import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/support/data/support_attachment_upload_service.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';
import 'package:tranzfort/src/features/support/presentation/report_issue_screen.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/features/support/providers/support_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

TicketAttachmentMetadata _testAttachment({
  String id = 'att-1',
  String ticketId = 'ticket-1',
  String uploadedBy = 'user-1',
  String filePath = 'user-1/support/evidence_1.jpg',
}) {
  return TicketAttachmentMetadata(
    id: id,
    ticketId: ticketId,
    uploadedBy: uploadedBy,
    fileName: 'evidence_1.jpg',
    filePath: filePath,
    fileSize: 1024,
    mimeType: 'image/jpeg',
    uploadStatus: 'uploaded',
    scanStatus: 'clean',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class _ReportIssueBackend implements SupportBackend {
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
  Future<List<Map<String, dynamic>>> fetchTicketMessages({
    required String userId,
    required String ticketId,
    int limit = 50,
  }) async {
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

  @override
  Future<int> finalizeTicketAttachments({required String ticketId, required String sessionId}) async {
    return 0; // Mock implementation
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

void main() {
  testWidgets('report issue screen shows sanitized submission failure copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend()..error = Exception('PostgrestException: leaked detail');
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: 'load-77',
      relatedTripId: 'trip-77',
      sourceLabel: 'Chat - Nagpur > Pune',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(ReportIssueScreen)));
    container.read(reportIssueProvider(reportContext).notifier).addAttachment(_testAttachment(filePath: 'user-1/report_issue/evidence_77.jpg'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'The other party sent repeated scam messages and fake payment promises.');
    await tester.scrollUntilVisible(find.text('Submit report'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('We could not submit this report right now. Review the details and retry shortly.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('report issue screen submits and navigates to support route', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final supportTicketsController = _TestSupportTicketsController(repository);
    Object? receivedExtra;
    const reportContext = ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: 'load-77',
      relatedTripId: 'trip-77',
      sourceLabel: 'Chat - Nagpur > Pune',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
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
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(ReportIssueScreen)));
    container.read(reportIssueProvider(reportContext).notifier).addAttachment(_testAttachment(filePath: 'user-1/report_issue/evidence_88.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('One evidence image is attached for review.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'The other party sent repeated scam messages and fake payment promises.');
    await tester.scrollUntilVisible(find.text('Submit report'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('Support route opened'), findsOneWidget);
    expect(receivedExtra, 'ticket-created');
    expect(backend.lastCategory, 'spam_or_scam');
    expect(backend.lastRelatedLoadId, 'load-77');
    expect(backend.lastRelatedTripId, 'trip-77');
    expect(backend.lastAttachmentPath, 'user-1/report_issue/evidence_88.jpg');
    expect(backend.lastMessageBody, 'The other party sent repeated scam messages and fake payment promises.');
    expect(supportTicketsController.loadCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('report issue screen blocks submission until evidence is attached', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'fake_payout_proof',
      relatedLoadId: 'load-55',
      relatedTripId: 'trip-55',
      sourceLabel: 'Trip - Jaipur > Delhi',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Evidence (required)'), findsOneWidget);
    expect(find.text('Attach one evidence image before submitting this report.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'The payout screenshot is misleading and does not match the actual settlement state.');
    await tester.scrollUntilVisible(find.text('Submit report'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('Attach one evidence image before submitting this report'), findsOneWidget);
    expect(backend.lastCategory, isNull);
  });

  testWidgets('report issue screen supports the non-payment category', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'non_payment',
      relatedLoadId: 'load-88',
      relatedTripId: 'trip-88',
      sourceLabel: 'Trip - Nashik > Pune',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Non-payment'), findsOneWidget);
    expect(find.text('Helpful details to include'), findsOneWidget);
    expect(find.text('Evidence (required)'), findsOneWidget);
    expect(
      find.text('Describe the non-payment issue clearly, including what was due, what follow-up already happened, and attach one evidence image with the strongest payment proof you can share.'),
      findsOneWidget,
    );
    expect(find.text('Amount still unpaid:'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Payment is still pending even after the agreed unload confirmation and promised settlement window.');
    expect(find.text('Attach one evidence image before submitting this report.'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(ReportIssueScreen)));
    container.read(reportIssueProvider(reportContext).notifier).addAttachment(_testAttachment(filePath: 'user-1/report_issue/evidence_2.jpg'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Amount still unpaid:'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amount still unpaid:'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Submit report'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(backend.lastCategory, 'non_payment');
    expect(backend.lastRelatedLoadId, 'load-88');
    expect(backend.lastRelatedTripId, 'trip-88');
    expect(backend.lastAttachmentPath, 'user-1/report_issue/evidence_2.jpg');
    expect(backend.lastMessageBody, contains('Payment is still pending'));
  });

  testWidgets('report issue screen renders fake payout proof guidance and prompt chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'fake_payout_proof',
      relatedLoadId: 'load-66',
      relatedTripId: 'trip-66',
      sourceLabel: 'Trip - Surat > Ahmedabad',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fake payout proof'), findsOneWidget);
    expect(
      find.text('Explain why the payout proof looks fake or misleading and attach one evidence image with the most useful payment context you can share.'),
      findsOneWidget,
    );
    expect(find.text('Why the payout proof looks fake or inconsistent:'), findsOneWidget);
    expect(find.text('What payment status should be instead:'), findsOneWidget);
    expect(find.text('Other proof or chat context not attached:'), findsOneWidget);
  });

  testWidgets('report issue screen renders abusive behavior guidance and prompt chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'abusive_behavior',
      relatedLoadId: 'load-67',
      relatedTripId: 'trip-67',
      sourceLabel: 'Chat - Kanpur > Lucknow',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abusive behavior'), findsOneWidget);
    expect(
      find.text('Describe the abusive or unsafe behavior clearly, including where it happened and any context support should review.'),
      findsOneWidget,
    );
    expect(find.text('What happened during the incident:'), findsOneWidget);
    expect(find.text('When or where the behavior occurred:'), findsOneWidget);
    expect(find.text('What outcome or correction is needed:'), findsOneWidget);
  });

  testWidgets('report issue screen appends prompt chip text into the description', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'abusive_behavior',
      relatedLoadId: 'load-68',
      relatedTripId: 'trip-68',
      sourceLabel: 'Chat - Kota > Jaipur',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('What happened during the incident:'));
    await tester.pumpAndSettle();

    final descriptionField = tester.widget<TextField>(find.byType(TextField).first);
    expect(descriptionField.controller!.text, contains('What happened during the incident:'));
  });

  testWidgets('report issue screen remove evidence action restores the required-evidence state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _ReportIssueBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    const reportContext = ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: 'load-69',
      relatedTripId: 'trip-69',
      sourceLabel: 'Chat - Pune > Mumbai',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.reportIssuePath,
      routes: [
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) => const ReportIssueScreen(contextData: reportContext),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(ReportIssueScreen)));
    container.read(reportIssueProvider(reportContext).notifier).addAttachment(_testAttachment(filePath: 'user-1/report_issue/evidence_69.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('One evidence image is attached for review.'), findsOneWidget);
    expect(find.text('Remove evidence'), findsOneWidget);

    await tester.tap(find.text('Remove evidence'));
    await tester.pumpAndSettle();

    expect(find.text('Attach one evidence image before submitting this report.'), findsOneWidget);
    expect(find.text('Remove evidence'), findsNothing);
  });
}
