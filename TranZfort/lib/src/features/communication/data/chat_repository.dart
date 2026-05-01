import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/map_readers.dart';
import 'chat_repository_conversation_models.dart';
import 'chat_repository_models.dart';
import 'chat_repository_backend.dart';

export 'chat_repository_conversation_models.dart';
export 'chat_repository_models.dart';
export 'chat_repository_backend.dart';

/// Extension to debounce stream events - batches rapid updates
extension StreamDebounce<T> on Stream<T> {
  Stream<T> debounce(Duration duration) {
    Timer? timer;
    final controller = StreamController<T>();

    listen((event) {
      timer?.cancel();
      timer = Timer(duration, () => controller.add(event));
    }, onDone: () {
      timer?.cancel();
      controller.close();
    }, onError: controller.addError, cancelOnError: false);

    return controller.stream;
  }
}

class ChatRepository {
  final ChatBackend _backend;
  final String? Function() _currentUserId;
  final AppUserRole Function() _currentUserRole;

  const ChatRepository(this._backend, this._currentUserId, this._currentUserRole);

  Future<Result<List<ConversationPreview>>> getConversations() async {
    final userId = _currentUserId();
    final role = _currentUserRole();
    if (userId == null) {
      return const Failure<List<ConversationPreview>>(UnauthorizedFailure());
    }
    if (role == AppUserRole.unknown) {
      return const Failure<List<ConversationPreview>>(
        BusinessRuleFailure(message: 'Your account role is required before messages can load.'),
      );
    }

    try {
      final rows = await _backend.fetchConversations(userId: userId, role: role);
      final previews = await _mapConversationRows(rows, currentUserId: userId);
      previews.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      return Success<List<ConversationPreview>>(previews);
    } catch (error, stackTrace) {
      return Failure<List<ConversationPreview>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<int>> getUnreadConversationCount() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<int>(UnauthorizedFailure());
    }

    try {
      final count = await _backend.fetchUnreadConversationCount();
      return Success<int>(count);
    } catch (error, stackTrace) {
      return Failure<int>(_mapError(error, stackTrace));
    }
  }

  Stream<Result<List<ConversationPreview>>> watchConversations() async* {
    final userId = _currentUserId();
    final role = _currentUserRole();
    if (userId == null) {
      yield const Failure<List<ConversationPreview>>(UnauthorizedFailure());
      return;
    }
    if (role == AppUserRole.unknown) {
      yield const Failure<List<ConversationPreview>>(
        BusinessRuleFailure(message: 'Your account role is required before messages can load.'),
      );
      return;
    }

    // Enriched realtime strategy: listen to raw table changes as triggers,
    // then refresh via RPC to get complete enriched data (route_label, has_unread, etc.).
    // This avoids mapping failures from incomplete realtime row shapes.
    await for (final _ in _backend
        .watchConversations(userId: userId, role: role)
        .debounce(const Duration(milliseconds: 300))) {
      try {
        final rows = await _backend.fetchConversations(userId: userId, role: role);
        final previews = await _mapConversationRows(rows, currentUserId: userId);
        yield Success<List<ConversationPreview>>(_sortConversationPreviews(previews));
      } catch (error, stackTrace) {
        yield Failure<List<ConversationPreview>>(_mapError(error, stackTrace));
      }
    }
  }

