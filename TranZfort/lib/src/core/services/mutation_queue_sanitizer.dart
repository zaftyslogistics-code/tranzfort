import '../models/mutation_queue.dart';

/// Sanitizes mutation queue payloads to minimize sensitive data at rest.
///
/// Even with encryption, we should minimize what we store. This utility
/// redacts or removes fields that are not strictly needed for replay.
class MutationQueueSanitizer {
  const MutationQueueSanitizer();

  /// Sanitize a payload based on the mutation target.
  /// Returns a new map with sensitive fields redacted or removed.
  Map<String, dynamic> sanitize(MutationTarget target, Map<String, dynamic> payload) {
    return switch (target) {
      MutationTarget.chatSend => _sanitizeChatSend(payload),
      MutationTarget.profileUpdate => _sanitizeProfileUpdate(payload),
      MutationTarget.supplierProfileUpdate => _sanitizeProfileUpdate(payload),
      MutationTarget.disputeRaise => _sanitizeDispute(payload),
      MutationTarget.reviewSubmit => _sanitizeReview(payload),
      MutationTarget.reviewReply => _sanitizeReview(payload),
      MutationTarget.podProofUpload => _sanitizeProofUpload(payload),
      MutationTarget.lrProofUpload => _sanitizeProofUpload(payload),
      _ => Map<String, dynamic>.from(payload),
    };
  }

  /// Keep only essential fields for chat message replay.
  Map<String, dynamic> _sanitizeChatSend(Map<String, dynamic> payload) {
    return {
      if (payload.containsKey('conversation_id')) 'conversation_id': payload['conversation_id'],
      if (payload.containsKey('type')) 'type': payload['type'],
      // Store text_body length instead of content for privacy
      if (payload.containsKey('text_body'))
        'text_body_length': (payload['text_body'] as String?)?.length ?? 0,
      if (payload.containsKey('attachment_path')) 'attachment_path': payload['attachment_path'],
    };
  }

  /// Remove PII from profile update payloads.
  Map<String, dynamic> _sanitizeProfileUpdate(Map<String, dynamic> payload) {
    final sanitized = Map<String, dynamic>.from(payload);
    // Redact any full name or email fields
    sanitized.remove('full_name');
    sanitized.remove('email');
    sanitized.remove('mobile');
    sanitized.remove('aadhaar_number');
    sanitized.remove('pan_number');
    return sanitized;
  }

  /// Keep only dispute metadata, not full context.
  Map<String, dynamic> _sanitizeDispute(Map<String, dynamic> payload) {
    return {
      if (payload.containsKey('trip_id')) 'trip_id': payload['trip_id'],
      if (payload.containsKey('load_id')) 'load_id': payload['load_id'],
      if (payload.containsKey('reason_code')) 'reason_code': payload['reason_code'],
      // Store description length instead of full text
      if (payload.containsKey('description'))
        'description_length': (payload['description'] as String?)?.length ?? 0,
    };
  }

  /// Keep only review metadata, not full content.
  Map<String, dynamic> _sanitizeReview(Map<String, dynamic> payload) {
    return {
      if (payload.containsKey('target_user_id')) 'target_user_id': payload['target_user_id'],
      if (payload.containsKey('trip_id')) 'trip_id': payload['trip_id'],
      if (payload.containsKey('rating')) 'rating': payload['rating'],
      // Store review text length instead of full content
      if (payload.containsKey('review_text'))
        'review_text_length': (payload['review_text'] as String?)?.length ?? 0,
      if (payload.containsKey('reply_text'))
        'reply_text_length': (payload['reply_text'] as String?)?.length ?? 0,
    };
  }

  /// Keep only file paths, not raw proof data.
  Map<String, dynamic> _sanitizeProofUpload(Map<String, dynamic> payload) {
    return {
      if (payload.containsKey('trip_id')) 'trip_id': payload['trip_id'],
      if (payload.containsKey('pod_path')) 'pod_path': payload['pod_path'],
      if (payload.containsKey('lr_path')) 'lr_path': payload['lr_path'],
      if (payload.containsKey('gps_lat')) 'gps_lat': payload['gps_lat'],
      if (payload.containsKey('gps_lng')) 'gps_lng': payload['gps_lng'],
    };
  }

  /// Map error messages to stable error codes for persistence.
  /// Prevents storing raw error strings that may contain sensitive data.
  static String sanitizeError(String rawError) {
    // Map known error patterns to stable codes
    if (rawError.contains('AuthException') || rawError.contains('JWT')) {
      return 'ERR_AUTH';
    }
    if (rawError.contains('SocketException') || rawError.contains('timeout')) {
      return 'ERR_NETWORK';
    }
    if (rawError.contains('PostgrestException') || rawError.contains('PGRST')) {
      return 'ERR_BACKEND';
    }
    if (rawError.contains('FormatException') || rawError.contains('type')) {
      return 'ERR_PARSE';
    }
    if (rawError.contains('permission') || rawError.contains('denied')) {
      return 'ERR_PERMISSION';
    }
    return 'ERR_UNKNOWN';
  }
}
