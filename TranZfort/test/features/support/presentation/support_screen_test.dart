import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/support/data/support_attachment_upload_service.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';
import 'package:tranzfort/src/features/support/presentation/support_screen.dart';
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

class _NoopSupportBackend implements SupportBackend {
  final List<Map<String, dynamic>> ticketRows;
  final Map<String, Map<String, dynamic>> ticketById;
  final Map<String, List<Map<String, dynamic>>> messagesByTicket;

  const _NoopSupportBackend({
    this.ticketRows = const <Map<String, dynamic>>[],
    this.ticketById = const <String, Map<String, dynamic>>{},
    this.messagesByTicket = const <String, List<Map<String, dynamic>>>{},
  });

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({required String userId, int limit = 20, DateTime? before}) async {
    var rows = ticketRows;
    if (before != null) {
      rows = rows
          .where(
            (row) => DateTime.parse((row['updated_at'] ?? '').toString()).isBefore(before),
          )
          .toList(growable: false);
    }
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchTicket({required String userId, required String ticketId}) async {
    return ticketById[ticketId];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({
    required String userId,
    required String ticketId,
    int limit = 50,
  }) async {
    return messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessagesPaginated({
    required String userId,
    required String ticketId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    final messages = messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
    return messages.take(limit).toList(growable: false);
  }

  @override
  Future<String> createTicket({
    required String category,
    required String messageBody,
    String? relatedLoadId,
    String? relatedTripId,
    String? attachmentPath,
    SupportTicketPriority? priority,
  }) async {
    return 'ticket-created';
  }

  @override
  Future<String> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  }) async {
    return 'reply-created';
  }
}

class _RecordingSupportBackend implements SupportBackend {
  final List<Map<String, dynamic>> ticketRows;
  final Map<String, Map<String, dynamic>> ticketById;
  final Map<String, List<Map<String, dynamic>>> messagesByTicket;
  String? lastReplyTicketId;
  String? lastReplyMessageBody;
  String? lastReplyAttachmentPath;

  _RecordingSupportBackend({
    this.ticketRows = const <Map<String, dynamic>>[],
    this.ticketById = const <String, Map<String, dynamic>>{},
    this.messagesByTicket = const <String, List<Map<String, dynamic>>>{},
  });

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({required String userId, int limit = 20, DateTime? before}) async {
    var rows = ticketRows;
    if (before != null) {
      rows = rows
          .where(
            (row) => DateTime.parse((row['updated_at'] ?? '').toString()).isBefore(before),
          )
          .toList(growable: false);
    }
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchTicket({required String userId, required String ticketId}) async {
    return ticketById[ticketId];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({
    required String userId,
    required String ticketId,
    int limit = 50,
  }) async {
    return messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessagesPaginated({
    required String userId,
    required String ticketId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    final messages = messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
    return messages.take(limit).toList(growable: false);
  }

  @override
  Future<String> createTicket({
    required String category,
    required String messageBody,
    String? relatedLoadId,
    String? relatedTripId,
    String? attachmentPath,
    SupportTicketPriority? priority,
  }) async {
    return 'ticket-created';
  }

  @override
  Future<String> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  }) async {
    lastReplyTicketId = ticketId;
    lastReplyMessageBody = messageBody;
    lastReplyAttachmentPath = attachmentPath;
    return 'reply-created';
  }
}

class _ThrowingDetailSupportBackend extends _NoopSupportBackend {
  const _ThrowingDetailSupportBackend();

  @override
  Future<Map<String, dynamic>?> fetchTicket({required String userId, required String ticketId}) async {
    throw const ServerFailure(message: 'PostgrestException: raw support detail leak');
  }
}

class _TestSupportTicketsController extends SupportTicketsController {
  int loadCalls = 0;
  int loadMoreCalls = 0;

  _TestSupportTicketsController(SupportTicketsState state)
      : super(SupportRepository(const _NoopSupportBackend(), () => 'user-1')) {
    this.state = state;
  }

  @override
  Future<void> load() async {
    loadCalls += 1;
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }
}

SupportTicket _ticket(
  String id, {
  SupportTicketStatus status = SupportTicketStatus.open,
  SupportTicketPriority priority = SupportTicketPriority.medium,
  DateTime? createdAt,
  DateTime? updatedAt,
  String category = 'trip_dispute',
}) {
  final when = createdAt ?? DateTime(2026, 3, 10, 9);
  return SupportTicket(
    id: id,
    category: category,
    status: status,
    priority: priority,
    relatedLoadId: 'load-1',
    relatedTripId: category == 'trip_dispute' ? 'trip-1' : null,
    resolutionSummary: null,
    createdAt: when,
    updatedAt: updatedAt ?? when,
    resolvedAt: null,
  );
}

UserProfile _currentUserProfile(AppUserRole role) {
  return UserProfile(
    id: 'user-1',
    fullName: 'Aarav Singh',
    mobile: '9999999999',
    email: 'aarav@example.com',
    roleType: role == AppUserRole.supplier ? 'supplier' : 'trucker',
    isBanned: false,
    accountDeletionStatus: 'active',
    trustSafetyStatus: 'normal',
  );
}

AuthStateSnapshot _currentAuthStateForProfile(UserProfile profile, AppUserRole role) {
  return AuthStateSnapshot(
    hasSession: true,
    role: role,
    isBanned: profile.isBanned,
    isDeactivated: profile.accountDeletionStatus == 'deactivated_pending_cleanup',
    isProfileComplete: true,
    isResolved: true,
    profile: profile,
  );
}

Widget _buildRouterApp({
  required GoRouter router,
  _TestSupportTicketsController? controller,
  required SupportRepository repository,
  AppUserRole role = AppUserRole.trucker,
  UserProfile? profile,
}) {
  final resolvedProfile = profile ?? _currentUserProfile(role);
  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        _currentAuthStateForProfile(resolvedProfile, role),
      ),
      currentProfileProvider.overrideWith(
        (ref) => Stream.value(resolvedProfile),
      ),
      supportRepositoryProvider.overrideWithValue(repository),
      if (controller != null) supportTicketsProvider.overrideWith((ref) => controller),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Map<String, dynamic> _ticketRow(
  String id, {
  String status = 'open',
  String priority = 'medium',
}) {
  return {
    'id': id,
    'category': 'trip_dispute',
    'status': status,
    'priority': priority,
    'related_load_id': 'load-1',
    'related_trip_id': 'trip-1',
    'resolution_summary': null,
    'created_at': '2026-03-10T09:00:00.000Z',
    'updated_at': '2026-03-10T09:00:00.000Z',
    'resolved_at': null,
  };
}

Widget _buildApp({
  _TestSupportTicketsController? controller,
  required SupportRepository repository,
  AppUserRole role = AppUserRole.trucker,
  UserProfile? profile,
}) {
  final resolvedProfile = profile ?? _currentUserProfile(role);
  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        _currentAuthStateForProfile(resolvedProfile, role),
      ),
      currentProfileProvider.overrideWith(
        (ref) => Stream.value(resolvedProfile),
      ),
      supportRepositoryProvider.overrideWithValue(repository),
      if (controller != null) supportTicketsProvider.overrideWith((ref) => controller),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SupportScreen(),
    ),
  );
}

Widget _buildRoutedApp({
  _TestSupportTicketsController? controller,
  required SupportRepository repository,
  AppUserRole role = AppUserRole.trucker,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.createSupportTicketPath,
        builder: (context, state) => const Scaffold(body: Text('Create support ticket opened')),
      ),
      GoRoute(
        path: '${AppRoutes.tripDetailPath}/:tripId',
        builder: (context, state) => Scaffold(body: Text('Trip detail opened: ${state.pathParameters['tripId']}')),
      ),
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: UserProfile(
            id: 'user-1',
            fullName: 'Aarav Singh',
            mobile: '9999999999',
            email: 'aarav@example.com',
            roleType: 'trucker',
            isBanned: false,
            accountDeletionStatus: 'active',
            trustSafetyStatus: 'normal',
          ),
        ),
      ),
      currentProfileProvider.overrideWith(
        (ref) => Stream.value(const 
          UserProfile(
            id: 'user-1',
            fullName: 'Aarav Singh',
            mobile: '9999999999',
            email: 'aarav@example.com',
            roleType: 'trucker',
            isBanned: false,
            accountDeletionStatus: 'active',
            trustSafetyStatus: 'normal',
          ),
        ),
      ),
      supportRepositoryProvider.overrideWithValue(repository),
      if (controller != null) supportTicketsProvider.overrideWith((ref) => controller),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

