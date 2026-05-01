import 'dart:async';

import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository_backend.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository_models.dart';

/// Centralized mock implementation of [ChatBackend] for testing.
/// 
/// This mock provides:
/// - Configurable behavior via public fields
/// - Method call tracking for verification
/// - Default sensible implementations
/// 
/// Usage:
/// ```dart
/// final mock = MockChatBackend()
///   ..conversationRows = [testConversation]
///   ..error = null;
/// ```
class MockChatBackend implements ChatBackend {
  // ==================== CONFIGURABLE BEHAVIOR ====================
  
  /// Return value for fetchConversations
  List<Map<String, dynamic>> conversationRows = const <Map<String, dynamic>>[];
  
  /// Exception to throw from any method (if non-null)
  Object? error;
  
  /// Stream controller for watchConversations
  final StreamController<List<Map<String, dynamic>>> conversationWatchController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  
  /// Messages per conversation ID
  final Map<String, List<Map<String, dynamic>>> messagesByConversation = <String, List<Map<String, dynamic>>>{};
  
  /// Latest message per conversation ID
  final Map<String, Map<String, dynamic>?> latestMessageByConversation = <String, Map<String, dynamic>?>{};
  
  /// Unread status per conversation ID
  final Map<String, bool> unreadByConversation = <String, bool>{};
  
  /// Load context per load ID
  final Map<String, Map<String, dynamic>?> loadContextById = <String, Map<String, dynamic>?>{};
  
  /// Profile per profile ID
  final Map<String, Map<String, dynamic>?> profileById = <String, Map<String, dynamic>?>{};
  
  /// Supplier extension per supplier ID
  final Map<String, Map<String, dynamic>?> supplierExtensionById = <String, Map<String, dynamic>?>{};
  
  /// Booking context per "loadId:truckerId" key
  final Map<String, Map<String, dynamic>?> bookingContextByLoadAndTrucker = <String, Map<String, dynamic>?>{};
  
  /// Result for createOrGetConversation
  String createConversationResult = 'conversation-1';
  
  /// Result for sendMessage
  String sendMessageResult = 'message-1';
  
  /// Result for fetchUnreadConversationCount
  int unreadConversationCount = 0;
  
  /// Conversation data per conversation ID
  final Map<String, Object?> conversationData = <String, Object?>{};

  // ==================== TRACKING FIELDS ====================
  
  String? fetchedConversationsUserId;
  AppUserRole? fetchedConversationsRole;
  
  String? watchedConversationsUserId;
  AppUserRole? watchedConversationsRole;
  
  String? fetchedMessagesConversationId;
  String? watchedMessagesConversationId;
  
  String? fetchedLatestMessageConversationId;
  
  String? fetchedHasUnreadConversationId;
  String? fetchedHasUnreadCurrentUserId;
  
  String? fetchedLoadContextId;
  String? fetchedProfileId;
  String? fetchedSupplierExtensionId;
  
  String? fetchedBookingContextLoadId;
  String? fetchedBookingContextTruckerId;
  
  String? createdConversationSupplierId;
  String? createdConversationTruckerId;
  String? createdConversationLoadId;
  
  String? fetchedConversationId;
  
  String? sentMessageConversationId;
  ChatMessageType? sentMessageType;
  String? sentMessageId;
  String? sentTextBody;
  String? sentAttachmentPath;
  Map<String, dynamic>? sentStructuredPayload;
  
  String? markedReadConversationId;
  String? markedReadReaderId;

  // ==================== METHOD IMPLEMENTATIONS ====================

