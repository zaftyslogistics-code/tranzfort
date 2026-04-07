import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/map_readers.dart';

class TruckerFleetReviewFeedback {
  final String? summary;
  final String? nextStep;

  const TruckerFleetReviewFeedback({
    required this.summary,
    required this.nextStep,
  });

  bool get hasContent => (summary ?? '').trim().isNotEmpty || (nextStep ?? '').trim().isNotEmpty;

  factory TruckerFleetReviewFeedback.fromJson(Object? raw) {
    if (raw is! Map) {
      return const TruckerFleetReviewFeedback(summary: null, nextStep: null);
    }

    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    return TruckerFleetReviewFeedback(
      summary: nullableString(map['summary']),
      nextStep: nullableString(map['next_step']),
    );
  }
}

enum TruckerFleetTruckStatus {
  pending,
  verified,
  rejected,
  editedPendingReapproval,
  archived,
  unknown,
}

extension TruckerFleetTruckStatusX on TruckerFleetTruckStatus {
  static TruckerFleetTruckStatus fromDatabase(String value) {
    return switch (value.trim().toLowerCase()) {
      'pending' => TruckerFleetTruckStatus.pending,
      'verified' => TruckerFleetTruckStatus.verified,
      'rejected' => TruckerFleetTruckStatus.rejected,
      'edited_pending_reapproval' => TruckerFleetTruckStatus.editedPendingReapproval,
      'archived' => TruckerFleetTruckStatus.archived,
      _ => TruckerFleetTruckStatus.unknown,
    };
  }

  String get databaseValue {
    return switch (this) {
      TruckerFleetTruckStatus.pending => 'pending',
      TruckerFleetTruckStatus.verified => 'verified',
      TruckerFleetTruckStatus.rejected => 'rejected',
      TruckerFleetTruckStatus.editedPendingReapproval => 'edited_pending_reapproval',
      TruckerFleetTruckStatus.archived => 'archived',
      TruckerFleetTruckStatus.unknown => 'unknown',
    };
  }

  bool get blocksApprovalDependentUse {
    return this != TruckerFleetTruckStatus.verified;
  }
}

class TruckerFleetTruck {
  final String id;
  final String? truckModelId;
  final String truckNumber;
  final String bodyType;
  final int tyres;
  final double capacityTonnes;
  final String? rcDocumentPath;
  final TruckerFleetTruckStatus status;
  final String? rejectionReason;
  final TruckerFleetReviewFeedback reviewFeedback;
  final String? modelLabel;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruckerFleetTruck({
    required this.id,
    required this.truckModelId,
    required this.truckNumber,
    required this.bodyType,
    required this.tyres,
    required this.capacityTonnes,
    required this.rcDocumentPath,
    required this.status,
    required this.rejectionReason,
    required this.reviewFeedback,
    required this.modelLabel,
    required this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasRcDocument => (rcDocumentPath ?? '').trim().isNotEmpty;
  bool get needsAttention =>
      status == TruckerFleetTruckStatus.rejected || status == TruckerFleetTruckStatus.editedPendingReapproval;

  factory TruckerFleetTruck.fromMap(Map<String, dynamic> map) {
    final modelMap = map['truck_models'];
    final resolvedModelMap = modelMap is Map<String, dynamic> ? modelMap : <String, dynamic>{};
    final make = _nullableString(resolvedModelMap['make']);
    final model = _nullableString(resolvedModelMap['model']);
    final modelLabel = switch ((make, model)) {
      (final String makeValue?, final String modelValue?) => '$makeValue $modelValue',
      (final String makeValue?, null) => makeValue,
      (null, final String modelValue?) => modelValue,
      _ => null,
    };

    return TruckerFleetTruck(
      id: (map['id'] ?? '').toString(),
      truckModelId: _nullableString(map['truck_model_id']),
      truckNumber: (map['truck_number'] ?? '').toString(),
      bodyType: (map['body_type'] ?? '').toString(),
      tyres: _readInt(map['tyres']),
      capacityTonnes: _readDouble(map['capacity_tonnes']),
      rcDocumentPath: _nullableString(map['rc_document_path']),
      status: TruckerFleetTruckStatusX.fromDatabase((map['status'] ?? 'unknown').toString()),
      rejectionReason: _nullableString(map['rejection_reason']),
      reviewFeedback: TruckerFleetReviewFeedback.fromJson(map['verification_feedback_json']),
      modelLabel: modelLabel,
      verifiedAt: _readDate(map['verified_at']),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
      updatedAt: DateTime.parse((map['updated_at'] ?? '').toString()),
    );
  }
}

abstract class TruckerFleetBackend {
  Future<List<Map<String, dynamic>>> fetchTrucks(String ownerId);

  Future<Map<String, dynamic>> createTruck(Map<String, dynamic> values);

  Future<void> updateTruck({
    required String ownerId,
    required String truckId,
    required Map<String, dynamic> values,
  });
}

class SupabaseTruckerFleetBackend implements TruckerFleetBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerFleetBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchTrucks(String ownerId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('trucks')
        .select(
          'id, truck_model_id, truck_number, body_type, tyres, capacity_tonnes, rc_document_path, status, rejection_reason, verification_feedback_json, verified_at, created_at, updated_at, truck_models(make, model)',
        )
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> createTruck(Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Trucker session is not available');
    }

    final response = await _client.from('trucks').insert(values).select('id').single();
    return response;
  }

  @override
  Future<void> updateTruck({
    required String ownerId,
    required String truckId,
    required Map<String, dynamic> values,
  }) async {
    if (_client == null) {
      throw const AuthException('Trucker session is not available');
    }

    await _client.from('trucks').update(values).eq('owner_id', ownerId).eq('id', truckId);
  }
}

class TruckerFleetRepository {
  final TruckerFleetBackend _backend;
  final String? Function() _currentUserId;

