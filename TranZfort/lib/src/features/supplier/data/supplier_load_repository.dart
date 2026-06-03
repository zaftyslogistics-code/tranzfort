import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';
import 'supplier_load_models.dart';
import 'supplier_load_repost.dart';
import 'supplier_load_repository_backend.dart';

export 'supplier_load_repository_backend.dart';

class MaterialCatalogItem {
  final String code;
  final String nameEn;
  final String? nameHi;
  final String? groupCode;

  const MaterialCatalogItem({
    required this.code,
    required this.nameEn,
    required this.nameHi,
    required this.groupCode,
  });

  factory MaterialCatalogItem.fromMap(Map<String, dynamic> map) {
    final code = (map['code'] ?? '').toString().trim();
    final nameEn = (map['name_en'] ?? '').toString().trim();
    return MaterialCatalogItem(
      code: code,
      nameEn: nameEn,
      nameHi: (map['name_hi'] as String?)?.trim(),
      groupCode: (map['group_code'] as String?)?.trim(),
    );
  }
}

class VehicleCategoryCatalogItem {
  final String code;
  final String nameEn;
  final String? nameHi;
  final String uiMode;

  const VehicleCategoryCatalogItem({
    required this.code,
    required this.nameEn,
    required this.nameHi,
    required this.uiMode,
  });

  factory VehicleCategoryCatalogItem.fromMap(Map<String, dynamic> map) {
    return VehicleCategoryCatalogItem(
      code: (map['code'] ?? '').toString().trim(),
      nameEn: (map['name_en'] ?? '').toString().trim(),
      nameHi: (map['name_hi'] as String?)?.trim(),
      uiMode: (map['ui_mode'] ?? '').toString().trim(),
    );
  }
}

class VehicleBodyStyleCatalogItem {
  final String categoryCode;
  final String code;
  final String nameEn;
  final String? nameHi;

  const VehicleBodyStyleCatalogItem({
    required this.categoryCode,
    required this.code,
    required this.nameEn,
    required this.nameHi,
  });

  factory VehicleBodyStyleCatalogItem.fromMap(Map<String, dynamic> map) {
    return VehicleBodyStyleCatalogItem(
      categoryCode: (map['category_code'] ?? '').toString().trim(),
      code: (map['code'] ?? '').toString().trim(),
      nameEn: (map['name_en'] ?? '').toString().trim(),
      nameHi: (map['name_hi'] as String?)?.trim(),
    );
  }
}

class VehicleConfigurationCatalogItem {
  final String code;
  final String categoryCode;
  final String? bodyStyleCode;
  final String labelEn;
  final String? labelHi;
  final int? wheelsW;
  final String? lengthFt;
  final double? loadingTonMin;
  final double? loadingTonMax;
  final bool isSpecial;

  const VehicleConfigurationCatalogItem({
    required this.code,
    required this.categoryCode,
    required this.bodyStyleCode,
    required this.labelEn,
    required this.labelHi,
    required this.wheelsW,
    required this.lengthFt,
    required this.loadingTonMin,
    required this.loadingTonMax,
    required this.isSpecial,
  });

  factory VehicleConfigurationCatalogItem.fromMap(Map<String, dynamic> map) {
    return VehicleConfigurationCatalogItem(
      code: (map['code'] ?? '').toString().trim(),
      categoryCode: (map['category_code'] ?? '').toString().trim(),
      bodyStyleCode: (map['body_style_code'] as String?)?.trim(),
      labelEn: (map['label_en'] ?? '').toString().trim(),
      labelHi: (map['label_hi'] as String?)?.trim(),
      wheelsW: int.tryParse((map['wheels_w'] ?? '').toString()),
      lengthFt: (map['length_ft'] as String?)?.trim(),
      loadingTonMin: double.tryParse((map['loading_ton_min'] ?? '').toString()),
      loadingTonMax: double.tryParse((map['loading_ton_max'] ?? '').toString()),
      isSpecial: map['is_special'] == true,
    );
  }
}