  void _throwIfError() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({
    required String userId,
    required AppUserRole role,
  }) async {
    _throwIfError();
    fetchedConversationsUserId = userId;
    fetchedConversationsRole = role;
    return conversationRows;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({
    required String userId,
    required AppUserRole role,
  }) {
    watchedConversationsUserId = userId;
    watchedConversationsRole = role;
    return conversationWatchController.stream;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({
    required String conversationId,
  }) async {
    _throwIfError();
    fetchedMessagesConversationId = conversationId;
    return messagesByConversation[conversationId] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessagesPaginated({
    required String conversationId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    _throwIfError();
    fetchedMessagesConversationId = conversationId;
    final messages = messagesByConversation[conversationId] ?? const <Map<String, dynamic>>[];
    // Simple pagination: return first 'limit' messages
    return messages.take(limit).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({
    required String conversationId,
  }) {
    watchedMessagesConversationId = conversationId;
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    controller.add(messagesByConversation[conversationId] ?? const <Map<String, dynamic>>[]);
    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({
    required String conversationId,
  }) async {
    _throwIfError();
    fetchedLatestMessageConversationId = conversationId;
    return latestMessageByConversation[conversationId];
  }

  @override
  Future<bool> fetchHasUnread({
    required String conversationId,
    required String currentUserId,
  }) async {
    _throwIfError();
    fetchedHasUnreadConversationId = conversationId;
    fetchedHasUnreadCurrentUserId = currentUserId;
    return unreadByConversation[conversationId] ?? false;
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async {
    _throwIfError();
    fetchedLoadContextId = loadId;
    return loadContextById[loadId];
  }

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async {
    _throwIfError();
    fetchedProfileId = profileId;
    return profileById[profileId];
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async {
    _throwIfError();
    fetchedSupplierExtensionId = supplierId;
    return supplierExtensionById[supplierId];
  }

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({
    required String loadId,
    required String truckerId,
  }) async {
    _throwIfError();
    fetchedBookingContextLoadId = loadId;
    fetchedBookingContextTruckerId = truckerId;
    final key = '$loadId:$truckerId';
    return bookingContextByLoadAndTrucker[key];
  }

  @override
  Future<String> createOrGetConversation({
    required String supplierId,
    required String truckerId,
    required String loadId,
  }) async {
    _throwIfError();
    createdConversationSupplierId = supplierId;
    createdConversationTruckerId = truckerId;
    createdConversationLoadId = loadId;
    return createConversationResult;
  }

  @override
  Future<Object?> fetchConversation(String conversationId) async {
    _throwIfError();
    fetchedConversationId = conversationId;
    return conversationData[conversationId];
  }

  @override
  Future<String> sendMessage({
    required String conversationId,
    required ChatMessageType type,
    String? messageId,
    String? textBody,
    String? attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async {
    _throwIfError();
    sentMessageConversationId = conversationId;
    sentMessageType = type;
    sentMessageId = messageId;
    sentTextBody = textBody;
    sentAttachmentPath = attachmentPath;
    sentStructuredPayload = structuredPayload;
    return sendMessageResult;
  }

  @override
  Future<void> markMessagesRead({
    required String conversationId,
    required String readerId,
  }) async {
    _throwIfError();
    markedReadConversationId = conversationId;
    markedReadReaderId = readerId;
    unreadByConversation[conversationId] = false;
  }

  @override
  Future<int> fetchUnreadConversationCount() async {
    _throwIfError();
    return unreadConversationCount;
  }

  // ==================== HELPER METHODS ====================
  
  /// Emits a conversation update to all watchers
  void emitConversationUpdate(List<Map<String, dynamic>> conversations) {
    conversationWatchController.add(conversations);
  }

  /// Sets up a simple conversation with messages
  void setupConversation({
    required String conversationId,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? latestMessage,
    bool hasUnread = false,
  }) {
    messagesByConversation[conversationId] = messages;
    latestMessageByConversation[conversationId] = latestMessage;
    unreadByConversation[conversationId] = hasUnread;
  }

  /// Clears all tracking fields
  void clearTracking() {
    fetchedConversationsUserId = null;
    fetchedConversationsRole = null;
    watchedConversationsUserId = null;
    watchedConversationsRole = null;
    fetchedMessagesConversationId = null;
    watchedMessagesConversationId = null;
    fetchedLatestMessageConversationId = null;
    fetchedHasUnreadConversationId = null;
    fetchedHasUnreadCurrentUserId = null;
    fetchedLoadContextId = null;
    fetchedProfileId = null;
    fetchedSupplierExtensionId = null;
    fetchedBookingContextLoadId = null;
    fetchedBookingContextTruckerId = null;
    createdConversationSupplierId = null;
    createdConversationTruckerId = null;
    createdConversationLoadId = null;
    fetchedConversationId = null;
    sentMessageConversationId = null;
    sentMessageType = null;
    sentMessageId = null;
    sentTextBody = null;
    sentAttachmentPath = null;
    sentStructuredPayload = null;
    markedReadConversationId = null;
    markedReadReaderId = null;
  }
}
