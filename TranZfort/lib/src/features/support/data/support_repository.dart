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

    var query = _client
        .from('support_tickets')
        .select(
          'id, category, status, priority, related_load_id, related_trip_id, resolution_summary, created_at, updated_at, resolved_at',
        )
        .eq('owner_profile_id', userId);

    if (before != null) {
      query = query.lt('updated_at', before.toUtc().toIso8601String());
    }

    final response = await query.order('updated_at', ascending: false).limit(limit);
    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchTicket({
    required String userId,
    required String ticketId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('support_tickets')
        .select(
          'id, category, status, priority, related_load_id, related_trip_id, resolution_summary, created_at, updated_at, resolved_at',
        )
        .eq('owner_profile_id', userId)
        .eq('id', ticketId)
        .maybeSingle();
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

    // Explicit ownership check: verify ticket exists and belongs to user
    final ticket = await _client
        .from('support_tickets')
        .select('id')
        .eq('id', ticketId)
        .eq('owner_profile_id', userId)
        .maybeSingle();
    if (ticket == null) {
      throw const AuthException('Ticket not found or access denied');
    }

    final response = await _client
        .from('support_ticket_messages')
        .select(
          'id, support_ticket_id, sender_profile_id, sender_admin_user_id, message_body, attachment_path, visibility_class, created_at',
        )
        .eq('support_ticket_id', ticketId)
        .order('created_at', ascending: true)
        .limit(limit);
    return response.whereType<Map<String, dynamic>>().toList(growable: false);
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

    // Explicit ownership check: verify ticket exists and belongs to user
    final ticket = await _client
        .from('support_tickets')
        .select('id')
        .eq('id', ticketId)
        .eq('owner_profile_id', userId)
        .maybeSingle();
    if (ticket == null) {
      throw const AuthException('Ticket not found or access denied');
    }

    var query = _client
        .from('support_ticket_messages')
        .select(
          'id, support_ticket_id, sender_profile_id, sender_admin_user_id, message_body, attachment_path, visibility_class, created_at',
        )
        .eq('support_ticket_id', ticketId);

    if (beforeCreatedAt != null) {
      query = query.lt('created_at', beforeCreatedAt.toUtc().toIso8601String());
    }
    if (beforeMessageId != null) {
      query = query.lt('id', beforeMessageId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return response.whereType<Map<String, dynamic>>().toList(growable: false).reversed.toList();
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
