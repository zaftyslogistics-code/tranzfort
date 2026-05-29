import '../../../core/utils/date_parser.dart';
import '../../../core/utils/map_readers.dart';

class MessageDto {
  final String id;
  final String conversationId;
  final String? senderProfileId;
  final ChatMessageType type;
  final String? textBody;
  final String? attachmentPath;
  final Map<String, dynamic>? structuredPayload;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    required this.type,
    required this.textBody,
    required this.attachmentPath,
    required this.structuredPayload,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  factory MessageDto.fromMap(Map<String, dynamic> map) {
    final payload = map['structured_payload'];
    return MessageDto(
      id: (map['id'] ?? '').toString(),
      conversationId: (map['conversation_id'] ?? '').toString(),
      senderProfileId: nullableString(map['sender_profile_id']),
      type: ChatMessageTypeX.fromDatabase((map['message_type'] ?? 'text').toString()),
      textBody: nullableString(map['text_body']),
      attachmentPath: nullableString(map['attachment_path']),
      structuredPayload: payload is Map<String, dynamic> ? payload : null,
      isRead: map['is_read'] == true,
      readAt: readDate(map['read_at']),
      createdAt: safeParseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  ChatMessage toDomain(String currentUserId) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderProfileId: senderProfileId,
      type: type,
      textBody: textBody,
      attachmentPath: attachmentPath,
      structuredPayload: structuredPayload,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
      isFromCurrentUser: senderProfileId == currentUserId,
    );
  }
}

enum ChatMessageType {
  text,
  voice,
  location,
  document,
  mapCard,
  truckCard,
  system,
}

extension ChatMessageTypeX on ChatMessageType {
  String get databaseValue {
    return switch (this) {
      ChatMessageType.text => 'text',
      ChatMessageType.voice => 'voice',
      ChatMessageType.location => 'location',
      ChatMessageType.document => 'document',
      ChatMessageType.mapCard => 'map_card',
      ChatMessageType.truckCard => 'truck_card',
      ChatMessageType.system => 'system',
    };
  }

  static ChatMessageType fromDatabase(String value) {
    return switch (value.trim().toLowerCase()) {
      'voice' => ChatMessageType.voice,
      'location' => ChatMessageType.location,
      'document' => ChatMessageType.document,
      'map_card' => ChatMessageType.mapCard,
      'truck_card' => ChatMessageType.truckCard,
      'system' => ChatMessageType.system,
      _ => ChatMessageType.text,
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String? senderProfileId;
  final ChatMessageType type;
  final String? textBody;
  final String? attachmentPath;
  final Map<String, dynamic>? structuredPayload;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isFromCurrentUser;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    required this.type,
    required this.textBody,
    required this.attachmentPath,
    required this.structuredPayload,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
    required this.isFromCurrentUser,
  });
}
