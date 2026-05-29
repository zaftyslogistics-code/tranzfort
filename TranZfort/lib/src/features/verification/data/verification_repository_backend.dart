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

    return _client
        .from('profiles')
        .select(
          // P0.7: last4 only; pan_number kept as fallback for rows not yet backfilled
          'id, user_role_type, verification_status, verification_rejection_reason, verification_feedback_json, aadhaar_last4, aadhaar_front_document_path, aadhaar_back_document_path, pan_last4, pan_number, pan_document_path, profile_photo_document_path',
        )
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('suppliers')
        .select(
          'id, company_name, business_licence_document_path, gst_certificate_document_path, verification_location_city, verification_location_state, verification_location_lat, verification_location_lng, business_licence_number, gst_number',
        )
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<int> countApprovedTrucks(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.from('trucks').select('id').eq('owner_id', userId).eq('status', 'verified');
    return response.length;
  }

  @override
  Future<int> countVerificationReadyTrucks(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.from('trucks').select('id, status, rc_document_path').eq('owner_id', userId);
    return response
        .whereType<Map<String, dynamic>>()
        .where(
          (row) =>
              (VerificationDetail.nullableString(row['rc_document_path']) ?? '').isNotEmpty &&
              (row['status'] ?? '').toString().trim().toLowerCase() != 'archived',
        )
        .length;
  }

  @override
  Future<void> updateProfileFields(String userId, Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Verification session is not available');
    }

    await _client.from('profiles').update(values).eq('id', userId);
  }

  @override
  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Verification session is not available');
    }

    await _client.from('suppliers').update(values).eq('id', userId);
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
