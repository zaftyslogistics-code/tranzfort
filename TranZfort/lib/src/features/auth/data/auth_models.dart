import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String? mobile;
  final String? email;
  final String? roleType;
  final String preferredLanguage;
  final bool isBanned;
  final String accountDeletionStatus;
  final String trustSafetyStatus;
  final String? trustSafetyReasonSummary;
  final DateTime? dataDeletionRequestedAt;
  final String? avatarUrl;
  final String? city;      // User location for public profile
  final String? state;     // User location state for public profile

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.roleType,
    this.preferredLanguage = 'en',
    required this.isBanned,
    required this.accountDeletionStatus,
    required this.trustSafetyStatus,
    this.trustSafetyReasonSummary,
    this.dataDeletionRequestedAt,
    this.avatarUrl,
    this.city,
    this.state,
  });

  bool get hasName => fullName.trim().length >= 2;
  bool get hasMobile => mobile?.trim().isNotEmpty ?? false;
  bool get hasRole => roleType?.trim().isNotEmpty ?? false;
  bool get isProfileComplete => hasName && hasMobile && hasRole;
  bool get isDeactivated => accountDeletionStatus == 'deactivated_pending_cleanup';
  bool get hasRestrictedTrustState {
    final normalized = trustSafetyStatus.trim().toLowerCase();
    return isBanned || normalized == 'banned' || normalized == 'suspended';
  }

  AppUserRole get role {
    final rawRole = (roleType ?? '').trim().toLowerCase();
    return switch (rawRole) {
      'supplier' => AppUserRole.supplier,
      'trucker' => AppUserRole.trucker,
      _ => AppUserRole.unknown,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final avatarUrl = _nullableText(map['avatar_url']);
    final verificationPhotoPath = _nullableText(map['profile_photo_document_path']);
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      mobile: map['mobile']?.toString(),
      email: map['email']?.toString(),
      roleType: map['user_role_type']?.toString(),
      preferredLanguage: _normalizedPreferredLanguage(map['preferred_language']?.toString()),
      isBanned: map['is_banned'] == true,
      accountDeletionStatus: (map['account_deletion_status'] ?? 'active').toString(),
      trustSafetyStatus: (map['trust_safety_status'] ?? 'normal').toString(),
      trustSafetyReasonSummary: _nullableText(map['ban_reason']),
      dataDeletionRequestedAt: _parseDateTime(map['data_deletion_requested_at']),
      avatarUrl: avatarUrl ?? verificationPhotoPath,
      city: _nullableText(map['city']),
      state: _nullableText(map['state']),
    );
  }

  static String? _nullableText(Object? rawValue) {
    final rawText = rawValue?.toString().trim();
    if (rawText == null || rawText.isEmpty) {
      return null;
    }
    return rawText;
  }

  static DateTime? _parseDateTime(Object? rawValue) {
    final rawText = rawValue?.toString();
    if (rawText == null || rawText.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawText)?.toLocal();
  }

  static String _normalizedPreferredLanguage(String? rawValue) {
    final normalized = (rawValue ?? '').trim().toLowerCase();
    if (normalized == 'hi' || normalized == 'en') {
      return normalized;
    }
    if (normalized.isNotEmpty) {
      AppLogger.warning('Unexpected language value, defaulting to en', scope: 'auth', error: normalized);
    }
    return 'en';
  }
}

class AccountDeletionRequestOutcome {
  final String status;
  final bool blocked;
  final String? blocker;
  final String message;

  const AccountDeletionRequestOutcome({
    required this.status,
    required this.blocked,
    required this.blocker,
    required this.message,
  });

  bool get isAccepted => !blocked && status == 'deactivated_pending_cleanup';

  bool get isCancelled => !blocked && status == 'active';

  factory AccountDeletionRequestOutcome.fromMap(Map<String, dynamic> map) {
    return AccountDeletionRequestOutcome(
      status: (map['status'] ?? 'active').toString(),
      blocked: map['blocked'] == true,
      blocker: map['blocker']?.toString(),
      message: (map['message'] ?? 'Account deletion request processed').toString(),
    );
  }
}
