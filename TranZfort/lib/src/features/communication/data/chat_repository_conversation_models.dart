part of 'chat_repository.dart';

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
  final String truckerName;
  final String? truckerMobile;
  final String? truckDisplayLabel;
  final String? bookingRequestId;
  final String? bookingStatusLabel;
  final String latestMessagePreview;
  final DateTime? lastMessageAt;
  final bool hasUnread;
  final bool isArchived;
  final DateTime createdAt;

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
    required this.truckerName,
    required this.truckerMobile,
    required this.truckDisplayLabel,
    required this.bookingRequestId,
    required this.bookingStatusLabel,
    required this.latestMessagePreview,
    required this.lastMessageAt,
    required this.hasUnread,
    required this.isArchived,
    required this.createdAt,
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
      truckerName: truckerName,
      truckerMobile: truckerMobile,
      truckDisplayLabel: truckDisplayLabel,
      bookingRequestId: bookingRequestId,
      bookingStatusLabel: bookingStatusLabel,
      latestMessagePreview: latestMessagePreview,
      lastMessageAt: lastMessageAt,
      hasUnread: hasUnread,
      isArchived: isArchived,
      createdAt: createdAt,
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
  final String truckerName;
  final String? truckerMobile;
  final String? truckDisplayLabel;
  final String? bookingRequestId;
  final String? bookingStatusLabel;
  final String latestMessagePreview;
  final DateTime? lastMessageAt;
  final bool hasUnread;
  final bool isArchived;
  final DateTime createdAt;

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
    required this.truckerName,
    required this.truckerMobile,
    required this.truckDisplayLabel,
    required this.bookingRequestId,
    required this.bookingStatusLabel,
    required this.latestMessagePreview,
    required this.lastMessageAt,
    required this.hasUnread,
    required this.isArchived,
    required this.createdAt,
  });
}
