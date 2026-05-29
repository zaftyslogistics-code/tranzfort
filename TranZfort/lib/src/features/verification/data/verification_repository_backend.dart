part of 'verification_repository.dart';

abstract class VerificationBackend {
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId);

  Future<int> countApprovedTrucks(String userId);

  Future<int> countVerificationReadyTrucks(String userId);

  Future<void> updateProfileFields(String userId, Map<String, dynamic> values);

  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values);

  Future<String> submitVerificationForReview();

  Future<String> resubmitVerificationCase();
}

class SupabaseVerificationBackend implements VerificationBackend {
  final SupabaseClient? _client;

  const SupabaseVerificationBackend(this._client);

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to read verification profile');
    }

    final response = await _client.rpc('get_verification_profile');
    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to read supplier verification data');
    }

    final response = await _client.rpc('get_supplier_verification_extension');
    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<int> countApprovedTrucks(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final counts = await _fetchTruckVerificationCounts(userId);
    return counts['approved_count'] ?? 0;
  }

  @override
  Future<int> countVerificationReadyTrucks(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final counts = await _fetchTruckVerificationCounts(userId);
    return counts['verification_ready_count'] ?? 0;
  }

  Future<Map<String, int>> _fetchTruckVerificationCounts(String userId) async {
    final currentUserId = _client!.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to read truck verification counts');
    }

    final response = await _client!.rpc('get_trucker_truck_verification_counts');
    if (response is! Map<String, dynamic>) {
      return const {'approved_count': 0, 'verification_ready_count': 0};
    }

    return {
      'approved_count': _readCount(response['approved_count']),
      'verification_ready_count': _readCount(response['verification_ready_count']),
    };
  }

  static int _readCount(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Future<void> updateProfileFields(String userId, Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Verification session is not available');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to update verification profile');
    }

    if (values.isEmpty) {
      return;
    }

    await _client.rpc(
      'patch_verification_profile_fields',
      params: <String, dynamic>{'p_patch': values},
    );
  }

  @override
  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Verification session is not available');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to update supplier verification data');
    }

    if (values.isEmpty) {
      return;
    }

    await _client.rpc(
      'patch_verification_supplier_fields',
      params: <String, dynamic>{'p_patch': values},
    );
  }

  @override
  Future<String> submitVerificationForReview() async {
    if (_client == null) {
      throw const AuthException('Verification session is not available');
    }

    final response = await _client.rpc('submit_verification_for_review');
    final caseId = (response ?? '').toString().trim();
    if (caseId.isEmpty) {
      throw Exception('Verification submission returned empty case ID');
    }
    return caseId;
  }

  @override
  Future<String> resubmitVerificationCase() async {
    if (_client == null) {
      throw const AuthException('Verification session is not available');
    }

    final response = await _client.rpc('resubmit_verification_case');
    final caseId = (response ?? '').toString().trim();
    if (caseId.isEmpty) {
      throw Exception('Verification resubmission returned empty case ID');
    }
    return caseId;
  }
}
