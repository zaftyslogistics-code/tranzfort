import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/type_safety.dart';
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

      final response = await _client.rpc('get_current_user_profile').timeout(const Duration(seconds: 8));

      final payload = safeMap(response);
      if (payload == null || payload.isEmpty) {
        return const Success<UserProfile?>(null);
      }

      return Success<UserProfile?>(UserProfile.fromMap(payload));
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
    String? city,
    String? state,
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
    final trimmedCity = city?.trim();
    final trimmedState = state?.trim();
    final hasGpsCoordinates = latitude != null && longitude != null;
    final rpcParams = <String, dynamic>{
      'p_user_role_type': roleValue,
      'p_full_name': trimmedName == null || trimmedName.isEmpty ? null : trimmedName,
      'p_mobile': trimmedMobile == null || trimmedMobile.isEmpty ? null : trimmedMobile,
      'p_city': trimmedCity == null || trimmedCity.isEmpty ? null : trimmedCity,
      'p_state': trimmedState == null || trimmedState.isEmpty ? null : trimmedState,
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
          message: AuthProfileErrorCodes.roleRequired,
          fieldErrors: {'role': AuthProfileErrorCodes.roleRequired},
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
          message: AuthProfileErrorCodes.roleRequired,
          fieldErrors: {'role': AuthProfileErrorCodes.roleRequired},
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

  String? _roleValueFromProfileAndMetadata(UserProfile? profile) {
    final fromProfile = profile?.roleType?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) {
      return fromProfile;
    }

    final user = _client?.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final fromMetadata = (metadata['user_role'] ?? metadata['role'])?.toString().trim();
    if (fromMetadata != null && fromMetadata.isNotEmpty) {
      return fromMetadata;
    }
    return null;
  }

  Future<Result<void>> updateProfile({
    required String fullName,
    required String mobile,
    String? city,
    String? state,
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
          message: AuthProfileErrorCodes.nameTooShort,
          fieldErrors: {'full_name': AuthProfileErrorCodes.nameTooShort},
        ),
      );
    }

    if (trimmedMobile.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: AuthProfileErrorCodes.mobileRequired,
          fieldErrors: {'mobile': AuthProfileErrorCodes.mobileRequired},
        ),
      );
    }

    final profileResult = await getCurrentProfile();
    if (profileResult.isFailure) {
      return Failure<void>(profileResult.failureOrNull!);
    }

    final roleValue = _roleValueFromProfileAndMetadata(profileResult.valueOrNull);
    if (roleValue == null) {
      return const Failure<void>(
        ValidationFailure(
          message: AuthProfileErrorCodes.roleRequired,
          fieldErrors: {'role': AuthProfileErrorCodes.roleRequired},
        ),
      );
    }

    final upsertResult = await _upsertCurrentUserProfile(
      roleValue: roleValue,
      fullName: trimmedName,
      mobile: trimmedMobile,
      city: city,
      state: state,
      latitude: latitude,
      longitude: longitude,
      recordTerms: false,
    );
    if (upsertResult.isFailure) {
      return upsertResult;
    }

    final consentResult = await recordTermsAcceptance();
    if (consentResult.isFailure) {
      return consentResult;
    }

    return _syncCurrentUserMetadata(onboardingComplete: true, roleValue: roleValue);
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
          message: AuthProfileErrorCodes.languageUnsupported,
          fieldErrors: {'preferred_language': AuthProfileErrorCodes.languageUnsupported},
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
      await _client.rpc('record_user_consent');
      return const Success<void>(null);
    } catch (error, stackTrace) {
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
          ServerFailure(message: AuthProfileErrorCodes.unexpectedResponse),
        );
      }
      final payload = safeMap(response) ?? <String, dynamic>{};
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
      final payload = safeMap(response) ?? <String, dynamic>{};
      return Success<AccountDeletionRequestOutcome>(
        AccountDeletionRequestOutcome.fromMap(payload),
      );
    } catch (error, stackTrace) {
      return Failure<AccountDeletionRequestOutcome>(mapAuthError(error, stackTrace));
    }
  }
}
