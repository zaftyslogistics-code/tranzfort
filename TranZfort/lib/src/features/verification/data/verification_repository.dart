import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

part 'verification_repository_backend.dart';
part 'verification_repository_feedback_models.dart';
part 'verification_repository_models.dart';

class VerificationRepository {
  final VerificationBackend _backend;
  final String? Function() _currentUserId;

  const VerificationRepository(this._backend, this._currentUserId);

  Future<Result<VerificationDetail?>> fetchCurrentDetail() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Success<VerificationDetail?>(null);
    }

    try {
      final profileMap = await _backend.fetchProfile(userId);
      if (profileMap == null) {
        return const Success<VerificationDetail?>(null);
      }
      final rawRole = (profileMap['user_role_type'] ?? '').toString().trim().toLowerCase();
      final supplierMap = rawRole == 'supplier' ? await _backend.fetchSupplierExtension(userId) : null;
      final approvedTruckCount = rawRole == 'trucker' ? await _backend.countApprovedTrucks(userId) : 0;
      final verificationReadyTruckCount = rawRole == 'trucker' ? await _backend.countVerificationReadyTrucks(userId) : 0;
      return Success<VerificationDetail?>(
        VerificationDetail.fromMaps(
          profileMap,
          supplierMap,
          approvedTruckCount: approvedTruckCount,
          verificationReadyTruckCount: verificationReadyTruckCount,
        ),
      );
    } catch (error, stackTrace) {
      return Failure<VerificationDetail?>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> saveVerificationPacketFields({
    String? companyName,
    required String aadhaarNumber,
    required String panNumber,
    String? businessLicenceNumber,
    String? gstNumber,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedAadhaar = aadhaarNumber.trim();
    final normalizedPan = panNumber.trim().toUpperCase();
    final normalizedCompanyName = VerificationDetail.nullableString(companyName);
    final normalizedBusinessLicence = VerificationDetail.nullableString(businessLicenceNumber);
    final normalizedGst = VerificationDetail.nullableString(gstNumber)?.toUpperCase();
    final fieldErrors = <String, String>{};

    try {
      final profileMap = await _backend.fetchProfile(userId);
      if (profileMap == null) {
        return const Failure<void>(NotFoundFailure(message: 'Profile is unavailable'));
      }

      final rawRole = (profileMap['user_role_type'] ?? '').toString().trim().toLowerCase();
      if (rawRole == 'supplier' && (normalizedCompanyName ?? '').isEmpty) {
        fieldErrors['company_name'] = 'Company name is required';
      }
      if (rawRole == 'supplier' && (normalizedBusinessLicence ?? '').isEmpty) {
        fieldErrors['business_licence_number'] = 'Business licence number is required';
      }
      if (normalizedAadhaar.length < 4) {
        fieldErrors['aadhaar_number'] = 'Aadhaar number must be at least 4 digits';
      }
      if (fieldErrors.isNotEmpty) {
        return Failure<void>(
          ValidationFailure(
            message: 'Please correct the verification details.',
            fieldErrors: fieldErrors,
          ),
        );
      }

      await _backend.updateProfileFields(userId, {
        // P0.7 Simplified: Only write last4 to profiles, not full numbers
        'aadhaar_last4': normalizedAadhaar.substring(normalizedAadhaar.length - 4),
        'pan_last4': normalizedPan.substring(normalizedPan.length - 4),
      });
      if (rawRole == 'supplier') {
        await _backend.updateSupplierFields(userId, {
          'company_name': normalizedCompanyName,
          'business_licence_number': normalizedBusinessLicence,
          'gst_number': normalizedGst,
        });
      }

      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> saveSupplierVerificationLocation({
    required String city,
    String? state,
    required double latitude,
    required double longitude,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }
    final trimmedCity = city.trim();
    if (trimmedCity.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Verification city is required',
          fieldErrors: {'verification_location_city': 'Verification city is required'},
        ),
      );
    }

    try {
      final profileMap = await _backend.fetchProfile(userId);
      if (profileMap == null) {
        return const Failure<void>(NotFoundFailure(message: 'Profile is unavailable'));
      }
      final rawRole = (profileMap['user_role_type'] ?? '').toString().trim().toLowerCase();
      if (rawRole != 'supplier') {
        return const Failure<void>(
          BusinessRuleFailure(message: 'Verification location capture is only available for supplier verification.'),
        );
      }
      await _backend.updateSupplierFields(userId, {
        'verification_location_city': trimmedCity,
        'verification_location_state': VerificationDetail.nullableString(state),
        'verification_location_lat': latitude,
        'verification_location_lng': longitude,
      });
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> saveDocumentPath({
    required VerificationDocumentType type,
    required String storagePath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }
    final normalizedPath = storagePath.trim();
    if (normalizedPath.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Document path is required',
          fieldErrors: {'storage_path': 'Document path is required'},
        ),
      );
    }

    try {
      final profileMap = await _backend.fetchProfile(userId);
      if (profileMap == null) {
        return const Failure<void>(NotFoundFailure(message: 'Profile is unavailable'));
      }
      final rawRole = (profileMap['user_role_type'] ?? '').toString().trim().toLowerCase();
      if (type == VerificationDocumentType.businessLicence || type == VerificationDocumentType.gstCertificate) {
        if (rawRole != 'supplier') {
          return Failure<void>(
            BusinessRuleFailure(
              message: type == VerificationDocumentType.businessLicence
                  ? 'Business licence upload is only available for supplier verification.'
                  : 'GST certificate upload is only available for supplier verification.',
            ),
          );
        }
        await _backend.updateSupplierFields(userId, {
          if (type == VerificationDocumentType.businessLicence) 'business_licence_document_path': normalizedPath,
          if (type == VerificationDocumentType.gstCertificate) 'gst_certificate_document_path': normalizedPath,
        });
      } else {
        final profileUpdates = <String, dynamic>{
          if (type == VerificationDocumentType.aadhaarFront) 'aadhaar_front_document_path': normalizedPath,
          if (type == VerificationDocumentType.aadhaarBack) 'aadhaar_back_document_path': normalizedPath,
          if (type == VerificationDocumentType.pan) 'pan_document_path': normalizedPath,
          if (type == VerificationDocumentType.profilePhoto) 'profile_photo_document_path': normalizedPath,
        };
        await _backend.updateProfileFields(userId, profileUpdates);
      }
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> submitForReview({required bool isResubmission}) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    try {
      final caseId = isResubmission
          ? await _backend.resubmitVerificationCase()
          : await _backend.submitVerificationForReview();
      return Success<String>(caseId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final normalized = error.message.trim().toLowerCase();
      if (normalized.contains('already verified') ||
          normalized.contains('already under review') ||
          normalized.contains('already active') ||
          normalized.contains('role is not configured')) {
        return BusinessRuleFailure(message: error.message.trim(), debugInfo: error.details?.toString());
      }
    }
    return mapSupabaseError(error, stackTrace);
  }
}

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return VerificationRepository(
    SupabaseVerificationBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
