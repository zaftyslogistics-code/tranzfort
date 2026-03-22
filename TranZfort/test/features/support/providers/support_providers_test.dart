import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/support/data/support_attachment_upload_service.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/features/support/providers/support_providers.dart';

class _FakeSupportBackend implements SupportBackend {
  List<Map<String, dynamic>> ticketRows = const <Map<String, dynamic>>[];
  final Map<String, Map<String, dynamic>> ticketById = <String, Map<String, dynamic>>{};
  final Map<String, List<Map<String, dynamic>>> messagesByTicket = <String, List<Map<String, dynamic>>>{};
  Object? error;
  String? lastCreatedCategory;
  String? lastCreatedMessageBody;
  String? lastCreatedLoadId;
  String? lastCreatedTripId;
  String? lastCreatedAttachmentPath;
  String? lastReplyTicketId;
  String? lastReplyMessageBody;
  String? lastReplyAttachmentPath;

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({required String userId, int limit = 20, DateTime? before}) async {
    if (error != null) {
      throw error!;
    }
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
    if (error != null) {
      throw error!;
    }
    return ticketById[ticketId];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({required String ticketId}) async {
    if (error != null) {
      throw error!;
    }
    return messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
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
    if (error != null) {
      throw error!;
    }
    lastCreatedCategory = category;
    lastCreatedMessageBody = messageBody;
    lastCreatedLoadId = relatedLoadId;
    lastCreatedTripId = relatedTripId;
    lastCreatedAttachmentPath = attachmentPath;
    return 'ticket-created';
  }

  @override
  Future<String> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastReplyTicketId = ticketId;
    lastReplyMessageBody = messageBody;
    lastReplyAttachmentPath = attachmentPath;
    return 'reply-created';
  }
}

class _FakeSupportAttachmentUploadService extends SupportAttachmentUploadService {
  String? lastRelocateCurrentPath;
  String? lastRelocateTargetPathSegment;
  Result<String> relocateResult;

  _FakeSupportAttachmentUploadService({Result<String>? relocateResult})
      : relocateResult = relocateResult ?? const Success<String>('user-1/support_ticket/ticket-created/evidence_1.jpg'),
        super(null);

  @override
  Future<Result<String>> relocateAttachment({required String currentPath, required String targetPathSegment}) async {
    lastRelocateCurrentPath = currentPath;
    lastRelocateTargetPathSegment = targetPathSegment;
    return relocateResult;
  }
}

Map<String, dynamic> _ticketRow(
  String id, {
  String status = 'open',
  String priority = 'medium',
  String createdAt = '2026-03-10T09:00:00.000Z',
  String? updatedAt,
}) {
  return {
    'id': id,
    'category': 'trip_dispute',
    'status': status,
    'priority': priority,
    'related_load_id': 'load-1',
    'related_trip_id': 'trip-1',
    'resolution_summary': null,
    'created_at': createdAt,
    'updated_at': updatedAt ?? createdAt,
    'resolved_at': null,
  };
}