  const TruckerFleetRepository(this._backend, this._currentUserId);

  Future<Result<List<TruckerFleetTruck>>> getMyTrucks() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<TruckerFleetTruck>>(UnauthorizedFailure());
    }

    try {
      final rows = await _backend.fetchTrucks(userId);
      final trucks = rows.map(TruckerFleetTruck.fromMap).toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success<List<TruckerFleetTruck>>(trucks);
    } catch (error, stackTrace) {
      return Failure<List<TruckerFleetTruck>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> createTruck({
    required String truckNumber,
    required String bodyType,
    required int tyres,
    required double capacityTonnes,
    required String rcDocumentPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    try {
      final response = await _backend.createTruck({
        'owner_id': userId,
        'truck_number': truckNumber.trim().toUpperCase(),
        'body_type': bodyType.trim(),
        'tyres': tyres,
        'capacity_tonnes': capacityTonnes,
        'rc_document_path': rcDocumentPath.trim(),
      });
      return Success<String>((response['id'] ?? '').toString());
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> updateTruck({
    required TruckerFleetTruck existingTruck,
    required String truckNumber,
    required String bodyType,
    required int tyres,
    required double capacityTonnes,
    required String rcDocumentPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    try {
      final nextStatus = existingTruck.status == TruckerFleetTruckStatus.verified
          ? TruckerFleetTruckStatus.editedPendingReapproval.databaseValue
          : TruckerFleetTruckStatus.pending.databaseValue;
      await _backend.updateTruck(
        ownerId: userId,
        truckId: existingTruck.id,
        values: {
          'truck_number': truckNumber.trim().toUpperCase(),
          'body_type': bodyType.trim(),
          'tyres': tyres,
          'capacity_tonnes': capacityTonnes,
          'rc_document_path': rcDocumentPath.trim(),
          'status': nextStatus,
          'rejection_reason': null,
          'verification_feedback_json': null,
          'verified_at': null,
          'verified_by_admin_user_id': null,
        },
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException && error.code?.trim() == '23505') {
      return ConflictFailure(debugInfo: error.details?.toString());
    }
    return mapSupabaseError(error, stackTrace);
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse((value ?? '0').toString()) ?? 0;
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse((value ?? '0').toString()) ?? 0;
}

DateTime? _readDate(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

String? _nullableString(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) {
    return null;
  }
  return raw;
}

final truckerFleetRepositoryProvider = Provider<TruckerFleetRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerFleetRepository(
    SupabaseTruckerFleetBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
