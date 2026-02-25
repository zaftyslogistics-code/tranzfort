import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

class LoadRepository {
  final SupabaseClient _supabase;

  LoadRepository(this._supabase);

  Future<Result<Map<String, dynamic>>> createLoad({
    required String supplierId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final insertPayload = <String, dynamic>{
        ...payload,
        'supplier_id': supplierId,
        'trucks_booked': 0,
        'status': 'active',
      };

      final response = await _supabase
          .from('loads')
          .insert(insertPayload)
          .select()
          .single();

      final supplier = await _supabase
          .from('suppliers')
          .select('total_loads_posted,active_loads_count')
          .eq('id', supplierId)
          .single();

      final totalLoadsPosted =
          (supplier['total_loads_posted'] as int? ?? 0) + 1;
      final activeLoadsCount =
          (supplier['active_loads_count'] as int? ?? 0) + 1;

      await _supabase
          .from('suppliers')
          .update({
            'total_loads_posted': totalLoadsPosted,
            'active_loads_count': activeLoadsCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', supplierId);

      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> findLoads({
    required int page,
    required int pageSize,
    String? originCity,
    String? destinationCity,
    String? material,
    String? truckType,
    String sortBy = 'newest',
  }) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      var query = _supabase
          .from('loads')
          .select()
          .isFilter('parent_load_id', null)
          .eq('status', 'active');

      if (originCity != null && originCity.trim().isNotEmpty) {
        query = query.ilike('origin_city', '%${originCity.trim()}%');
      }
      if (destinationCity != null && destinationCity.trim().isNotEmpty) {
        query = query.ilike('dest_city', '%${destinationCity.trim()}%');
      }
      if (material != null && material.trim().isNotEmpty) {
        query = query.eq('material', material.trim());
      }
      if (truckType != null && truckType.trim().isNotEmpty) {
        query = query.or(
          'required_truck_type.eq.$truckType,required_truck_type.is.null',
        );
      }

      final response = switch (sortBy) {
        'price_high' => await query
            .order('price', ascending: false)
            .range(from, to),
        'price_low' => await query
            .order('price', ascending: true)
            .range(from, to),
        'pickup_date' => await query
            .order('pickup_date', ascending: true)
            .range(from, to),
        _ => await query
            .order('created_at', ascending: false)
            .range(from, to),
      };

      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> myLoads({
    required String supplierId,
    required bool completed,
  }) async {
    try {
      var query = _supabase
          .from('loads')
          .select()
          .eq('supplier_id', supplierId)
          .isFilter('parent_load_id', null);

      if (completed) {
        query = query.inFilter('status', ['completed', 'cancelled', 'expired']);
      } else {
        query = query.inFilter('status', [
          'active',
          'pending_approval',
          'booked',
          'in_transit',
        ]);
      }

      final response = await query.order('created_at', ascending: false);
      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getLoadDetail(String loadId) async {
    try {
      final response = await _supabase
          .from('loads')
          .select()
          .eq('id', loadId)
          .single();
      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getChildLoads(
    String parentLoadId,
  ) async {
    try {
      final response = await _supabase
          .from('loads')
          .select()
          .eq('parent_load_id', parentLoadId)
          .order('created_at', ascending: false);
      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> deactivateLoad(String loadId) async {
    try {
      await _supabase
          .from('loads')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loadId);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> bookLoad({
    required String parentLoadId,
    required String truckerId,
    required String truckId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'book_load',
        params: {
          'p_parent_load_id': parentLoadId,
          'p_trucker_id': truckerId,
          'p_truck_id': truckId,
        },
      );
      final map = response as Map<String, dynamic>;
      final success = map['success'] == true;
      if (!success) {
        return Failure(
          AppFailureType.validation,
          debugMessage: map['error']?.toString(),
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> approveBooking(String childLoadId) async {
    try {
      final response = await _supabase.rpc(
        'approve_booking',
        params: {'p_child_load_id': childLoadId},
      );
      final map = response as Map<String, dynamic>;
      if (map['success'] != true) {
        return Failure(
          AppFailureType.validation,
          debugMessage: map['error']?.toString(),
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> rejectBooking(String childLoadId) async {
    try {
      final response = await _supabase.rpc(
        'reject_booking',
        params: {'p_child_load_id': childLoadId},
      );
      final map = response as Map<String, dynamic>;
      if (map['success'] != true) {
        return Failure(
          AppFailureType.validation,
          debugMessage: map['error']?.toString(),
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getVerifiedTrucks(
    String truckerId,
  ) async {
    try {
      final response = await _supabase
          .from('trucks')
          .select(
            'id,truck_number,body_type,tyres,capacity_tonnes,truck_model_id,status',
          )
          .eq('owner_id', truckerId)
          .eq('status', 'verified');
      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<double>> getDieselPrice(String state) async {
    try {
      final response = await _supabase
          .from('diesel_prices')
          .select('price_per_litre')
          .ilike('state', state)
          .maybeSingle();
      if (response == null) {
        return const Success(90);
      }
      final value = (response['price_per_litre'] as num?)?.toDouble() ?? 90;
      return Success(value);
    } catch (_) {
      return const Success(90);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getMyTrips({
    required String truckerId,
    required bool completed,
  }) async {
    try {
      final statuses = completed
          ? const ['completed']
          : const ['at_pickup', 'in_transit', 'delivered', 'pod_uploaded'];

      final response = await _supabase
          .from('trips')
          .select('''
            id,
            stage,
            start_time,
            end_time,
            created_at,
            lr_photo_url,
            pod_photo_url,
            load:loads(
              id,
              supplier_id,
              assigned_trucker_id,
              origin_city,
              dest_city,
              material,
              weight_tonnes,
              status
            ),
            truck:trucks(
              id,
              truck_number
            )
          ''')
          .eq('trucker_id', truckerId)
          .inFilter('stage', statuses)
          .order('created_at', ascending: false);

      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getTripDetail(String tripId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('''
            id,
            stage,
            trucker_id,
            start_time,
            end_time,
            lr_number,
            lr_photo_url,
            pod_photo_url,
            last_known_lat,
            last_known_lng,
            last_location_at,
            load:loads(
              id,
              origin_city,
              dest_city,
              material,
              weight_tonnes,
              distance_km,
              status,
              price,
              advance_percentage
            ),
            truck:trucks(
              id,
              truck_number,
              body_type,
              tyres
            )
          ''')
          .eq('id', tripId)
          .single();

      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> startTrip({
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _supabase.rpc(
        'start_trip',
        params: {'p_trip_id': tripId, 'p_lat': lat, 'p_lng': lng},
      );

      final map = response as Map<String, dynamic>;
      if (map['success'] != true) {
        return Failure(
          AppFailureType.validation,
          debugMessage: map['error']?.toString(),
        );
      }

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> markDelivered({
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    try {
      final trip = await _supabase
          .from('trips')
          .select('id,stage')
          .eq('id', tripId)
          .single();

      final stage = (trip['stage'] ?? '').toString();
      if (stage != 'in_transit') {
        return const Failure(
          AppFailureType.validation,
          debugMessage: 'Trip is not in transit',
        );
      }

      await _supabase
          .from('trips')
          .update({
            'stage': 'delivered',
            'last_known_lat': lat,
            'last_known_lng': lng,
            'last_location_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> uploadLr({
    required String tripId,
    required String lrPhotoUrl,
  }) async {
    try {
      final trip = await _supabase
          .from('trips')
          .select('id,stage,load_id')
          .eq('id', tripId)
          .single();

      final stage = (trip['stage'] ?? '').toString();
      if (stage != 'at_pickup') {
        return const Failure(
          AppFailureType.validation,
          debugMessage: 'LR can only be uploaded at pickup stage',
        );
      }

      final loadId = (trip['load_id'] ?? '').toString();
      if (loadId.isEmpty) {
        return const Failure(
          AppFailureType.notFound,
          debugMessage: 'Related load not found',
        );
      }

      final now = DateTime.now().toIso8601String();

      await _supabase
          .from('trips')
          .update({'lr_photo_url': lrPhotoUrl, 'updated_at': now})
          .eq('id', tripId);

      await _supabase
          .from('loads')
          .update({'lr_photo_url': lrPhotoUrl, 'updated_at': now})
          .eq('id', loadId);

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> uploadPod({
    required String tripId,
    required String podPhotoUrl,
    double? lat,
    double? lng,
  }) async {
    try {
      final trip = await _supabase
          .from('trips')
          .select('id,stage,load_id')
          .eq('id', tripId)
          .single();

      final stage = (trip['stage'] ?? '').toString();
      if (stage != 'delivered') {
        return const Failure(
          AppFailureType.validation,
          debugMessage: 'Trip is not delivered yet',
        );
      }

      final loadId = (trip['load_id'] ?? '').toString();
      if (loadId.isEmpty) {
        return const Failure(
          AppFailureType.notFound,
          debugMessage: 'Related load not found',
        );
      }

      final now = DateTime.now().toIso8601String();

      await _supabase
          .from('trips')
          .update({
            'stage': 'pod_uploaded',
            'pod_photo_url': podPhotoUrl,
            'last_known_lat': lat,
            'last_known_lng': lng,
            'last_location_at': now,
            'updated_at': now,
          })
          .eq('id', tripId);

      await _supabase
          .from('loads')
          .update({'pod_photo_url': podPhotoUrl, 'updated_at': now})
          .eq('id', loadId);

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> confirmDeliveryForChildLoad(String childLoadId) async {
    try {
      final trip = await _supabase
          .from('trips')
          .select('id,stage,trucker_id')
          .eq('load_id', childLoadId)
          .maybeSingle();

      if (trip == null) {
        return const Failure(
          AppFailureType.notFound,
          debugMessage: 'Trip not found for load',
        );
      }

      final stage = (trip['stage'] ?? '').toString();
      if (stage != 'pod_uploaded') {
        return const Failure(
          AppFailureType.validation,
          debugMessage: 'Trip is not awaiting POD confirmation',
        );
      }

      final truckerId = (trip['trucker_id'] ?? '').toString();
      final now = DateTime.now().toIso8601String();

      await _supabase
          .from('trips')
          .update({'stage': 'completed', 'end_time': now, 'updated_at': now})
          .eq('load_id', childLoadId);

      await _supabase
          .from('loads')
          .update({
            'status': 'completed',
            'completed_at': now,
            'updated_at': now,
          })
          .eq('id', childLoadId);

      if (truckerId.isNotEmpty) {
        final trucker = await _supabase
            .from('truckers')
            .select('completed_trips')
            .eq('id', truckerId)
            .maybeSingle();
        if (trucker != null) {
          final completedTrips = (trucker['completed_trips'] as int? ?? 0) + 1;
          await _supabase
              .from('truckers')
              .update({'completed_trips': completedTrips, 'updated_at': now})
              .eq('id', truckerId);
        }
      }

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> submitRating({
    required String loadId,
    required String reviewerId,
    required String revieweeId,
    required String reviewerRole,
    required int score,
    String? comment,
  }) async {
    try {
      await _supabase.from('ratings').insert({
        'load_id': loadId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'reviewer_role': reviewerRole,
        'score': score,
        'comment': comment,
      });
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>?>> getRatingForLoad({
    required String loadId,
    required String reviewerId,
  }) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('id,score,comment,created_at')
          .eq('load_id', loadId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();
      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> updateProfileLastKnownLocation({
    required String profileId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'last_known_lat': lat,
            'last_known_lng': lng,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profileId);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}