void main() {
  test('support tickets provider loads initial tickets and supports pagination', () async {
    final backend = _FakeSupportBackend()
      ..ticketRows = List.generate(
        21,
        (index) {
          final itemNumber = 21 - index;
          final hour = itemNumber.toString().padLeft(2, '0');
          return _ticketRow(
            'ticket-$itemNumber',
            createdAt: '2026-03-10T$hour:00:00.000Z',
          );
        },
      );
    final repository = SupportRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(supportTicketsProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(supportTicketsProvider).tickets, hasLength(20));
    expect(container.read(supportTicketsProvider).tickets.first.id, 'ticket-21');

    await container.read(supportTicketsProvider.notifier).loadMore();

    expect(container.read(supportTicketsProvider).tickets, hasLength(21));
    expect(container.read(supportTicketsProvider).tickets.last.id, 'ticket-1');
  });

  test('support ticket detail provider returns mapped detail', () async {
    final backend = _FakeSupportBackend()
      ..ticketById['ticket-1'] = _ticketRow('ticket-1', status: 'waiting_for_user')
      ..messagesByTicket['ticket-1'] = [
        {
          'id': 'message-1',
          'support_ticket_id': 'ticket-1',
          'sender_profile_id': null,
          'sender_admin_user_id': 'admin-1',
          'message_body': 'Please upload more proof.',
          'attachment_path': null,
          'visibility_class': 'visible',
          'created_at': '2026-03-10T09:10:00.000Z',
        },
      ];
    final repository = SupportRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(supportTicketsProvider, (_, _) {});
    addTearDown(container.dispose);
    addTearDown(subscription.close);

    final detail = await container.read(supportTicketDetailProvider('ticket-1').future);

    expect(detail.ticket.status, SupportTicketStatus.waitingForUser);
    expect(detail.messages.single.senderType, SupportMessageSenderType.support);
  });

  test('support tickets provider keeps latest updated activity first after pagination merge', () async {
    final backend = _FakeSupportBackend()
      ..ticketRows = [
        _ticketRow(
          'ticket-recent-update',
          createdAt: '2026-03-10T07:00:00.000Z',
          updatedAt: '2026-03-10T13:00:00.000Z',
        ),
        _ticketRow(
          'ticket-mid-update',
          createdAt: '2026-03-10T12:00:00.000Z',
          updatedAt: '2026-03-10T12:30:00.000Z',
        ),
        _ticketRow(
          'ticket-old-update',
          createdAt: '2026-03-10T11:00:00.000Z',
          updatedAt: '2026-03-10T11:30:00.000Z',
        ),
      ];
    final repository = SupportRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final controller = SupportTicketsController(repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.tickets.map((ticket) => ticket.id).toList(), [
      'ticket-recent-update',
      'ticket-mid-update',
      'ticket-old-update',
    ]);
  });

  test('support tickets provider surfaces backend failures', () async {
    final backend = _FakeSupportBackend()
      ..error = const PostgrestException(message: 'permission denied', code: '42501');
    final repository = SupportRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(supportTicketsProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(supportTicketsProvider).failure, isA<PermissionFailure>());
  });

  test('support ticket detail provider throws mapped failures', () async {
    final backend = _FakeSupportBackend()
      ..error = const PostgrestException(message: 'permission denied', code: '42501');
    final repository = SupportRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(supportTicketDetailProvider('ticket-1').future),
      throwsA(isA<PermissionFailure>()),
    );
  });

  test('create support ticket controller validates and submits through repository', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final uploadService = _FakeSupportAttachmentUploadService(
      relocateResult: const Success<String>('user-1/support_ticket/ticket-created/evidence_1.jpg'),
    );
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
        supportAttachmentUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(createSupportTicketProvider.notifier);
    controller.setCategory('technical');
    controller.setRelatedLoadId('load-42');
    controller.setRelatedTripId('trip-42');
    controller.setAttachmentPath('user-1/support/evidence_1.jpg');
    controller.setDescription('The trip detail timeline is missing the latest proof update.');

    final result = await controller.submit();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'ticket-created');
    expect(backend.lastCreatedCategory, 'technical');
    expect(backend.lastCreatedLoadId, 'load-42');
    expect(backend.lastCreatedTripId, 'trip-42');
    expect(backend.lastCreatedAttachmentPath, 'user-1/support/evidence_1.jpg');
    expect(backend.lastCreatedMessageBody, 'The trip detail timeline is missing the latest proof update.');
    expect(uploadService.lastRelocateCurrentPath, 'user-1/support/evidence_1.jpg');
    expect(uploadService.lastRelocateTargetPathSegment, 'support_ticket/ticket-created');
    expect(container.read(createSupportTicketProvider).attachmentPath, isEmpty);
  });

  test('report issue controller submits linked-context trust report through repository', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final uploadService = _FakeSupportAttachmentUploadService();
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
        supportAttachmentUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );
    addTearDown(container.dispose);

    const context = ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: 'load-99',
      relatedTripId: 'trip-99',
      sourceLabel: 'Chat • Nagpur → Pune',
    );
    final controller = container.read(reportIssueProvider(context).notifier);
    controller.setCategory('abusive_behavior');
    controller.setAttachmentPath('user-1/report_issue/evidence_1.jpg');
    controller.setDescription('The other party sent abusive messages and tried to pressure me off-platform.');

    final result = await controller.submit();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'ticket-created');
    expect(backend.lastCreatedCategory, 'abusive_behavior');
    expect(backend.lastCreatedLoadId, 'load-99');
    expect(backend.lastCreatedTripId, 'trip-99');
    expect(backend.lastCreatedAttachmentPath, 'user-1/report_issue/evidence_1.jpg');
    expect(backend.lastCreatedMessageBody, 'The other party sent abusive messages and tried to pressure me off-platform.');
    expect(uploadService.lastRelocateCurrentPath, 'user-1/report_issue/evidence_1.jpg');
    expect(uploadService.lastRelocateTargetPathSegment, 'support_ticket/ticket-created');
    expect(container.read(reportIssueProvider(context)).attachmentPath, isEmpty);
  });

  test('report issue controller surfaces finalize failure when attachment relocation fails', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final uploadService = _FakeSupportAttachmentUploadService(
      relocateResult: const Failure<String>(ServerFailure(message: 'move failed')),
    );
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
        supportAttachmentUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );
    addTearDown(container.dispose);

    const context = ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: 'load-55',
      relatedTripId: 'trip-55',
      sourceLabel: 'Trip • Jaipur → Delhi',
    );
    final controller = container.read(reportIssueProvider(context).notifier);
    controller.setAttachmentPath('user-1/report_issue/evidence_55.jpg');
    controller.setDescription('The evidence image is ready, but final attachment relocation should surface a safe failure state.');

    final result = await controller.submit();

    expect(result.isSuccess, isTrue);
    expect(uploadService.lastRelocateCurrentPath, 'user-1/report_issue/evidence_55.jpg');
    expect(uploadService.lastRelocateTargetPathSegment, 'support_ticket/ticket-created');
    expect(container.read(reportIssueProvider(context)).failure, isA<ServerFailure>());
    expect(container.read(reportIssueProvider(context)).failure?.message, 'Report created but failed to finalize attachment.');
    expect(container.read(reportIssueProvider(context)).attachmentPath, 'user-1/report_issue/evidence_55.jpg');
  });

  test('report issue controller requires an evidence attachment before submitting', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    const context = ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: 'load-44',
      relatedTripId: 'trip-44',
      sourceLabel: 'Trip • Indore → Bhopal',
    );
    final controller = container.read(reportIssueProvider(context).notifier);
    controller.setDescription('The other party is sending repeated misleading payment claims and scam-like follow-up.');

    final result = await controller.submit();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(container.read(reportIssueProvider(context)).fieldErrors['attachment_path'], 'Attach one evidence image before submitting this report');
    expect(backend.lastCreatedCategory, isNull);
  });

  test('support reply controller submits reply and clears the draft on success', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');
    final uploadService = _FakeSupportAttachmentUploadService(
      relocateResult: const Success<String>('user-1/support_reply/reply-created/evidence_2.jpg'),
    );
    final container = ProviderContainer(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repository),
        supportAttachmentUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(supportReplyProvider('ticket-1').notifier);
    controller.setAttachmentPath('user-1/support/evidence_2.jpg');
    controller.setMessageBody('I have now uploaded the clearer POD copy you requested.');

    final result = await controller.submit();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'reply-created');
    expect(backend.lastReplyTicketId, 'ticket-1');
    expect(backend.lastReplyMessageBody, 'I have now uploaded the clearer POD copy you requested.');
    expect(backend.lastReplyAttachmentPath, 'user-1/support/evidence_2.jpg');
    expect(uploadService.lastRelocateCurrentPath, 'user-1/support/evidence_2.jpg');
    expect(uploadService.lastRelocateTargetPathSegment, 'support_reply/reply-created');
    expect(container.read(supportReplyProvider('ticket-1')).attachmentPath, isEmpty);
    expect(container.read(supportReplyProvider('ticket-1')).messageBody, isEmpty);
  });
}
