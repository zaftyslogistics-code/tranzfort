import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

part 'chat_repository_conversation_models.dart';
part 'chat_repository_models.dart';
part 'chat_repository_backend.dart';

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

    await for (final rows in _backend.watchConversations(userId: userId, role: role)) {
      try {
        final previews = await _mapConversationRows(rows, currentUserId: userId);
        previews.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt;
          final bTime = b.lastMessageAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
        yield Success<List<ConversationPreview>>(previews);
      } catch (error, stackTrace) {
        yield Failure<List<ConversationPreview>>(_mapError(error, stackTrace));
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

  Future<List<ConversationPreview>> _mapConversationRows(
    List<Map<String, dynamic>> rows, {
    required String currentUserId,
  }) async {
    final previews = <ConversationPreview>[];
    for (final row in rows) {
      final loadId = (row['load_id'] ?? '').toString();
      final supplierId = (row['supplier_id'] ?? '').toString();
      final truckerId = (row['trucker_id'] ?? '').toString();
      final loadMap = loadId.isEmpty ? null : await _backend.fetchLoadContext(loadId);
      final supplierProfile = supplierId.isEmpty ? null : await _backend.fetchProfile(supplierId);
      final supplierExtension = supplierId.isEmpty ? null : await _backend.fetchSupplierExtension(supplierId);
      final truckerProfile = truckerId.isEmpty ? null : await _backend.fetchProfile(truckerId);
      final bookingContext = loadId.isEmpty || truckerId.isEmpty
          ? null
          : await _backend.fetchBookingContext(loadId: loadId, truckerId: truckerId);
      final latestMessageMap = await _backend.fetchLatestMessage(
        conversationId: (row['id'] ?? '').toString(),
      );
      final latestMessage = latestMessageMap == null ? null : MessageDto.fromMap(latestMessageMap);
      final hasUnread = await _backend.fetchHasUnread(
        conversationId: (row['id'] ?? '').toString(),
        currentUserId: currentUserId,
      );
      final dto = ConversationPreviewDto(
        id: (row['id'] ?? '').toString(),
        supplierId: supplierId,
        truckerId: truckerId,
        loadId: loadId,
        tripId: _nullableString(row['trip_id']),
        routeLabel: _buildRouteLabel(loadMap),
        loadMaterial: _nullableString(loadMap?['material']),
        loadPriceAmount: _readDouble(loadMap?['price_amount']),
        loadStatusLabel: _nullableString(loadMap?['status']),
        pickupDate: _readDate(loadMap?['pickup_date']),
        supplierName: (supplierProfile?['full_name'] ?? 'Supplier').toString(),
        supplierMobile: _nullableString(supplierProfile?['mobile']),
        supplierCompanyName: _nullableString(supplierExtension?['company_name']),
        truckerName: (truckerProfile?['full_name'] ?? 'Trucker').toString(),
        truckerMobile: _nullableString(truckerProfile?['mobile']),
        truckDisplayLabel: _buildTruckDisplayLabel(bookingContext),
        bookingRequestId: _nullableString(bookingContext?['id']),
        bookingStatusLabel: _nullableString(bookingContext?['status']),
        latestMessagePreview: _previewTextFromLatestMessage(latestMessage),
        lastMessageAt: _readDate(row['last_message_at']) ?? latestMessage?.createdAt,
        hasUnread: hasUnread,
        isArchived: row['is_archived'] == true,
        createdAt: DateTime.parse((row['created_at'] ?? '').toString()),
      );
      previews.add(dto.toDomain());
    }
    return previews;
  }

  String _buildRouteLabel(Map<String, dynamic>? loadMap) {
    final origin = (loadMap?['origin_label'] ?? 'Load').toString();
    final destination = (loadMap?['destination_label'] ?? '').toString();
    if (destination.trim().isEmpty) {
      return origin;
    }
    return '$origin → $destination';
  }

  String _previewTextFromLatestMessage(MessageDto? message) {
    if (message == null) {
      return 'No messages yet';
    }
    return switch (message.type) {
      ChatMessageType.text => (message.textBody ?? '').trim().isEmpty ? 'New message' : message.textBody!.trim(),
      ChatMessageType.voice => 'Voice message',
      ChatMessageType.location => 'Location shared',
      ChatMessageType.document => 'Document shared',
      ChatMessageType.mapCard => 'Route card shared',
      ChatMessageType.truckCard => 'Truck details shared',
      ChatMessageType.system => (message.textBody ?? '').trim().isEmpty ? 'System update' : message.textBody!.trim(),
    };
  }

  String? _buildTruckDisplayLabel(Map<String, dynamic>? bookingContext) {
    if (bookingContext == null) {
      return null;
    }
    final truckMap = bookingContext['trucks'];
    final truck = truckMap is Map<String, dynamic> ? truckMap : null;
    final modelMap = truck?['truck_models'];
    final model = modelMap is Map<String, dynamic> ? modelMap : null;
    final truckNumber = _nullableString(truck?['truck_number']);
    final make = _nullableString(model?['make']);
    final modelName = _nullableString(model?['model']);

    final modelLabel = [make, modelName].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
    if (truckNumber != null && modelLabel.isNotEmpty) {
      return '$truckNumber • $modelLabel';
    }
    if (truckNumber != null) {
      return truckNumber;
    }
    if (modelLabel.isNotEmpty) {
      return modelLabel;
    }
    return null;
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