class VehicleCatalog {
  final List<VehicleCategoryCatalogItem> categories;
  final List<VehicleBodyStyleCatalogItem> bodyStyles;
  final List<VehicleConfigurationCatalogItem> configurations;

  const VehicleCatalog({
    required this.categories,
    required this.bodyStyles,
    required this.configurations,
  });
}

class SupplierLoadRepository {
  final SupplierLoadBackend _backend;
  final String? Function() _currentUserId;
  final int _pageSize;

  const SupplierLoadRepository(
    this._backend,
    this._currentUserId, {
    int pageSize = 20,
  }) : _pageSize = pageSize;

  Future<Result<String>> createLoad(CreateLoadDto dto) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final validationFailure = _validateCreateLoad(dto);
    if (validationFailure != null) {
      return Failure<String>(validationFailure);
    }

    try {
      final loadId = await _backend.createLoad(dto.toRpcParams());
      return Success<String>(loadId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<MaterialCatalogItem>>> searchMaterials(
    String query, {
    int limit = 12,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return const Success<List<MaterialCatalogItem>>(<MaterialCatalogItem>[]);
    }

    try {
      final rows = await _backend.searchMaterials(
        query: normalized,
        limit: limit,
      );
      final materials = rows
          .map(MaterialCatalogItem.fromMap)
          .where((item) => item.code.isNotEmpty && item.nameEn.isNotEmpty)
          .toList(growable: false);
      return Success<List<MaterialCatalogItem>>(materials);
    } catch (error, stackTrace) {
      return Failure<List<MaterialCatalogItem>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<VehicleCatalog>> getVehicleCatalog() async {
    try {
      if (_backend is! SupabaseSupplierLoadBackend) {
        return const Failure<VehicleCatalog>(
          BusinessRuleFailure(message: 'Vehicle catalog backend is unavailable'),
        );
      }
      final payload = await (_backend as SupabaseSupplierLoadBackend).getVehicleCatalog();
      final categoriesRaw = payload['categories'] as List? ?? const <dynamic>[];
      final bodyStylesRaw = payload['body_styles'] as List? ?? const <dynamic>[];
      final configurationsRaw = payload['configurations'] as List? ?? const <dynamic>[];
      final catalog = VehicleCatalog(
        categories: categoriesRaw
            .whereType<Map<String, dynamic>>()
            .map(VehicleCategoryCatalogItem.fromMap)
            .where((item) => item.code.isNotEmpty && item.nameEn.isNotEmpty)
            .toList(growable: false),
        bodyStyles: bodyStylesRaw
            .whereType<Map<String, dynamic>>()
            .map(VehicleBodyStyleCatalogItem.fromMap)
            .where((item) => item.categoryCode.isNotEmpty && item.code.isNotEmpty)
            .toList(growable: false),
        configurations: configurationsRaw
            .whereType<Map<String, dynamic>>()
            .map(VehicleConfigurationCatalogItem.fromMap)
            .where((item) => item.code.isNotEmpty && item.categoryCode.isNotEmpty)
            .toList(growable: false),
      );
      return Success<VehicleCatalog>(catalog);
    } catch (error, stackTrace) {
      return Failure<VehicleCatalog>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> cloneLoadForRepost(RepostLoadRequest request) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    try {
      final loadId = await _backend.cloneLoadForRepost(request.toRpcParams());
      return Success<String>(loadId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<Load>>> getMyLoads(
    LoadFilters filters, {
    int page = 1,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<Load>>(UnauthorizedFailure());
    }

    if (page < 1) {
      return const Failure<List<Load>>(
        ValidationFailure(
          message: 'Page must be at least 1',
          fieldErrors: {'page': 'Invalid page'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchMyLoads(
        supplierId: userId,
        filters: filters,
        page: page,
        pageSize: _pageSize,
      );
      final loads = rows
          .map(LoadListItemDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Success<List<Load>>(loads);
    } catch (error, stackTrace) {
      return Failure<List<Load>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<LoadDetail>> getLoadDetail(String id) async {
    final userId = _currentUserId();
    if (userId == null) {
      AppLogger.warning('getLoadDetail: User ID is null', scope: 'supplier_load_repo');
      return const Failure<LoadDetail>(UnauthorizedFailure());
    }

    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      AppLogger.warning('getLoadDetail: Load ID is empty', scope: 'supplier_load_repo');
      return const Failure<LoadDetail>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    AppLogger.debug('getLoadDetail: loadId=$normalizedId, supplierId=$userId', scope: 'supplier_load_repo');

    try {
      final row = await _backend.fetchLoadDetail(supplierId: userId, loadId: normalizedId);
      if (row == null) {
        AppLogger.warning('getLoadDetail: RPC returned null for loadId=$normalizedId', scope: 'supplier_load_repo');
        return const Failure<LoadDetail>(NotFoundFailure());
      }

      AppLogger.debug('getLoadDetail: Success for loadId=$normalizedId', scope: 'supplier_load_repo');
      return Success<LoadDetail>(LoadDetailDto.fromMap(row).toDomain());
    } catch (error, stackTrace) {
      AppLogger.error('getLoadDetail: Failed for loadId=$normalizedId', scope: 'supplier_load_repo', error: error, stackTrace: stackTrace);
      return Failure<LoadDetail>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<LoadBookingRequest>>> getBookingRequests(String loadId) async {
    AppLogger.info('Starting getBookingRequests', scope: 'supplier_load_repo');

    final userId = _currentUserId();
    if (userId == null) {
      AppLogger.warning('User ID is null', scope: 'supplier_load_repo');
      return const Failure<List<LoadBookingRequest>>(UnauthorizedFailure());
    }

    if (loadId.trim().isEmpty) {
      AppLogger.warning('Load ID is empty', scope: 'supplier_load_repo');
      return const Failure<List<LoadBookingRequest>>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchBookingRequests(
        supplierId: userId,
        loadId: loadId.trim(),
      );
      final bookings = rows
          .map(LoadBookingRequest.fromMap)
          .toList(growable: false);
      AppLogger.info(
        'getBookingRequests success - ${bookings.length} bookings',
        scope: 'supplier_load_repo',
      );
      return Success<List<LoadBookingRequest>>(bookings);
    } catch (error, stackTrace) {
      final failure = _mapError(error, stackTrace);
      AppLogger.warning(
        'getBookingRequests failed',
        scope: 'supplier_load_repo',
        error: failure,
      );
      return Failure<List<LoadBookingRequest>>(failure);
    }
  }

  Future<Result<List<LinkedTrip>>> getLinkedTrips(String loadId) async {
    AppLogger.info('Starting getLinkedTrips', scope: 'supplier_load_repo');

    final userId = _currentUserId();
    if (userId == null) {
      AppLogger.warning('User ID is null', scope: 'supplier_load_repo');
      return const Failure<List<LinkedTrip>>(UnauthorizedFailure());
    }

    if (loadId.trim().isEmpty) {
      AppLogger.warning('Load ID is empty', scope: 'supplier_load_repo');
      return const Failure<List<LinkedTrip>>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchLinkedTrips(
        supplierId: userId,
        loadId: loadId.trim(),
      );
      final trips = rows
          .map(LinkedTrip.fromMap)
          .toList(growable: false);
      AppLogger.info(
        'getLinkedTrips success - ${trips.length} trips',
        scope: 'supplier_load_repo',
      );
      return Success<List<LinkedTrip>>(trips);
    } catch (error, stackTrace) {
      final failure = _mapError(error, stackTrace);
      AppLogger.warning(
        'getLinkedTrips failed',
        scope: 'supplier_load_repo',
        error: failure,
      );
      return Failure<List<LinkedTrip>>(failure);
    }
  }

  Future<Result<void>> cancelLoad(String id) async {
    return _mutateLoad(
      id: id,
      action: (loadId) => _backend.cancelLoad(loadId),
    );
  }

  Future<Result<void>> closeFilledOutsideApp(String id) async {
    return _mutateLoad(
      id: id,
      action: (loadId) => _backend.closeLoadFilledOutsideApp(loadId),
    );
  }

  Future<Result<void>> requestSuperLoad(String id) async {
    return _mutateLoad(
      id: id,
      action: (loadId) => _backend.requestSuperLoad(loadId),
    );
  }

  Future<Result<String>> approveBookingRequest(String bookingId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    if (bookingId.trim().isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Booking id is required',
          fieldErrors: {'booking_id': 'Booking id is required'},
        ),
      );
    }

    try {
      final tripId = await _backend.approveBookingRequest(bookingId.trim());
      return Success<String>(tripId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> rejectBookingRequest(String bookingId, {String? reason}) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    if (bookingId.trim().isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Booking id is required',
          fieldErrors: {'booking_id': 'Booking id is required'},
        ),
      );
    }

    try {
      await _backend.rejectBookingRequest(bookingId.trim(), reason: reason?.trim());
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> _mutateLoad({
    required String id,
    required Future<void> Function(String loadId) action,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    if (id.trim().isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      await action(id.trim());
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  ValidationFailure? _validateCreateLoad(CreateLoadDto dto) {
    if (dto.originLabel.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter an origin location',
        fieldErrors: {'origin_label': 'Origin is required'},
      );
    }

    if (dto.originCity.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter an origin city',
        fieldErrors: {'origin_city': 'Origin city is required'},
      );
    }

    if (dto.destinationLabel.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter a destination location',
        fieldErrors: {'destination_label': 'Destination is required'},
      );
    }

    if (dto.destinationCity.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter a destination city',
        fieldErrors: {'destination_city': 'Destination city is required'},
      );
    }

    if (dto.materialCode.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Select a material from suggestions',
        fieldErrors: {'material_code': 'Material selection is required'},
      );
    }

    if (dto.weightTonnes <= 0) {
      return const ValidationFailure(
        message: 'Enter a valid weight',
        fieldErrors: {'weight_tonnes': 'Weight must be positive'},
      );
    }

    if (dto.trucksNeeded < 1) {
      return const ValidationFailure(
        message: 'Enter how many trucks you need',
        fieldErrors: {'trucks_needed': 'Trucks needed must be at least 1'},
      );
    }

    if (dto.priceAmount <= 0) {
      return const ValidationFailure(
        message: 'Enter a valid rate amount',
        fieldErrors: {'price_amount': 'Price amount must be positive'},
      );
    }

    if (!CreateLoadDto.isSupportedPriceType(dto.priceType)) {
      return const ValidationFailure(
        message: 'Select a valid price type',
        fieldErrors: {'price_type': 'Price type must be fixed or per_ton'},
      );
    }

    if (dto.advancePercentage != null && (dto.advancePercentage! < 0 || dto.advancePercentage! > 100)) {
      return const ValidationFailure(
        message: 'Advance percentage must stay between 0 and 100',
        fieldErrors: {'advance_percentage': 'Advance percentage is invalid'},
      );
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedPickupDate = DateTime(dto.pickupDate.year, dto.pickupDate.month, dto.pickupDate.day);
    if (normalizedPickupDate.isBefore(normalizedToday)) {
      return const ValidationFailure(
        message: 'Pickup date must be today or later',
        fieldErrors: {'pickup_date': 'Pickup date cannot be in the past'},
      );
    }

    return null;
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final message = error.message.trim();
      final normalized = message.toLowerCase();
      if (normalized.contains('daily_post_limit_reached')) {
        return const BusinessRuleFailure(message: 'daily_post_limit_reached');
      }
      if (normalized.contains('cannot be cancelled') ||
          normalized.contains('cannot be closed') ||
          normalized.contains('booking not in submitted state') ||
          normalized.contains('already booked') ||
          normalized.contains('not available') ||
          normalized.contains('not a supplier') ||
          normalized.contains('supplier verification required')) {
        return BusinessRuleFailure(message: message, debugInfo: error.details?.toString());
      }
    }
    return mapSupabaseError(error, stackTrace);
  }

}

final supplierLoadRepositoryProvider = Provider<SupplierLoadRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierLoadRepository(
    SupabaseSupplierLoadBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
