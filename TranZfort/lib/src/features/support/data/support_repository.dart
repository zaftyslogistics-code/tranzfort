import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/map_readers.dart';
import 'support_models.dart';

export 'support_models.dart';

// Structured error codes shared with presentation layer for l10n mapping.
const String _supportCreateTicketDescriptionTooShortCode = 'support_create_ticket_description_too_short';
const String _supportReplyMessageTooShortCode = 'support_reply_message_too_short';
const String _supportTicketIdRequiredCode = 'support_ticket_id_required';
const String _supportCategoryRequiredCode = 'support_category_required';

abstract class SupportBackend {
  Future<List<Map<String, dynamic>>> fetchTickets({
    required String userId,
    int limit = 20,
    DateTime? before,
  });

  Future<Map<String, dynamic>?> fetchTicket({
    required String userId,
    required String ticketId,
  });

  Future<List<Map<String, dynamic>>> fetchTicketMessages({
    required String userId,
    required String ticketId,
    int limit = 50,
  });

  Future<List<Map<String, dynamic>>> fetchTicketMessagesPaginated({
    required String userId,
    required String ticketId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  });

  Future<String> createTicket({
    required String category,
    required String messageBody,
    String? relatedLoadId,
    String? relatedTripId,
    String? attachmentPath,
    SupportTicketPriority? priority,
  });

  Future<String> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  });

  Future<int> finalizeTicketAttachments({
    required String ticketId,
    required String sessionId,
  });
}

class SupabaseSupportBackend implements SupportBackend {
  final SupabaseClient? _client;

