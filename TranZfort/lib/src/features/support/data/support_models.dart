import '../../../core/utils/map_readers.dart';

enum SupportTicketStatus {
  open,
  inProgress,
  waitingForUser,
  resolved,
  closed,
  unknown,
}

extension SupportTicketStatusX on SupportTicketStatus {
  static SupportTicketStatus fromDatabase(String value) {
    return switch (value.trim().toLowerCase()) {
      'open' => SupportTicketStatus.open,
      'in_progress' => SupportTicketStatus.inProgress,
      'waiting_for_user' => SupportTicketStatus.waitingForUser,
      'resolved' => SupportTicketStatus.resolved,
      'closed' => SupportTicketStatus.closed,
      _ => SupportTicketStatus.unknown,
    };
  }
}

enum SupportTicketPriority {
  low,
  medium,
  high,
  urgent,
  unknown,
}

extension SupportTicketPriorityX on SupportTicketPriority {
  static SupportTicketPriority fromDatabase(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'low' => SupportTicketPriority.low,
      'medium' => SupportTicketPriority.medium,
      'high' => SupportTicketPriority.high,
      'urgent' => SupportTicketPriority.urgent,
      _ => SupportTicketPriority.unknown,
    };
  }
}

enum SupportMessageSenderType {
  user,
  support,
}

class SupportTicketDto {
  final String id;
  final String category;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final String? relatedLoadId;
  final String? relatedTripId;
  final String? resolutionSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const SupportTicketDto({
    required this.id,
    required this.category,
    required this.status,
    required this.priority,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.resolutionSummary,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  factory SupportTicketDto.fromMap(Map<String, dynamic> map) {
    return SupportTicketDto(
      id: (map['id'] ?? '').toString(),
      category: (map['category'] ?? 'general').toString(),
      status: SupportTicketStatusX.fromDatabase((map['status'] ?? 'open').toString()),
      priority: SupportTicketPriorityX.fromDatabase(map['priority']?.toString()),
      relatedLoadId: nullableString(map['related_load_id']),
      relatedTripId: nullableString(map['related_trip_id']),
      resolutionSummary: nullableString(map['resolution_summary']),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
      updatedAt: DateTime.parse((map['updated_at'] ?? '').toString()),
      resolvedAt: readDate(map['resolved_at']),
    );
  }

  SupportTicket toDomain() {
    return SupportTicket(
      id: id,
      category: category,
      status: status,
      priority: priority,
      relatedLoadId: relatedLoadId,
      relatedTripId: relatedTripId,
      resolutionSummary: resolutionSummary,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
    );
  }
}

class SupportTicketMessageDto {
  final String id;
  final String supportTicketId;
  final SupportMessageSenderType senderType;
  final String? messageBody;
  final String? attachmentPath;
  final String visibilityClass;
  final DateTime createdAt;

  const SupportTicketMessageDto({
    required this.id,
    required this.supportTicketId,
    required this.senderType,
    required this.messageBody,
    required this.attachmentPath,
    required this.visibilityClass,
    required this.createdAt,
  });

  factory SupportTicketMessageDto.fromMap(Map<String, dynamic> map) {
    // Use sender_admin_user_id to determine sender type (more reliable than sender_profile_id null check)
    final senderAdminUserId = nullableString(map['sender_admin_user_id']);
    return SupportTicketMessageDto(
      id: (map['id'] ?? '').toString(),
      supportTicketId: (map['support_ticket_id'] ?? '').toString(),
      senderType: senderAdminUserId != null ? SupportMessageSenderType.support : SupportMessageSenderType.user,
      messageBody: nullableString(map['message_body']),
      attachmentPath: nullableString(map['attachment_path']),
      visibilityClass: (map['visibility_class'] ?? 'visible').toString(),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
    );
  }

  SupportTicketMessage toDomain() {
    return SupportTicketMessage(
      id: id,
      supportTicketId: supportTicketId,
      senderType: senderType,
      messageBody: messageBody,
      attachmentPath: attachmentPath,
      visibilityClass: visibilityClass,
      createdAt: createdAt,
    );
  }
}

class SupportTicket {
  final String id;
  final String category;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final String? relatedLoadId;
  final String? relatedTripId;
  final String? resolutionSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const SupportTicket({
    required this.id,
    required this.category,
    required this.status,
    required this.priority,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.resolutionSummary,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  bool get isResolved => status == SupportTicketStatus.resolved || status == SupportTicketStatus.closed;
}

class SupportTicketMessage {
  final String id;
  final String supportTicketId;
  final SupportMessageSenderType senderType;
  final String? messageBody;
  final String? attachmentPath;
  final String visibilityClass;
  final DateTime createdAt;

  const SupportTicketMessage({
    required this.id,
    required this.supportTicketId,
    required this.senderType,
    required this.messageBody,
    required this.attachmentPath,
    required this.visibilityClass,
    required this.createdAt,
  });

  bool get hasAttachment => (attachmentPath ?? '').trim().isNotEmpty;
}

class SupportTicketDetail {
  final SupportTicket ticket;
  final List<SupportTicketMessage> messages;

  const SupportTicketDetail({
    required this.ticket,
    required this.messages,
  });
}
