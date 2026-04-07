import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_verification_repository_models.dart';

class SupabaseAdminVerificationBackend implements AdminVerificationBackend {
  final SupabaseClient? client;

  const SupabaseAdminVerificationBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchVerificationCases() async {
    final activeClient = client;
    if (activeClient == null) {
      debugPrint('[AdminVerification] fetchVerificationCases: client is null');
      return const [];
    }

    try {
      debugPrint('[AdminVerification] fetchVerificationCases: querying with current user: ${activeClient.auth.currentUser?.id}');
      final rows = await activeClient
          .from('verification_cases')
          .select('id, subject_type, subject_id, review_type, case_status, assigned_admin_user_id, submitted_at, last_reviewed_at, current_decision_summary')
          .inFilter('case_status', ['submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated'])
          .order('submitted_at', ascending: false);
      debugPrint('[AdminVerification] fetchVerificationCases returned ${rows.length} rows');
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[AdminVerification] fetchVerificationCases ERROR: $error');
      debugPrint('[AdminVerification] fetchVerificationCases STACK: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchVerificationCaseById(String caseId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('verification_cases')
          .select('id, subject_type, subject_id, review_type, case_status, assigned_admin_user_id, submitted_at, last_reviewed_at, current_decision_summary, current_review_feedback_json')
          .eq('id', caseId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerificationCaseEvents(String caseId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('verification_case_events')
          .select('id, event_type, event_summary, internal_note, created_at')
          .eq('verification_case_id', caseId)
          .order('created_at', ascending: false);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('admin_users')
          .select('id, full_name, role')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('profiles')
          .select('id, full_name, mobile, email, user_role_type')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchProfileById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('profiles')
          .select('id, full_name, mobile, email, user_role_type, verification_status, created_at, avatar_url, aadhaar_number, aadhaar_last4, pan_number, aadhaar_front_document_path, aadhaar_back_document_path, pan_document_path, profile_photo_document_path, verification_feedback_json, profile_photo_review_status, profile_photo_rejection_reason, profile_photo_feedback_json, profile_photo_submitted_at, profile_photo_last_reviewed_at')
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSuppliersByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('suppliers')
          .select('id, company_name')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('suppliers')
          .select('id, company_name, gst_number, gst_certificate_document_path, business_licence_number, business_licence_document_path, verification_location_city, verification_location_state, verification_location_lat, verification_location_lng')
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('truckers')
          .select('id, dl_number, rating, total_trips, completed_trips')
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      debugPrint('[AdminVerification] fetchTruckerById failed for $id: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTrucksByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('trucks')
          .select('id, owner_id, truck_number, body_type')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('trucks')
          .select('id, owner_id, truck_number, body_type, tyres, capacity_tonnes, rc_document_path, status, rejection_reason, verification_feedback_json, verified_at')
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<String?> createVerificationDocumentSignedUrl(String path) async {
    final activeClient = client;
    final normalizedPath = path.trim();
    if (activeClient == null || normalizedPath.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(normalizedPath);
    if (parsed != null && parsed.hasScheme) {
      if (parsed.scheme == 'http' || parsed.scheme == 'https') {
        return normalizedPath;
      }
      if (parsed.scheme == 'file') {
        return null;
      }
    }

    try {
      final bucketAndPath = _resolveStorageTarget(normalizedPath);
      return await activeClient.storage.from(bucketAndPath.bucket).createSignedUrl(bucketAndPath.path, 3600);
    } catch (error, stackTrace) {
      debugPrint('createVerificationDocumentSignedUrl failed for $normalizedPath: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<bool> approveVerificationCase({
    required String caseId,
    required String subjectType,
    required String subjectId,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }

    try {
      if (subjectType == 'truck') {
        await activeClient.rpc(
          'update_truck_verification_state',
          params: {
            'p_truck_id': subjectId,
            'p_next_status': 'verified',
            'p_reason': null,
            'p_feedback_json': null,
          },
        );
      } else {
        await activeClient.rpc(
          'approve_verification_case',
          params: {
            'p_case_id': caseId,
          },
        );
      }
      return true;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<bool> rejectVerificationCase({
    required String caseId,
    required String subjectType,
    required String subjectId,
    required String reason,
    VerificationReviewFeedbackPayload? feedback,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }

    try {
      if (subjectType == 'truck') {
        await activeClient.rpc(
          'update_truck_verification_state',
          params: {
            'p_truck_id': subjectId,
            'p_next_status': 'rejected',
            'p_reason': reason,
            'p_feedback_json': feedback?.toJson(),
          },
        );
      } else {
        await activeClient.rpc(
          'reject_verification_case',
          params: {
            'p_case_id': caseId,
            'p_reason': reason,
            'p_feedback_json': feedback?.toJson(),
          },
        );
      }
      return true;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

({String bucket, String path}) _resolveStorageTarget(String rawPath) {
  final normalized = rawPath.trim().replaceFirst(RegExp(r'^/+'), '');
  if (normalized.startsWith('truck-documents/')) {
    return (bucket: 'truck-documents', path: normalized.substring('truck-documents/'.length));
  }
  if (normalized.startsWith('verification-documents/')) {
    return (bucket: 'verification-documents', path: normalized.substring('verification-documents/'.length));
  }
  final bucket = normalized.contains('/rc/') ? 'truck-documents' : 'verification-documents';
  return (bucket: bucket, path: normalized);
}