String _expectedLocalizedDateTime(WidgetTester tester, DateTime value) {
  final context = tester.element(find.byType(SupportScreen).first);
  final material = MaterialLocalizations.of(context);
  final localValue = value.toLocal();
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(localValue),
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
  return '${material.formatShortDate(localValue)} - $timeLabel';
}

void main() {
  testWidgets('renders sanitized support ticket list failure copy', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        failure: const UnknownFailure(message: 'PostgrestException: raw backend detail'),
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Support tickets unavailable'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Support tickets unavailable'), findsOneWidget);
    expect(
      find.text('We could not load your support tickets right now. Retry shortly to refresh your latest support and dispute activity.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: raw backend detail'), findsNothing);
  });

  testWidgets('renders support tickets and selected detail thread', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-1', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
          _ticket('ticket-2', status: SupportTicketStatus.inProgress, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
        messagesByTicket: {
          'ticket-1': [
            {
              'id': 'message-1',
              'support_ticket_id': 'ticket-1',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-1',
              'message_body': 'Please upload more proof.',
              'attachment_path': 'support-attachments/user-1/trip_dispute/evidence_1.jpg',
              'visibility_class': 'visible',
              'created_at': '2026-03-10T09:10:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Support and dispute follow-up'), findsOneWidget);
    expect(find.text('Create support ticket'), findsOneWidget);
    expect(find.text('Trust: Normal'), findsOneWidget);
    expect(find.text('Current trust status'), findsOneWidget);
    expect(find.text('Normal'), findsWidgets);
    expect(find.text('2 tickets'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('My tickets'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('My tickets'), findsOneWidget);
    expect(find.text('Trip dispute review - high priority'), findsAtLeastNWidgets(1));
    expect(find.text('Non-payment report - medium priority'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-list-open-trip-ticket-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('support-list-open-load-ticket-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('support-list-open-load-ticket-2')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Selected ticket and reply'), findsOneWidget);
    expect(find.text('Support team'), findsOneWidget);
    expect(find.text('Please upload more proof.'), findsOneWidget);
    expect(find.text('Dispute category: Trip dispute'), findsWidgets);
    expect(
      find.text('Category: Trip dispute. This trip dispute is waiting on your clarification or proof. Both sides can follow visible status updates, but raw evidence access may remain restricted during review.'),
      findsOneWidget,
    );
    expect(find.text('Evidence visibility'), findsOneWidget);
    expect(find.text('Visible thread summary'), findsOneWidget);
    expect(find.text('Visible replies: 1'), findsOneWidget);
    expect(find.text('Latest visible sender: Support team'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-open-related-trip-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('support-open-related-load-button')), findsOneWidget);
    expect(find.text('Visible attachment summary: One or more visible replies include an attachment reference.'), findsOneWidget);
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible on this ticket.'),
      findsOneWidget,
    );
    expect(
      find.text('If your dispute depends on additional documents or screenshots beyond the current single-image flow, describe those missing proofs clearly in your visible reply so support knows what else to review.'),
      findsOneWidget,
    );
    expect(find.text('Evidence attached to this reply. Raw file access may remain restricted during review.'), findsOneWidget);
    expect(find.text('If other supporting proofs are not attached here, summarize them in visible reply text so support can request or review them safely.'), findsOneWidget);
    expect(find.textContaining('support-attachments/user-1/trip_dispute/evidence_1.jpg'), findsNothing);
    expect(find.text('Current workflow'), findsOneWidget);
  });

  testWidgets('renders sanitized selected support detail failure copy', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-1', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
        ],
      ),
    );
    final repository = SupportRepository(const _ThrowingDetailSupportBackend(), () => 'user-1');
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SupportScreen(initialSelectedTicketId: 'ticket-1'),
        ),
      ],
    );

    await tester.pumpWidget(_buildRouterApp(router: router, controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Selected ticket and reply'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ticket detail unavailable'), findsOneWidget);
    expect(
      find.text('We could not load this ticket detail right now. Retry shortly to refresh the latest visible thread and workflow status.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: raw support detail leak'), findsNothing);
  });

  testWidgets('renders localized support fallback label for unknown ticket categories', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-unknown-1', category: 'unexpected_review_code'),
        ],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('My tickets'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Support - medium priority'), findsOneWidget);
    expect(find.text('Unexpected review code - medium priority'), findsNothing);
  });

  testWidgets('support screen reply composer attaches an image path and clears it after successful submit', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-reply-1', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
        ],
      ),
    );
    final backend = _RecordingSupportBackend(
      ticketRows: [
        _ticketRow('ticket-reply-1', status: 'waiting_for_user', priority: 'high'),
      ],
      ticketById: {
        'ticket-reply-1': {
          'id': 'ticket-reply-1',
          'category': 'trip_dispute',
          'status': 'waiting_for_user',
          'priority': 'high',
          'related_load_id': 'load-1',
          'related_trip_id': 'trip-1',
          'resolution_summary': null,
          'created_at': '2026-03-10T09:00:00.000Z',
          'updated_at': '2026-03-10T09:00:00.000Z',
          'resolved_at': null,
        },
      },
      messagesByTicket: {
        'ticket-reply-1': [
          {
            'id': 'message-reply-1',
            'support_ticket_id': 'ticket-reply-1',
            'sender_profile_id': null,
            'sender_admin_user_id': 'admin-1',
            'message_body': 'Please share the clearest next proof update.',
            'attachment_path': null,
            'visibility_class': 'visible',
            'created_at': '2026-03-10T09:10:00.000Z',
          },
        ],
      },
    );
    final repository = SupportRepository(backend, () => 'user-1');

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(SupportScreen)));
    container.read(supportReplyProvider('ticket-reply-1').notifier).addAttachment(_testAttachment(filePath: 'user-1/support_ticket/ticket-reply-1/evidence_77.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('Remove attachment'), findsOneWidget);
    expect(container.read(supportReplyProvider('ticket-reply-1')).attachments, isNotEmpty);

    await tester.enterText(find.byType(TextField).last, 'I have attached the clearest POD image you requested.');
    await tester.scrollUntilVisible(find.text('Send reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send reply'));
    await tester.pumpAndSettle();

    expect(backend.lastReplyTicketId, 'ticket-reply-1');
    expect(backend.lastReplyMessageBody, 'I have attached the clearest POD image you requested.');
    expect(backend.lastReplyAttachmentPath, 'user-1/support_ticket/ticket-reply-1/evidence_77.jpg');
    expect(container.read(supportReplyProvider('ticket-reply-1')).attachments, isEmpty);
    expect(container.read(supportReplyProvider('ticket-reply-1')).messageBody, isEmpty);
    expect(controller.loadCalls, greaterThanOrEqualTo(1));
    expect(find.text('Reply sent successfully'), findsOneWidget);
  });

  testWidgets('support screen reply composer allows removing an attached image before submit', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-reply-2', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-reply-2': {
            'id': 'ticket-reply-2',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(SupportScreen)));
    container.read(supportReplyProvider('ticket-reply-2').notifier).addAttachment(_testAttachment(filePath: 'user-1/support_ticket/ticket-reply-2/evidence_remove.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('Remove attachment'), findsOneWidget);
    expect(container.read(supportReplyProvider('ticket-reply-2')).attachments, isNotEmpty);

    await tester.scrollUntilVisible(find.text('Remove attachment'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove attachment'));
    await tester.pumpAndSettle();

    expect(find.text('No evidence image attached yet.'), findsOneWidget);
    expect(container.read(supportReplyProvider('ticket-reply-2')).attachments, isEmpty);
  });

  testWidgets('renders warned trust badge and current trust status on support screen', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildApp(
        controller: controller,
        repository: repository,
        profile: const UserProfile(
          id: 'user-1',
          fullName: 'Aarav Singh',
          mobile: '9999999999',
          email: 'aarav@example.com',
          roleType: 'trucker',
          isBanned: false,
          accountDeletionStatus: 'active',
          trustSafetyStatus: 'warned',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust: Warned'), findsOneWidget);
    expect(find.text('Current trust status'), findsOneWidget);
    expect(find.text('Warned'), findsWidgets);
  });

  testWidgets('renders restricted trust badge and current trust status on support screen', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildApp(
        controller: controller,
        repository: repository,
        profile: const UserProfile(
          id: 'user-1',
          fullName: 'Aarav Singh',
          mobile: '9999999999',
          email: 'aarav@example.com',
          roleType: 'trucker',
          isBanned: false,
          accountDeletionStatus: 'active',
          trustSafetyStatus: 'restricted',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust: Restricted'), findsOneWidget);
    expect(find.text('Current trust status'), findsOneWidget);
    expect(find.text('Restricted'), findsWidgets);
  });

  testWidgets('renders suspended trust badge and current trust status on support screen', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildApp(
        controller: controller,
        repository: repository,
        profile: const UserProfile(
          id: 'user-1',
          fullName: 'Aarav Singh',
          mobile: '9999999999',
          email: 'aarav@example.com',
          roleType: 'trucker',
          isBanned: false,
          accountDeletionStatus: 'active',
          trustSafetyStatus: 'suspended',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust: Suspended'), findsOneWidget);
    expect(find.text('Current trust status'), findsOneWidget);
    expect(find.text('Suspended'), findsWidgets);
  });

  testWidgets('renders banned trust badge and current trust status on support screen', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildApp(
        controller: controller,
        repository: repository,
        profile: const UserProfile(
          id: 'user-1',
          fullName: 'Aarav Singh',
          mobile: '9999999999',
          email: 'aarav@example.com',
          roleType: 'trucker',
          isBanned: true,
          accountDeletionStatus: 'active',
          trustSafetyStatus: 'banned',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust: Banned'), findsOneWidget);
    expect(find.text('Current trust status'), findsOneWidget);
    expect(find.text('Banned'), findsWidgets);
  });

  testWidgets('renders unknown fallback for unsupported trust status on support screen', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildApp(
        controller: controller,
        repository: repository,
        profile: const UserProfile(
          id: 'user-1',
          fullName: 'Aarav Singh',
          mobile: '9999999999',
          email: 'aarav@example.com',
          roleType: 'trucker',
          isBanned: false,
          accountDeletionStatus: 'active',
          trustSafetyStatus: 'mystery_flag',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust: Unknown'), findsOneWidget);
    expect(find.text('Current trust status'), findsOneWidget);
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Mystery Flag'), findsNothing);
  });

  testWidgets('support screen create support ticket CTA opens create support ticket route', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [_ticket('ticket-1')],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(_buildRoutedApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket'), findsOneWidget);

    await tester.tap(find.text('Create support ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket opened'), findsOneWidget);
  });

  testWidgets('support screen create support ticket CTA opens create support ticket route for suppliers', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [_ticket('ticket-1')],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildRoutedApp(controller: controller, repository: repository, role: AppUserRole.supplier),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket'), findsOneWidget);

    await tester.tap(find.text('Create support ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket opened'), findsOneWidget);
  });

  testWidgets('support screen selected ticket related trip action opens trip detail route', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [_ticket('ticket-1')],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildRoutedApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-open-related-trip-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-open-related-trip-button')));
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: trip-1'), findsOneWidget);
  });

  testWidgets('support screen selected ticket related trip action opens trip detail route for suppliers', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [_ticket('ticket-1')],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(
      _buildRoutedApp(controller: controller, repository: repository, role: AppUserRole.supplier),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-open-related-trip-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-open-related-trip-button')));
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: trip-1'), findsOneWidget);
  });

  testWidgets('support screen selected ticket related load action opens load detail route', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [_ticket('ticket-1')],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildRoutedApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-open-related-load-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-open-related-load-button')));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('support screen selected ticket related load action opens load detail route for suppliers', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [_ticket('ticket-1')],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(
      _buildRoutedApp(controller: controller, repository: repository, role: AppUserRole.supplier),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-open-related-load-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-open-related-load-button')));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('support screen ticket list related trip action opens trip detail route', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-1', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
          _ticket('ticket-2', status: SupportTicketStatus.inProgress, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildRoutedApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-list-open-trip-ticket-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-list-open-trip-ticket-1')));
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: trip-1'), findsOneWidget);
  });

  testWidgets('support screen ticket list related load action opens load detail route', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-1', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
          _ticket('ticket-2', status: SupportTicketStatus.inProgress, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-1': {
            'id': 'ticket-1',
            'category': 'trip_dispute',
            'status': 'waiting_for_user',
            'priority': 'high',
            'related_load_id': 'load-1',
            'related_trip_id': 'trip-1',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:00:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildRoutedApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-list-open-load-ticket-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-list-open-load-ticket-1')));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('support routed app preselects ticket from route extra', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-1', status: SupportTicketStatus.waitingForUser, priority: SupportTicketPriority.high),
          SupportTicket(
            id: 'ticket-2',
            category: 'non_payment',
            status: SupportTicketStatus.inProgress,
            priority: SupportTicketPriority.medium,
            relatedLoadId: 'load-2',
            relatedTripId: null,
            resolutionSummary: null,
            createdAt: DateTime(2026, 3, 10, 8),
            updatedAt: DateTime(2026, 3, 10, 8, 45),
            resolvedAt: null,
          ),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-2': {
            'id': 'ticket-2',
            'category': 'non_payment',
            'status': 'in_progress',
            'priority': 'medium',
            'related_load_id': 'load-2',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T08:00:00.000Z',
            'updated_at': '2026-03-10T08:45:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: AppRoutes.supportPath,
          builder: (context, state) => SupportScreen(
            initialSelectedTicketId: state.extra is String ? state.extra as String : null,
          ),
        ),
      ],
    );

    await tester.pumpWidget(_buildRouterApp(router: router, controller: controller, repository: repository));
    router.go(AppRoutes.supportPath, extra: 'ticket-2');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Selected ticket and reply'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ticket reference: ticket-2'), findsOneWidget);
    expect(find.text('Related load: load-2'), findsOneWidget);
    expect(find.text('Current workflow'), findsOneWidget);
    expect(
      find.text('Support or operations are actively reviewing this ticket. Watch for visible replies and be ready to clarify the timeline or proof if more detail is requested.'),
      findsOneWidget,
    );
  });

  testWidgets('renders latest updated support activity first in the ticket list', (tester) async {
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketRows: [
          {
            'id': 'ticket-created-later',
            'category': 'non_payment',
            'status': 'open',
            'priority': 'medium',
            'related_load_id': 'load-1',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T12:00:00.000Z',
            'updated_at': '2026-03-10T12:05:00.000Z',
            'resolved_at': null,
          },
          {
            'id': 'ticket-updated-later',
            'category': 'abusive_behavior',
            'status': 'open',
            'priority': 'medium',
            'related_load_id': 'load-1',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T08:00:00.000Z',
            'updated_at': '2026-03-10T13:00:00.000Z',
            'resolved_at': null,
          },
        ],
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('My tickets'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    final newerUpdateFinder = find.text('Abusive behavior report - medium priority');
    final olderUpdateFinder = find.text('Non-payment report - medium priority');

    expect(newerUpdateFinder, findsOneWidget);
    expect(olderUpdateFinder, findsOneWidget);
    expect(
      tester.getTopLeft(newerUpdateFinder).dy,
      lessThan(tester.getTopLeft(olderUpdateFinder).dy),
    );
  });

  testWidgets('renders fake payout proof report title on the selected ticket surface', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-30', status: SupportTicketStatus.inProgress, category: 'fake_payout_proof'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-30': {
            'id': 'ticket-30',
            'category': 'fake_payout_proof',
            'status': 'in_progress',
            'priority': 'medium',
            'related_load_id': 'load-30',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T10:00:00.000Z',
            'resolved_at': null,
          },
        },
        messagesByTicket: {
          'ticket-30': [
            {
              'id': 'message-30',
              'support_ticket_id': 'ticket-30',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-30',
              'message_body': 'Please keep the clearest payout-proof screenshot ready for review.',
              'attachment_path': null,
              'visibility_class': 'visible',
              'created_at': '2026-03-10T10:05:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Fake payout proof report - medium priority'), findsAtLeastNWidgets(1));
    expect(find.text('Please keep the clearest payout-proof screenshot ready for review.'), findsOneWidget);
  });

  testWidgets('renders spam or scam report title on the selected ticket surface', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-31', status: SupportTicketStatus.open, category: 'spam_or_scam'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-31': {
            'id': 'ticket-31',
            'category': 'spam_or_scam',
            'status': 'open',
            'priority': 'medium',
            'related_load_id': 'load-31',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T11:00:00.000Z',
            'updated_at': '2026-03-10T11:30:00.000Z',
            'resolved_at': null,
          },
        },
        messagesByTicket: {
          'ticket-31': [
            {
              'id': 'message-31',
              'support_ticket_id': 'ticket-31',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-31',
              'message_body': 'We have started reviewing the reported spam and scam indicators on this ticket.',
              'attachment_path': null,
              'visibility_class': 'visible',
              'created_at': '2026-03-10T11:35:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Spam or scam report - medium priority'), findsAtLeastNWidgets(1));
    expect(find.text('We have started reviewing the reported spam and scam indicators on this ticket.'), findsOneWidget);
  });

  testWidgets('renders abusive behavior report title on the selected ticket surface', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-32', status: SupportTicketStatus.inProgress, category: 'abusive_behavior'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-32': {
            'id': 'ticket-32',
            'category': 'abusive_behavior',
            'status': 'in_progress',
            'priority': 'medium',
            'related_load_id': 'load-32',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T12:00:00.000Z',
            'updated_at': '2026-03-10T12:30:00.000Z',
            'resolved_at': null,
          },
        },
        messagesByTicket: {
          'ticket-32': [
            {
              'id': 'message-32',
              'support_ticket_id': 'ticket-32',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-32',
              'message_body': 'We are reviewing the reported abusive behavior and any related context shared on this ticket.',
              'attachment_path': null,
              'visibility_class': 'visible',
              'created_at': '2026-03-10T12:35:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Abusive behavior report - medium priority'), findsAtLeastNWidgets(1));
    expect(find.text('We are reviewing the reported abusive behavior and any related context shared on this ticket.'), findsOneWidget);
  });

  testWidgets('localizes remaining support dispute category fallback labels', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          SupportTicket(
            id: 'ticket-21',
            category: 'delay_or_no_show',
            status: SupportTicketStatus.waitingForUser,
            priority: SupportTicketPriority.medium,
            relatedLoadId: 'load-21',
            relatedTripId: 'trip-21',
            resolutionSummary: null,
            createdAt: DateTime(2026, 3, 10, 9),
            updatedAt: DateTime(2026, 3, 10, 9, 30),
            resolvedAt: null,
          ),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-21': {
            'id': 'ticket-21',
            'category': 'delay_or_no_show',
            'status': 'waiting_for_user',
            'priority': 'medium',
            'related_load_id': 'load-21',
            'related_trip_id': 'trip-21',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:30:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('My tickets'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Trip dispute review - medium priority'), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Dispute category: Delay or no-show'), findsWidgets);
    expect(
      find.textContaining('Category: Delay or no-show. This trip dispute is waiting on your clarification or proof.'),
      findsOneWidget,
    );
  });

  testWidgets('localizes additional support dispute fallback labels across the ticket list', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          SupportTicket(
            id: 'ticket-41',
            category: 'loaded_quantity_mismatch',
            status: SupportTicketStatus.waitingForUser,
            priority: SupportTicketPriority.medium,
            relatedLoadId: 'load-41',
            relatedTripId: 'trip-41',
            resolutionSummary: null,
            createdAt: DateTime(2026, 3, 10, 9),
            updatedAt: DateTime(2026, 3, 10, 9, 30),
            resolvedAt: null,
          ),
          SupportTicket(
            id: 'ticket-42',
            category: 'unloaded_quantity_mismatch',
            status: SupportTicketStatus.waitingForUser,
            priority: SupportTicketPriority.medium,
            relatedLoadId: 'load-42',
            relatedTripId: 'trip-42',
            resolutionSummary: null,
            createdAt: DateTime(2026, 3, 10, 10),
            updatedAt: DateTime(2026, 3, 10, 10, 30),
            resolvedAt: null,
          ),
          SupportTicket(
            id: 'ticket-43',
            category: 'document_mismatch',
            status: SupportTicketStatus.waitingForUser,
            priority: SupportTicketPriority.medium,
            relatedLoadId: 'load-43',
            relatedTripId: 'trip-43',
            resolutionSummary: null,
            createdAt: DateTime(2026, 3, 10, 11),
            updatedAt: DateTime(2026, 3, 10, 11, 30),
            resolvedAt: null,
          ),
          SupportTicket(
            id: 'ticket-44',
            category: 'damage_or_shortage',
            status: SupportTicketStatus.waitingForUser,
            priority: SupportTicketPriority.medium,
            relatedLoadId: 'load-44',
            relatedTripId: 'trip-44',
            resolutionSummary: null,
            createdAt: DateTime(2026, 3, 10, 12),
            updatedAt: DateTime(2026, 3, 10, 12, 30),
            resolvedAt: null,
          ),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-41': {
            'id': 'ticket-41',
            'category': 'loaded_quantity_mismatch',
            'status': 'waiting_for_user',
            'priority': 'medium',
            'related_load_id': 'load-41',
            'related_trip_id': 'trip-41',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:30:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('My tickets'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Dispute category: Loaded quantity mismatch'), findsWidgets);
    expect(find.text('Dispute category: Unloaded quantity mismatch'), findsOneWidget);
    expect(find.text('Dispute category: Document mismatch'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Dispute category: Damage or shortage'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Dispute category: Damage or shortage'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Category: Loaded quantity mismatch. This trip dispute is waiting on your clarification or proof.'), findsOneWidget);
  });

  testWidgets('renders in-progress workflow guidance for active support review', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-9', status: SupportTicketStatus.inProgress, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-9': {
            'id': 'ticket-9',
            'category': 'non_payment',
            'status': 'in_progress',
            'priority': 'medium',
            'related_load_id': 'load-9',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T09:30:00.000Z',
            'resolved_at': null,
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Current workflow'), findsOneWidget);
    expect(
      find.text('Support or operations are actively reviewing this ticket. Watch for visible replies and be ready to clarify the timeline or proof if more detail is requested.'),
      findsOneWidget,
    );
    expect(find.text('Support is waiting for your reply'), findsNothing);
  });

  testWidgets('renders resolved outcome section for closed ticket summaries', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-11', status: SupportTicketStatus.resolved, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-11': {
            'id': 'ticket-11',
            'category': 'non_payment',
            'status': 'resolved',
            'priority': 'medium',
            'related_load_id': 'load-11',
            'related_trip_id': null,
            'resolution_summary': 'Support confirmed the final settlement proof and closed the ticket.',
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T11:00:00.000Z',
            'resolved_at': '2026-03-10T11:00:00.000Z',
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Resolution outcome'), findsOneWidget);
    expect(
      find.textContaining(
        'Resolved on: ${_expectedLocalizedDateTime(tester, DateTime.utc(2026, 3, 10, 11))}',
      ),
      findsOneWidget,
    );
    expect(find.text('Support confirmed the final settlement proof and closed the ticket.'), findsAtLeastNWidgets(1));
    expect(find.text('Replies are closed for this ticket'), findsOneWidget);
    expect(find.text('Reply to support'), findsNothing);
  });

  testWidgets('renders resolved empty-thread guidance when no visible messages were posted', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-12', status: SupportTicketStatus.resolved, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-12': {
            'id': 'ticket-12',
            'category': 'non_payment',
            'status': 'resolved',
            'priority': 'medium',
            'related_load_id': 'load-12',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T10:00:00.000Z',
            'resolved_at': '2026-03-10T10:00:00.000Z',
          },
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Visible thread summary'), findsOneWidget);
    expect(find.text('Visible replies: 0'), findsOneWidget);
    expect(find.text('Last visible update: No visible replies yet.'), findsOneWidget);
    expect(find.text('Latest visible sender: No visible sender yet.'), findsOneWidget);
    expect(find.text('Visible attachment summary: No visible replies include an attachment reference yet.'), findsOneWidget);
    expect(find.text('No visible thread yet'), findsOneWidget);
    expect(find.text('No visible thread was recorded before this ticket was resolved or closed.'), findsOneWidget);
  });

  testWidgets('renders resolved dispute banner copy for closed dispute tickets', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-13', status: SupportTicketStatus.resolved),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-13': {
            'id': 'ticket-13',
            'category': 'trip_dispute',
            'status': 'resolved',
            'priority': 'high',
            'related_load_id': 'load-13',
            'related_trip_id': 'trip-13',
            'resolution_summary': 'Support closed the dispute after reviewing the final delivery context.',
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T12:00:00.000Z',
            'resolved_at': '2026-03-10T12:00:00.000Z',
          },
        },
        messagesByTicket: {
          'ticket-13': [
            {
              'id': 'message-13',
              'support_ticket_id': 'ticket-13',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-13',
              'message_body': 'Final dispute review completed.',
              'attachment_path': 'support-attachments/user-1/trip_dispute/final-evidence.jpg',
              'visibility_class': 'visible',
              'created_at': '2026-03-10T11:30:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Dispute review closed'), findsOneWidget);
    expect(
      find.text('Category: Trip dispute. This trip dispute has reached a final support outcome. Both sides can still follow the recorded ticket context, but raw evidence access may remain restricted.'),
      findsOneWidget,
    );
    expect(
      find.text('Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this ticket.'),
      findsOneWidget,
    );
    expect(
      find.text('Raw attachments and sensitive proof may remain restricted even after the review outcome is recorded on the ticket.'),
      findsOneWidget,
    );
    expect(
      find.text('If you believe important proof was not considered before closure, start a fresh support follow-up only when you have a genuinely new issue or clarification to raise.'),
      findsOneWidget,
    );
    expect(
      find.text('Evidence attached to this reply. Raw file access may remain restricted even after the review outcome is recorded on this ticket.'),
      findsOneWidget,
    );
    expect(
      find.text('If you still need to reference other supporting proofs after closure, open a fresh follow-up only when you have genuinely new context that was not captured on this ticket.'),
      findsOneWidget,
    );
    expect(find.text('Dispute review in progress'), findsNothing);
  });

  testWidgets('renders in-progress dispute banner copy for active dispute tickets', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-15', status: SupportTicketStatus.inProgress),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-15': {
            'id': 'ticket-15',
            'category': 'trip_dispute',
            'status': 'in_progress',
            'priority': 'high',
            'related_load_id': 'load-15',
            'related_trip_id': 'trip-15',
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T10:30:00.000Z',
            'resolved_at': null,
          },
        },
        messagesByTicket: {
          'ticket-15': [
            {
              'id': 'message-15',
              'support_ticket_id': 'ticket-15',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-15',
              'message_body': 'Support is reviewing the delivery context and visible proof on this dispute.',
              'attachment_path': null,
              'visibility_class': 'visible',
              'created_at': '2026-03-10T10:20:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Dispute review in progress'), findsOneWidget);
    expect(
      find.text('Category: Trip dispute. This trip dispute is under active support review. Both sides can follow visible status updates, but raw evidence access may remain restricted during review.'),
      findsOneWidget,
    );
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible on this ticket.'),
      findsOneWidget,
    );
    expect(
      find.text('Raw attachments and sensitive proof may remain restricted while this review stays active on the ticket.'),
      findsOneWidget,
    );
    expect(
      find.text('If your dispute depends on additional documents or screenshots beyond the current single-image flow, describe those missing proofs clearly in your visible reply so support knows what else to review.'),
      findsOneWidget,
    );
    expect(find.text('Dispute waiting for your reply'), findsNothing);
    expect(find.text('Dispute review closed'), findsNothing);
  });

  testWidgets('keeps generic attachment copy on non-dispute support tickets', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: [
          _ticket('ticket-14', status: SupportTicketStatus.inProgress, category: 'non_payment'),
        ],
      ),
    );
    final repository = SupportRepository(
      const _NoopSupportBackend(
        ticketById: {
          'ticket-14': {
            'id': 'ticket-14',
            'category': 'non_payment',
            'status': 'in_progress',
            'priority': 'medium',
            'related_load_id': 'load-14',
            'related_trip_id': null,
            'resolution_summary': null,
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T10:00:00.000Z',
            'resolved_at': null,
          },
        },
        messagesByTicket: {
          'ticket-14': [
            {
              'id': 'message-14',
              'support_ticket_id': 'ticket-14',
              'sender_profile_id': null,
              'sender_admin_user_id': 'admin-14',
              'message_body': 'Please keep payout proof ready.',
              'attachment_path': 'support-attachments/user-1/non_payment/proof.jpg',
              'visibility_class': 'visible',
              'created_at': '2026-03-10T10:15:00.000Z',
            },
          ],
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Selected ticket and reply'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Evidence attached to this reply. Raw file access may remain restricted during review.'), findsOneWidget);
    expect(
      find.text('If other supporting proofs are not attached here, summarize them in visible reply text so support can request or review them safely.'),
      findsOneWidget,
    );
    expect(find.text('If you still need to reference other supporting proofs after closure, open a fresh follow-up only when you have genuinely new context that was not captured on this ticket.'), findsNothing);
  });

  testWidgets('load older tickets button requests another page', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: true,
        tickets: [
          _ticket('ticket-1'),
        ],
      ),
    );
    final repository = SupportRepository(
      _NoopSupportBackend(
        ticketById: {
          'ticket-1': _ticketRow('ticket-1'),
        },
      ),
      () => 'user-1',
    );

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load older tickets'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Load older tickets'));
    await tester.pumpAndSettle();

    expect(controller.loadMoreCalls, 1);
  });

  testWidgets('renders support empty state when there are no tickets', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(_buildApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('No support tickets yet'), findsOneWidget);
    expect(find.text('Create support ticket'), findsAtLeastNWidgets(1));
    expect(
      find.text('Create a support ticket to start a new support or dispute follow-up and track future updates here.'),
      findsOneWidget,
    );
  });

  testWidgets('support screen empty-state CTA opens create support ticket route', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
        tickets: const <SupportTicket>[],
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(_buildRoutedApp(controller: controller, repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Create support ticket').first);
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket opened'), findsOneWidget);
  });

  testWidgets('support screen empty-state CTA opens create support ticket route for suppliers', (tester) async {
    final controller = _TestSupportTicketsController(
      SupportTicketsState.initial().copyWith(
        isLoading: false,
        hasMore: false,
      ),
    );
    final repository = SupportRepository(const _NoopSupportBackend(), () => 'user-1');

    await tester.pumpWidget(
      _buildRoutedApp(controller: controller, repository: repository, role: AppUserRole.supplier),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Create support ticket').first);
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket opened'), findsOneWidget);
  });
}