  const SupabaseSupportBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({
    required String userId,
    int limit = 20,
    DateTime? before,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_support_tickets',
      params: <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
        'p_before_updated_at': before?.toUtc().toIso8601String(),
      },
    );

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchTicket({
    required String userId,
    required String ticketId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_support_ticket_detail',
      params: <String, dynamic>{
        'p_ticket_id': ticketId,
        'p_user_id': userId,
      },
    );

    if (response is Map<String, dynamic>) {
      final ticket = response['ticket'];
      if (ticket is Map<String, dynamic> && ticket.isNotEmpty) {
        return ticket;
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({
    required String userId,
    required String ticketId,
    int limit = 50,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_support_ticket_detail',
      params: <String, dynamic>{
        'p_ticket_id': ticketId,
        'p_user_id': userId,
      },
    );

    if (response is Map<String, dynamic>) {
      final messages = response['messages'];
      if (messages is List) {
        return List<Map<String, dynamic>>.from(messages);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessagesPaginated({
    required String userId,
    required String ticketId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_support_ticket_messages',
      params: <String, dynamic>{
        'p_ticket_id': ticketId,
        'p_user_id': userId,
        'p_limit': limit,
        'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(),
        'p_before_message_id': beforeMessageId,
      },
    );

    if (response is List) {
      return List<Map<String, dynamic>>.from(response).reversed.toList();
    }
    return const <Map<String, dynamic>>[];
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
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'create_support_ticket',
      params: <String, dynamic>{
        'p_category': category,
        'p_message_body': messageBody,
        'p_related_load_id': _nullableUuid(relatedLoadId),
        'p_related_trip_id': _nullableUuid(relatedTripId),
        'p_attachment_path': nullableString(attachmentPath),
        'p_priority': priority == null || priority == SupportTicketPriority.unknown ? null : priority.name,
      },
    );

    return (response ?? '').toString();
  }

  @override
  Future<String> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'reply_to_support_ticket',
      params: <String, dynamic>{
        'p_support_ticket_id': ticketId,
        'p_message_body': messageBody,
        'p_visibility_class': 'visible',
        'p_attachment_path': nullableString(attachmentPath),
      },
    );

    return (response ?? '').toString();
  }

  @override
  Future<int> finalizeTicketAttachments({
    required String ticketId,
    required String sessionId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'finalize_ticket_attachments',
      params: <String, dynamic>{
        'p_ticket_id': ticketId,
        'p_session_id': sessionId,
      },
    );

    return (response as int?) ?? 0;
  }
}

class SupportRepository {
  final SupportBackend _backend;
  final String? Function() _currentUserId;

  const SupportRepository(this._backend, this._currentUserId);

  Future<Result<List<SupportTicket>>> getTickets({
    int limit = 20,
    DateTime? before,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<SupportTicket>>(UnauthorizedFailure());
    }

    try {
      final rows = await _backend.fetchTickets(
        userId: userId,
        limit: limit,
        before: before,
      );
      final tickets = rows
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Success<List<SupportTicket>>(tickets);
    } catch (error, stackTrace) {
      return Failure<List<SupportTicket>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<SupportTicketDetail>> getTicketDetail(String ticketId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<SupportTicketDetail>(UnauthorizedFailure());
    }

    final normalizedTicketId = ticketId.trim();
    if (normalizedTicketId.isEmpty) {
      return const Failure<SupportTicketDetail>(
        ValidationFailure(
          message: _supportTicketIdRequiredCode,
          fieldErrors: {'ticket_id': _supportTicketIdRequiredCode},
        ),
      );
    }

    try {
      final ticketRow = await _backend.fetchTicket(
        userId: userId,
        ticketId: normalizedTicketId,
      );
      if (ticketRow == null) {
        return const Failure<SupportTicketDetail>(NotFoundFailure());
      }
      final messageRows = await _backend.fetchTicketMessages(userId: userId, ticketId: normalizedTicketId);
      final ticket = SupportTicketDto.fromMap(ticketRow).toDomain();
      final messages = messageRows
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketMessageDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return Success<SupportTicketDetail>(
        SupportTicketDetail(ticket: ticket, messages: messages),
      );
    } catch (error, stackTrace) {
      return Failure<SupportTicketDetail>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<SupportTicketMessage>>> getTicketMessagesPaginated(
    String ticketId, {
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<SupportTicketMessage>>(UnauthorizedFailure());
    }

    final normalizedTicketId = ticketId.trim();
    if (normalizedTicketId.isEmpty) {
      return const Failure<List<SupportTicketMessage>>(
        ValidationFailure(
          message: _supportTicketIdRequiredCode,
          fieldErrors: {'ticket_id': _supportTicketIdRequiredCode},
        ),
      );
    }

    try {
      final rows = await _backend.fetchTicketMessagesPaginated(
        userId: userId,
        ticketId: normalizedTicketId,
        limit: limit,
        beforeCreatedAt: beforeCreatedAt,
        beforeMessageId: beforeMessageId,
      );
      final messages = rows
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketMessageDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Success<List<SupportTicketMessage>>(messages);
    } catch (error, stackTrace) {
      return Failure<List<SupportTicketMessage>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> createTicket({
    required String category,
    required String messageBody,
    String? relatedLoadId,
    String? relatedTripId,
    String? attachmentPath,
    SupportTicketPriority? priority,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: _supportCategoryRequiredCode,
          fieldErrors: {'category': _supportCategoryRequiredCode},
        ),
      );
    }

    final normalizedMessage = messageBody.trim();
    if (normalizedMessage.length < 10) {
      return const Failure<String>(
        ValidationFailure(
          message: _supportCreateTicketDescriptionTooShortCode,
          fieldErrors: {'message_body': _supportCreateTicketDescriptionTooShortCode},
        ),
      );
    }

    try {
      final ticketId = await _backend.createTicket(
        category: normalizedCategory,
        messageBody: normalizedMessage,
        relatedLoadId: _nullableUuid(relatedLoadId),
        relatedTripId: _nullableUuid(relatedTripId),
        attachmentPath: attachmentPath,
        priority: priority,
      );
      return Success<String>(ticketId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedTicketId = ticketId.trim();
    if (normalizedTicketId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: _supportTicketIdRequiredCode,
          fieldErrors: {'ticket_id': _supportTicketIdRequiredCode},
        ),
      );
    }

    final normalizedMessage = messageBody.trim();
    if (normalizedMessage.length < 2) {
      return const Failure<String>(
        ValidationFailure(
          message: _supportReplyMessageTooShortCode,
          fieldErrors: {'message_body': _supportReplyMessageTooShortCode},
        ),
      );
    }

    try {
      final messageId = await _backend.replyToTicket(
        ticketId: normalizedTicketId,
        messageBody: normalizedMessage,
        attachmentPath: attachmentPath,
      );
      return Success<String>(messageId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<int>> finalizeTicketAttachments({
    required String ticketId,
    required String sessionId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<int>(UnauthorizedFailure());
    }

    final normalizedTicketId = ticketId.trim();
    if (normalizedTicketId.isEmpty) {
      return const Failure<int>(
        ValidationFailure(
          message: _supportTicketIdRequiredCode,
          fieldErrors: {'ticket_id': _supportTicketIdRequiredCode},
        ),
      );
    }

    try {
      final count = await _backend.finalizeTicketAttachments(
        ticketId: normalizedTicketId,
        sessionId: sessionId,
      );
      return Success<int>(count);
    } catch (error, stackTrace) {
      return Failure<int>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final rawMessage = error.message.trim().toLowerCase();
      if (rawMessage.contains('support ticket not found')) {
        return NotFoundFailure(debugInfo: error.details?.toString());
      }
    }
    return mapSupabaseError(error, stackTrace);
  }
}

// Using shared map_readers.dart helpers: nullableString, readDate

String? _nullableUuid(String? value) {
  final raw = (value ?? '').trim();
  return raw.isEmpty ? null : raw;
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupportRepository(
    SupabaseSupportBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
