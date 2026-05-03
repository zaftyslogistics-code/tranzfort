import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import 'auth_error_mapper.dart';
import 'auth_models.dart';

// F-005: Error codes for localization (UI should map these to AppLocalizations)
class AuthProfileErrorCodes {
  static const String roleRequired = 'auth.role_required';
  static const String nameTooShort = 'auth.name_too_short';
  static const String mobileRequired = 'auth.mobile_required';
  static const String languageUnsupported = 'auth.language_unsupported';
  static const String unexpectedResponse = 'auth.unexpected_response';
}

class AuthProfileRepository {
  final SupabaseClient? _client;

  AuthProfileRepository(this._client);

  Stream<UserProfile?> watchCurrentProfile() async* {
    if (_client == null) {
      yield null;
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    yield* _client
        .from('profiles')
        .stream(primaryKey: const ['id'])
        .eq('id', user.id)
        .map((rows) {
          final first = rows.whereType<Map<String, dynamic>>().firstOrNull;
          if (first == null) {
            return null;
          }
          return UserProfile.fromMap(first);
        });
  }

  Future<Result<UserProfile?>> getCurrentProfile() async {
    if (_client == null) {
      return const Success<UserProfile?>(null);
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Success<UserProfile?>(null);
      }

      final response = await _client
          .from('profiles')
          .select('id, full_name, mobile, email, user_role_type, preferred_language, is_banned, account_deletion_status, trust_safety_status, ban_reason, data_deletion_requested_at, avatar_url, profile_photo_document_path')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (response == null) {
        return const Success<UserProfile?>(null);
      }

      return Success<UserProfile?>(UserProfile.fromMap(response));
    } catch (error, stackTrace) {
      return Failure<UserProfile?>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> _syncCurrentUserMetadata({
    String? roleValue,
    bool? onboardingComplete,
  }) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final nextMetadata = Map<String, dynamic>.from(user.userMetadata ?? const <String, dynamic>{});
    if (roleValue != null) {
      nextMetadata['user_role'] = roleValue;
      nextMetadata['role'] = roleValue;
    }
    if (onboardingComplete != null) {
      nextMetadata['profile_complete'] = onboardingComplete;
      nextMetadata['onboarding_complete'] = onboardingComplete;
    }

    try {
      await _client.auth.updateUser(
        UserAttributes(data: nextMetadata),
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> _upsertCurrentUserProfile({
    String? roleValue,
    String? fullName,
    String? mobile,
    double? latitude,
    double? longitude,
    bool recordTerms = false,
  }) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final trimmedName = fullName?.trim();
    final trimmedMobile = mobile?.trim();
    final hasGpsCoordinates = latitude != null && longitude != null;
    final rpcParams = <String, dynamic>{
      'p_user_role_type': roleValue,
      'p_full_name': trimmedName == null || trimmedName.isEmpty ? null : trimmedName,
      'p_mobile': trimmedMobile == null || trimmedMobile.isEmpty ? null : trimmedMobile,
      'p_location_lat': latitude,
      'p_location_lng': longitude,
      'p_location_source': hasGpsCoordinates ? 'gps' : null,
      'p_record_terms': recordTerms,
    };

    try {
      await _client.rpc('upsert_current_user_profile', params: rpcParams);
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> updateRoleSelection(AppUserRole role) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final roleValue = switch (role) {
      AppUserRole.supplier => 'supplier',
      AppUserRole.trucker => 'trucker',
      AppUserRole.unknown => null,
    };

    if (roleValue == null) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to AuthProfileErrorCodes.roleRequired in UI layer
          message: 'Select a valid role to continue',
          fieldErrors: {'role': 'Role is required'},
        ),
      );
    }

    final upsertResult = await _upsertCurrentUserProfile(roleValue: roleValue);
    if (upsertResult.isFailure) {
      return upsertResult;
    }

    return _syncCurrentUserMetadata(roleValue: roleValue, onboardingComplete: false);
  }

  Future<Result<void>> provisionRoleExtension(AppUserRole role) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final roleValue = switch (role) {
      AppUserRole.supplier => 'supplier',
      AppUserRole.trucker => 'trucker',
      AppUserRole.unknown => null,
    };

    if (roleValue == null) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to AuthProfileErrorCodes.roleRequired in UI layer
          message: 'Select a valid role to continue',
          fieldErrors: {'role': 'Role is required'},
        ),
      );
    }

    try {
      await _client.rpc('ensure_role_extension', params: {'p_role': roleValue});
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> updateProfile({
    required String fullName,
    required String mobile,
    double? latitude,
    double? longitude,
  }) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final trimmedName = fullName.trim();
    final trimmedMobile = mobile.trim();
    if (trimmedName.length < 2) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to AuthProfileErrorCodes.nameTooShort in UI layer
          message: 'Enter your full name',
          fieldErrors: {'full_name': 'Name must be at least 2 characters'},
        ),
      );
    }

    if (trimmedMobile.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to AuthProfileErrorCodes.mobileRequired in UI layer
          message: 'Enter a valid mobile number',
          fieldErrors: {'mobile': 'Mobile number is required'},
        ),
      );
    }

    final upsertResult = await _upsertCurrentUserProfile(
      fullName: trimmedName,
      mobile: trimmedMobile,
      latitude: latitude,
      longitude: longitude,
      recordTerms: true,
    );
    if (upsertResult.isFailure) {
      return upsertResult;
    }

    return _syncCurrentUserMetadata(onboardingComplete: true);
  }

  Future<Result<void>> updatePreferredLanguage(String languageCode) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedLanguageCode = switch (languageCode.trim().toLowerCase()) {
      'hi' => 'hi',
      'en' => 'en',
      _ => '',
    };
    if (normalizedLanguageCode.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to AuthProfileErrorCodes.languageUnsupported in UI layer
          message: 'Select a supported language',
          fieldErrors: {'preferred_language': 'Supported languages are English and Hindi'},
        ),
      );
    }

    try {
      await _client.rpc(
        'set_current_user_preferred_language',
        params: {'p_preferred_language': normalizedLanguageCode},
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> recordTermsAcceptance() async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    try {
      await _client.from('user_consents').insert({
        'profile_id': user.id,
        'consent_type': 'terms_of_service',
        'consent_version': 'v1',
        'source_context': 'onboarding_profile',
      });
      return const Success<void>(null);
    } catch (error, stackTrace) {
      if (error is PostgrestException && error.code == '23505') {
        return const Success<void>(null);
      }

      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<AccountDeletionRequestOutcome>> requestAccountDeletion() async {
    if (_client == null) {
      return const Failure<AccountDeletionRequestOutcome>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<AccountDeletionRequestOutcome>(UnauthorizedFailure());
    }

    try {
      final response = await _client.rpc('request_account_deletion');
      if (response is! Map) {
        return const Failure<AccountDeletionRequestOutcome>(
          // TODO: Map to AuthProfileErrorCodes.unexpectedResponse in UI layer
          ServerFailure(message: 'Unexpected response format from account deletion request'),
        );
      }
      final payload = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response);
      return Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome.fromMap(payload),
      );
    } catch (error, stackTrace) {
      return Failure<AccountDeletionRequestOutcome>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<AccountDeletionRequestOutcome>> cancelAccountDeletion() async {
    if (_client == null) {
      return const Failure<AccountDeletionRequestOutcome>(UnauthorizedFailure());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Failure<AccountDeletionRequestOutcome>(UnauthorizedFailure());
    }

    try {
      final response = await _client.rpc('cancel_account_deletion_request');
      final payload = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      return Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome.fromMap(payload),
      );
    } catch (error, stackTrace) {
      return Failure<AccountDeletionRequestOutcome>(mapAuthError(error, stackTrace));
    }
  }
}
