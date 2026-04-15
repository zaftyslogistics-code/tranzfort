import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

class SupplierProfile {
  final String id;
  final String fullName;
  final String? mobile;
  final String? email;
  final String verificationStatus;
  final String? companyName;
  final String? businessLicenceNumber;
  final String? gstNumber;
  final int totalLoadsPosted;
  final int activeLoadsCount;

  const SupplierProfile({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.verificationStatus,
    required this.companyName,
    required this.businessLicenceNumber,
    required this.gstNumber,
    required this.totalLoadsPosted,
    required this.activeLoadsCount,
  });

  bool get hasCompanyName => (companyName ?? '').trim().isNotEmpty;
  bool get isVerificationApproved => verificationStatus.trim().toLowerCase() == 'verified';
  bool get canAccessWorkspace => isVerificationApproved && hasCompanyName;

  factory SupplierProfile.fromMaps(
    Map<String, dynamic> profileMap,
    Map<String, dynamic>? supplierMap,
  ) {
    return SupplierProfile(
      id: (profileMap['id'] ?? '').toString(),
      fullName: (profileMap['full_name'] ?? '').toString(),
      mobile: _nullableString(profileMap['mobile']),
      email: _nullableString(profileMap['email']),
      verificationStatus: (profileMap['verification_status'] ?? 'unverified').toString(),
      companyName: _nullableString(supplierMap?['company_name']),
      businessLicenceNumber: _nullableString(supplierMap?['business_licence_number']),
      gstNumber: _nullableString(supplierMap?['gst_number']),
      totalLoadsPosted: _readInt(supplierMap?['total_loads_posted']),
      activeLoadsCount: _readInt(supplierMap?['active_loads_count']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  static String? _nullableString(Object? value) {
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

abstract class SupplierProfileBackend {
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId);

  Future<void> updateSupplierExtension(
    String userId,
    Map<String, dynamic> values,
  );
}

class SupabaseSupplierProfileBackend implements SupplierProfileBackend {
  final SupabaseClient? _client;

  const SupabaseSupplierProfileBackend(this._client);

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('profiles')
        .select('id, full_name, mobile, email, verification_status')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('suppliers')
        .select('id, company_name, business_licence_number, gst_number, total_loads_posted, active_loads_count')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  @override
  Future<void> updateSupplierExtension(
    String userId,
    Map<String, dynamic> values,
  ) async {
    if (_client == null) {
      throw const AuthException('Supplier session is not available');
    }

    await _client.from('suppliers').update(values).eq('id', userId);
  }
}

class SupplierProfileRepository {
  final SupplierProfileBackend _backend;
  final String? Function() _currentUserId;

  const SupplierProfileRepository(this._backend, this._currentUserId);

  Future<Result<SupplierProfile?>> fetchCurrentSupplierProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Success<SupplierProfile?>(null);
    }

    try {
      final profileMap = await _backend.fetchProfile(userId);
      if (profileMap == null) {
        return const Success<SupplierProfile?>(null);
      }

      final supplierMap = await _backend.fetchSupplierExtension(userId);
      return Success<SupplierProfile?>(
        SupplierProfile.fromMaps(profileMap, supplierMap),
      );
    } catch (error, stackTrace) {
      return Failure<SupplierProfile?>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> updateBusinessFields({
    required String companyName,
    String? businessLicenceNumber,
    String? gstNumber,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final trimmedCompanyName = companyName.trim();
    final trimmedBusinessLicenceNumber = businessLicenceNumber?.trim();
    final trimmedGstNumber = gstNumber?.trim();

    if (trimmedCompanyName.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter your company name',
          fieldErrors: {'company_name': 'Company name is required'},
        ),
      );
    }

    try {
      await _backend.updateSupplierExtension(userId, {
        'company_name': trimmedCompanyName,
        'business_licence_number': _nullableString(trimmedBusinessLicenceNumber),
        'gst_number': _nullableString(trimmedGstNumber),
      });
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);

  static String? _nullableString(Object? value) {
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}

final supplierProfileRepositoryProvider = Provider<SupplierProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierProfileRepository(
    SupabaseSupplierProfileBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
