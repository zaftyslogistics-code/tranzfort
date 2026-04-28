import 'chat_repository_models.dart';

class ConversationPreviewDto {
  final String id;
  final String supplierId;
  final String truckerId;
  final String loadId;
  final String? tripId;
  final String routeLabel;
  final String? loadMaterial;
  final double? loadPriceAmount;
  final String? loadStatusLabel;
  final DateTime? pickupDate;
  final String supplierName;
  final String? supplierMobile;
  final String? supplierCompanyName;
  final String? supplierAvatarUrl;
  final String truckerName;
  final String? truckerMobile;
  final String? truckDisplayLabel;
  final String? truckerAvatarUrl;
  final String? bookingRequestId;
  final String? bookingStatusLabel;
  final String latestMessagePreview;
  final ChatMessageType? latestMessageTypeHint;
  final DateTime? lastMessageAt;
  final bool hasUnread;
  final bool isArchived;
  final DateTime createdAt;
  final bool isAttachmentAllowed;

  const ConversationPreviewDto({
    required this.id,
    required this.supplierId,
    required this.truckerId,
    required this.loadId,
    required this.tripId,
    required this.routeLabel,
    required this.loadMaterial,
    required this.loadPriceAmount,
    required this.loadStatusLabel,
    required this.pickupDate,
    required this.supplierName,
    required this.supplierMobile,
    required this.supplierCompanyName,
    this.supplierAvatarUrl,
    required this.truckerName,
    required this.truckerMobile,
    required this.truckDisplayLabel,
    this.truckerAvatarUrl,
    required this.bookingRequestId,
    required this.bookingStatusLabel,
    required this.latestMessagePreview,
    this.latestMessageTypeHint,
    required this.lastMessageAt,
    required this.hasUnread,
    required this.isArchived,
    required this.createdAt,
    this.isAttachmentAllowed = true,
  });

  ConversationPreview toDomain() {
    return ConversationPreview(
      id: id,
      supplierId: supplierId,
      truckerId: truckerId,
      loadId: loadId,
      tripId: tripId,
      routeLabel: routeLabel,
      loadMaterial: loadMaterial,
      loadPriceAmount: loadPriceAmount,
      loadStatusLabel: loadStatusLabel,
      pickupDate: pickupDate,
      supplierName: supplierName,
      supplierMobile: supplierMobile,
      supplierCompanyName: supplierCompanyName,
      supplierAvatarUrl: supplierAvatarUrl,
      truckerName: truckerName,
      truckerMobile: truckerMobile,
      truckDisplayLabel: truckDisplayLabel,
      truckerAvatarUrl: truckerAvatarUrl,
      bookingRequestId: bookingRequestId,
      bookingStatusLabel: bookingStatusLabel,
      latestMessagePreview: latestMessagePreview,
      latestMessageTypeHint: latestMessageTypeHint,
      lastMessageAt: lastMessageAt,
      hasUnread: hasUnread,
      isArchived: isArchived,
      createdAt: createdAt,
      isAttachmentAllowed: isAttachmentAllowed,
    );
  }
}

class ConversationPreview {
  final String id;
  final String supplierId;
  final String truckerId;
  final String loadId;
  final String? tripId;
  final String routeLabel;
  final String? loadMaterial;
  final double? loadPriceAmount;
  final String? loadStatusLabel;
  final DateTime? pickupDate;
  final String supplierName;
  final String? supplierMobile;
  final String? supplierCompanyName;
  final String? supplierAvatarUrl;
  final String truckerName;
  final String? truckerMobile;
  final String? truckDisplayLabel;
  final String? truckerAvatarUrl;
  final String? bookingRequestId;
  final String? bookingStatusLabel;
  final String latestMessagePreview;
  final ChatMessageType? latestMessageTypeHint;
  final DateTime? lastMessageAt;
  final bool hasUnread;
  final bool isArchived;
  final DateTime createdAt;
  final bool isAttachmentAllowed;

  const ConversationPreview({
    required this.id,
    required this.supplierId,
    required this.truckerId,
    required this.loadId,
    required this.tripId,
    required this.routeLabel,
    required this.loadMaterial,
    required this.loadPriceAmount,
    required this.loadStatusLabel,
    required this.pickupDate,
    required this.supplierName,
    required this.supplierMobile,
    required this.supplierCompanyName,
    this.supplierAvatarUrl,
    required this.truckerName,
    required this.truckerMobile,
    required this.truckDisplayLabel,
    this.truckerAvatarUrl,
    required this.bookingRequestId,
    required this.bookingStatusLabel,
    required this.latestMessagePreview,
    this.latestMessageTypeHint,
    required this.lastMessageAt,
    required this.hasUnread,
    required this.isArchived,
    required this.createdAt,
    this.isAttachmentAllowed = true,
  });
}