  Stream<Result<int>> watchUnreadConversationCount() async* {
    final userId = _currentUserId();
    if (userId == null) {
      yield const Failure<int>(UnauthorizedFailure());
      return;
    }

    await for (final _ in _backend
        .watchConversations(userId: userId, role: _currentUserRole())
        .debounce(const Duration(milliseconds: 300))) {
      try {
        final count = await _backend.fetchUnreadConversationCount();
        yield Success<int>(count);
      } catch (error, stackTrace) {
        yield Failure<int>(_mapError(error, stackTrace));
      }
    }
  }

  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<ChatMessage>>(UnauthorizedFailure());
    }

    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Failure<List<ChatMessage>>(
        ValidationFailure(
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchMessages(conversationId: normalizedConversationId);
      return Success<List<ChatMessage>>(
        rows
            .whereType<Map<String, dynamic>>()
            .map(MessageDto.fromMap)
            .map((dto) => dto.toDomain(userId))
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<ChatMessage>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<ChatMessage>>> getMessagesPaginated(
    String conversationId, {
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<ChatMessage>>(UnauthorizedFailure());
    }

    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Failure<List<ChatMessage>>(
        ValidationFailure(
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchMessagesPaginated(
        conversationId: normalizedConversationId,
        limit: limit,
        beforeCreatedAt: beforeCreatedAt,
        beforeMessageId: beforeMessageId,
      );
      return Success<List<ChatMessage>>(
        rows
            .whereType<Map<String, dynamic>>()
            .map(MessageDto.fromMap)
            .map((dto) => dto.toDomain(userId))
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<ChatMessage>>(_mapError(error, stackTrace));
    }
  }

  Stream<Result<List<ChatMessage>>> watchMessages(String conversationId) async* {
    final userId = _currentUserId();
    if (userId == null) {
      yield const Failure<List<ChatMessage>>(UnauthorizedFailure());
      return;
    }

    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      yield const Failure<List<ChatMessage>>(
        ValidationFailure(
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
      return;
    }

    await for (final rows in _backend.watchMessages(conversationId: normalizedConversationId)) {
      try {
        yield Success<List<ChatMessage>>(
          rows
              .whereType<Map<String, dynamic>>()
              .map(MessageDto.fromMap)
              .map((dto) => dto.toDomain(userId))
              .toList(growable: false),
        );
      } catch (error, stackTrace) {
        yield Failure<List<ChatMessage>>(_mapError(error, stackTrace));
      }
    }
  }

  Future<Result<String>> createOrGetConversation({
    required String supplierId,
    required String truckerId,
    required String loadId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedSupplierId = supplierId.trim();
    final normalizedTruckerId = truckerId.trim();
    final normalizedLoadId = loadId.trim();
    if (normalizedSupplierId.isEmpty || normalizedTruckerId.isEmpty || normalizedLoadId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Supplier, trucker, and load context are required',
          fieldErrors: {
            'supplier_id': 'Supplier id is required',
            'trucker_id': 'Trucker id is required',
            'load_id': 'Load id is required',
          },
        ),
      );
    }

    try {
      final conversationId = await _backend.createOrGetConversation(
        supplierId: normalizedSupplierId,
        truckerId: normalizedTruckerId,
        loadId: normalizedLoadId,
      );
      if (conversationId.trim().isEmpty) {
        return const Failure<String>(UnknownFailure());
      }
      return Success<String>(conversationId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String?>> getSupplierMobile(String conversationId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String?>(UnauthorizedFailure());
    }

    try {
      final result = await _backend.fetchConversation(conversationId);
      if (result == null) {
        return const Failure<String?>(NotFoundFailure());
      }
      final Map<String, dynamic>? row = switch (result) {
        final Map<String, dynamic> map => map,
        final List<dynamic> rows when rows.isNotEmpty => rows.first is Map<String, dynamic>
            ? rows.first as Map<String, dynamic>
            : Map<String, dynamic>.from(rows.first as Map),
        _ => null,
      };
      if (row == null) {
        return const Failure<String?>(NotFoundFailure());
      }

      final mobile = nullableString(row['supplier_mobile']);
      return Success<String?>(mobile);
    } catch (error, stackTrace) {
      return Failure<String?>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final normalizedConversationId = conversationId.trim();
    final normalizedText = text.trim();
    if (normalizedConversationId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
    }
    if (normalizedText.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Message text is required',
          fieldErrors: {'text': 'Message text is required'},
        ),
      );
    }

    try {
      final messageId = await _backend.sendMessage(
        conversationId: normalizedConversationId,
        type: ChatMessageType.text,
        textBody: normalizedText,
      );
      if (messageId.trim().isEmpty) {
        return const Failure<String>(UnknownFailure());
      }
      return Success<String>(messageId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> sendVoiceMessage({
    required String conversationId,
    String? messageId,
    required String attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async {
    final normalizedConversationId = conversationId.trim();
    final normalizedMessageId = (messageId ?? '').trim();
    final normalizedAttachmentPath = attachmentPath.trim();
    if (normalizedConversationId.isEmpty || normalizedAttachmentPath.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Conversation and voice attachment are required',
          fieldErrors: {
            'conversation_id': 'Conversation id is required',
            'attachment_path': 'Voice attachment is required',
          },
        ),
      );
    }

    try {
      final messageId = await _backend.sendMessage(
        conversationId: normalizedConversationId,
        type: ChatMessageType.voice,
        messageId: normalizedMessageId.isEmpty ? null : normalizedMessageId,
        attachmentPath: normalizedAttachmentPath,
        structuredPayload: structuredPayload,
      );
      if (messageId.trim().isEmpty) {
        return const Failure<String>(UnknownFailure());
      }
      return Success<String>(messageId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> markConversationRead(String conversationId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
    }

    try {
      await _backend.markMessagesRead(
        conversationId: normalizedConversationId,
        readerId: userId,
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  // TODO: Remove if not needed - currently unused
  // Future<Result<ConversationPreview?>> _fetchConversationPreview({
  //   required String conversationId,
  // }) async {
  //   try {
  //     final result = await _backend.fetchConversation(conversationId);
  //     if (result == null) {
  //       return const Success<ConversationPreview?>(null);
  //     }

  //     final Map<String, dynamic>? row = switch (result) {
  //       final Map<String, dynamic> map => map,
  //       final List<dynamic> rows when rows.isNotEmpty => rows.first is Map<String, dynamic>
  //           ? rows.first as Map<String, dynamic>
  //           : Map<String, dynamic>.from(rows.first as Map),
  //       _ => null,
  //     };
  //     if (row == null) {
  //       return const Success<ConversationPreview?>(null);
  //     }

  //     return Success<ConversationPreview?>(_mapConversationSummaryRow(row));
  //   } catch (error, stackTrace) {
  //     return Failure<ConversationPreview?>(_mapError(error, stackTrace));
  //   }
  // }

  List<ConversationPreview> _sortConversationPreviews(Iterable<ConversationPreview> previews) {
    final sorted = previews.toList(growable: false);
    sorted.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  // TODO: Remove if not needed - currently unused
  // bool _mapEquals(Map<String, dynamic>? left, Map<String, dynamic>? right) {
  //   if (identical(left, right)) {
  //     return true;
  //   }
  //   if (left == null || right == null || left.length != right.length) {
  //     return false;
  //   }
  //   for (final entry in left.entries) {
  //     if (right[entry.key] != entry.value) {
  //       return false;
  //     }
  //   }
  //   return true;
  // }

  Future<List<ConversationPreview>> _mapConversationRows(
    List<Map<String, dynamic>> rows, {
    required String currentUserId,
  }) async {
    final previews = <ConversationPreview>[];
    for (final row in rows) {
      // Phase 3-G: RPC path always returns complete data. N+1 fallback removed.
      if (!row.containsKey('route_label') || !row.containsKey('has_unread')) {
        throw const ServerFailure(message: 'Conversation summary row missing required fields. Ensure RPC returns complete data.');
      }
      previews.add(_mapConversationSummaryRow(row));
    }
    return previews;
  }

  ConversationPreview _mapConversationSummaryRow(Map<String, dynamic> row) {
    final latestMessageType = row['latest_message_type']?.toString();
    final latestMessageText = nullableString(row['latest_message_text']);
    final parsedType = latestMessageType == null
        ? null
        : ChatMessageTypeX.fromDatabase(latestMessageType);
    final latestPreview = latestMessageText?.trim().isNotEmpty == true
        ? latestMessageText!.trim()
        : switch (parsedType) {
            ChatMessageType.voice => 'Voice message',
            ChatMessageType.location => 'Location shared',
            ChatMessageType.document => 'Document shared',
            ChatMessageType.mapCard => 'Route card shared',
            ChatMessageType.truckCard => 'Truck details shared',
            ChatMessageType.system => 'System update',
            _ => 'No messages yet',
          };

    return ConversationPreview(
      id: (row['id'] ?? '').toString(),
      supplierId: (row['supplier_id'] ?? '').toString(),
      truckerId: (row['trucker_id'] ?? '').toString(),
      loadId: (row['load_id'] ?? '').toString(),
      tripId: nullableString(row['trip_id']),
      routeLabel: (row['route_label'] ?? 'Load').toString(),
      loadMaterial: nullableString(row['load_material']),
      loadPriceAmount: readDouble(row['load_price_amount']),
      loadStatusLabel: nullableString(row['load_status_label']),
      pickupDate: readDate(row['pickup_date']),
      supplierName: (row['supplier_name'] ?? 'Supplier').toString(),
      supplierMobile: nullableString(row['supplier_mobile']),
      supplierCompanyName: nullableString(row['supplier_company_name']),
      supplierAvatarUrl: nullableString(row['supplier_avatar_url']),
      truckerName: (row['trucker_name'] ?? 'Trucker').toString(),
      truckerMobile: nullableString(row['trucker_mobile']),
      truckDisplayLabel: nullableString(row['truck_display_label']),
      truckerAvatarUrl: nullableString(row['trucker_avatar_url']),
      bookingRequestId: nullableString(row['booking_request_id']),
      bookingStatusLabel: nullableString(row['booking_status_label']),
      latestMessagePreview: latestPreview,
      latestMessageTypeHint: parsedType,
      lastMessageAt: readDate(row['last_message_at']),
      hasUnread: row['has_unread'] == true,
      isArchived: row['is_archived'] == true,
      createdAt: DateTime.parse((row['created_at'] ?? '').toString()),
    );
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final rawMessage = error.message.trim().toLowerCase();
      if (rawMessage.contains('not a participant')) {
        return PermissionFailure(debugInfo: error.details?.toString());
      }
      if (rawMessage.contains('conversation not found')) {
        return NotFoundFailure(debugInfo: error.details?.toString());
      }
      if (rawMessage.contains('duplicate') || rawMessage.contains('already exists')) {
        return ConflictFailure(debugInfo: error.details?.toString());
      }
    }
    return mapSupabaseError(error, stackTrace);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(currentAuthStateProvider);
  return ChatRepository(
    SupabaseChatBackend(client),
    () => client?.auth.currentUser?.id,
    () => authState.role,
  );
});
