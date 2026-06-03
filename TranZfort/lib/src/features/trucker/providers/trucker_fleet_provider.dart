import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/vehicle_catalog_selector.dart';
import '../../supplier/data/supplier_load_repository.dart';
import '../data/truck_document_upload_service.dart';
import '../data/trucker_fleet_repository.dart';
import '../data/trucker_marketplace_repository.dart';

// T-006: Error codes for localization (UI should map these to AppLocalizations)
class TruckerFleetErrorCodes {
  static const String saveAlreadyInProgress = 'trucker.truck_save_already_in_progress';
  static const String validationFailed = 'trucker.truck_validation_failed';
  static const String truckNotFound = 'trucker.truck_not_found';
}

const List<String> truckerFleetBodyTypes = <String>[
  'open',
  'container',
  'trailer',
  'tanker',
  'refrigerated',
];

const List<int> truckerFleetTyreOptions = <int>[6, 10, 12, 14, 16, 18, 22];

class TruckerFleetState {
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingDocument;
  final List<TruckerFleetTruck> trucks;
  final AppFailure? loadFailure;
  final AppFailure? actionFailure;
  final String truckNumberDraft;
  final String bodyTypeDraft;
  final String vehicleCategoryCodeDraft;
  final String? vehicleBodyStyleCodeDraft;
  final String? configurationCodeDraft;
  final String tyresDraft;
  final String capacityTonnesDraft;
  final String passingTonnesDraft;
  final String? rcDocumentPathDraft;
  final String? editingTruckId;
  final Map<String, String> fieldErrors;

  const TruckerFleetState({
    required this.isLoading,
    required this.isSaving,
    required this.isUploadingDocument,
    required this.trucks,
    required this.loadFailure,
    required this.actionFailure,
    required this.truckNumberDraft,
    required this.bodyTypeDraft,
    required this.vehicleCategoryCodeDraft,
    required this.vehicleBodyStyleCodeDraft,
    required this.configurationCodeDraft,
    required this.tyresDraft,
    required this.capacityTonnesDraft,
    required this.passingTonnesDraft,
    required this.rcDocumentPathDraft,
    required this.editingTruckId,
    required this.fieldErrors,
  });

  factory TruckerFleetState.initial() {
    return TruckerFleetState(
      isLoading: true,
      isSaving: false,
      isUploadingDocument: false,
      trucks: const <TruckerFleetTruck>[],
      loadFailure: null,
      actionFailure: null,
      truckNumberDraft: '',
      bodyTypeDraft: truckerFleetBodyTypes.first,
      vehicleCategoryCodeDraft: '',
      vehicleBodyStyleCodeDraft: null,
      configurationCodeDraft: null,
      tyresDraft: '${truckerFleetTyreOptions[2]}',
      capacityTonnesDraft: '',
      passingTonnesDraft: '',
      rcDocumentPathDraft: null,
      editingTruckId: null,
      fieldErrors: const <String, String>{},
    );
  }

  TruckerFleetState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingDocument,
    List<TruckerFleetTruck>? trucks,
    AppFailure? loadFailure,
    bool? clearLoadFailure,
    AppFailure? actionFailure,
    bool? clearActionFailure,
    String? truckNumberDraft,
    String? bodyTypeDraft,
    String? vehicleCategoryCodeDraft,
    String? vehicleBodyStyleCodeDraft,
    bool? clearVehicleBodyStyleCodeDraft,
    String? configurationCodeDraft,
    bool? clearConfigurationCodeDraft,
    String? tyresDraft,
    String? capacityTonnesDraft,
    String? passingTonnesDraft,
    String? rcDocumentPathDraft,
    bool? clearRcDocumentPathDraft,
    String? editingTruckId,
    bool? clearEditingTruckId,
    Map<String, String>? fieldErrors,
  }) {
    return TruckerFleetState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      trucks: trucks ?? this.trucks,
      loadFailure: clearLoadFailure == true ? null : loadFailure ?? this.loadFailure,
      actionFailure: clearActionFailure == true ? null : actionFailure ?? this.actionFailure,
      truckNumberDraft: truckNumberDraft ?? this.truckNumberDraft,
      bodyTypeDraft: bodyTypeDraft ?? this.bodyTypeDraft,
      vehicleCategoryCodeDraft: vehicleCategoryCodeDraft ?? this.vehicleCategoryCodeDraft,
      vehicleBodyStyleCodeDraft: clearVehicleBodyStyleCodeDraft == true
          ? null
          : vehicleBodyStyleCodeDraft ?? this.vehicleBodyStyleCodeDraft,
      configurationCodeDraft: clearConfigurationCodeDraft == true
          ? null
          : configurationCodeDraft ?? this.configurationCodeDraft,
      tyresDraft: tyresDraft ?? this.tyresDraft,
      capacityTonnesDraft: capacityTonnesDraft ?? this.capacityTonnesDraft,
      passingTonnesDraft: passingTonnesDraft ?? this.passingTonnesDraft,
      rcDocumentPathDraft: clearRcDocumentPathDraft == true ? null : rcDocumentPathDraft ?? this.rcDocumentPathDraft,
      editingTruckId: clearEditingTruckId == true ? null : editingTruckId ?? this.editingTruckId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  bool get isEditing => (editingTruckId ?? '').trim().isNotEmpty;

  TruckerFleetTruck? get editingTruck {
    final editingId = editingTruckId;
    if (editingId == null) {
      return null;
    }
    for (final truck in trucks) {
      if (truck.id == editingId) {
        return truck;
      }
    }
    return null;
  }
}

class TruckerFleetController extends StateNotifier<TruckerFleetState> {
  final TruckerFleetRepository _repository;
  final TruckDocumentUploadService _uploadService;
  final String? Function() _currentUserId;

  TruckerFleetController(
    this._repository,
    this._uploadService,
    this._currentUserId,
  ) : super(TruckerFleetState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearLoadFailure: true);
    final result = await _repository.getMyTrucks();
    result.when(
      success: (trucks) {
        state = state.copyWith(
          isLoading: false,
          trucks: trucks,
          clearLoadFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, loadFailure: failure);
      },
    );
  }

  void startCreate() {
    state = state.copyWith(
      truckNumberDraft: '',
      bodyTypeDraft: truckerFleetBodyTypes.first,
      vehicleCategoryCodeDraft: '',
      clearVehicleBodyStyleCodeDraft: true,
      clearConfigurationCodeDraft: true,
      tyresDraft: '${truckerFleetTyreOptions[2]}',
      capacityTonnesDraft: '',
      passingTonnesDraft: '',
      fieldErrors: const <String, String>{},
      clearRcDocumentPathDraft: true,
      clearEditingTruckId: true,
      clearActionFailure: true,
    );
  }

  void startEdit(TruckerFleetTruck truck) {
    state = state.copyWith(
      truckNumberDraft: truck.truckNumber,
      bodyTypeDraft: truck.bodyType,
      vehicleCategoryCodeDraft: truck.vehicleCategoryCode ?? '',
      vehicleBodyStyleCodeDraft: truck.vehicleBodyStyleCode,
      configurationCodeDraft: truck.configurationCode,
      tyresDraft: '${truck.tyres}',
      capacityTonnesDraft: truck.capacityTonnes.toStringAsFixed(truck.capacityTonnes.truncateToDouble() == truck.capacityTonnes ? 0 : 1),
      passingTonnesDraft: (truck.passingTonnes ?? 0) <= 0
          ? ''
          : (truck.passingTonnes!.truncateToDouble() == truck.passingTonnes
              ? truck.passingTonnes!.toStringAsFixed(0)
              : truck.passingTonnes!.toStringAsFixed(1)),
      rcDocumentPathDraft: truck.rcDocumentPath,
      editingTruckId: truck.id,
      fieldErrors: const <String, String>{},
      clearActionFailure: true,
    );
  }

  void updateTruckNumber(String value) {
    state = state.copyWith(
      truckNumberDraft: value,
      fieldErrors: _withoutErrors(const <String>['truck_number']),
      clearActionFailure: true,
    );
  }

  void updateBodyType(String? value) {
    if (value == null) {
      return;
    }
    state = state.copyWith(bodyTypeDraft: value, clearActionFailure: true);
  }

  void applyVehicleCatalogSelection({
    required VehicleRequirementSelection selection,
    required VehicleCatalog catalog,
  }) {
    final selectedConfig = selection.configurationCodes.isEmpty
        ? null
        : catalog.configurations.cast<VehicleConfigurationCatalogItem?>().firstWhere(
              (item) => item?.code == selection.configurationCodes.first,
              orElse: () => null,
            );
    final selectedBodyStyleCode = selection.bodyStyleCodes.isEmpty ? null : selection.bodyStyleCodes.first;
    final selectedBodyStyleLabel = selectedBodyStyleCode == null
        ? null
        : catalog.bodyStyles.cast<VehicleBodyStyleCatalogItem?>().firstWhere(
              (item) => item?.code == selectedBodyStyleCode,
              orElse: () => null,
            )?.nameEn;
    state = state.copyWith(
      vehicleCategoryCodeDraft: selection.categoryCode,
      vehicleBodyStyleCodeDraft: selectedBodyStyleCode,
      configurationCodeDraft: selectedConfig?.code,
      bodyTypeDraft: _mapCatalogBodyStyleToLegacyBodyType(selectedBodyStyleLabel),
      tyresDraft: selectedConfig?.wheelsW?.toString() ?? state.tyresDraft,
      passingTonnesDraft: selectedConfig?.loadingTonMax?.toStringAsFixed(
            selectedConfig.loadingTonMax!.truncateToDouble() == selectedConfig.loadingTonMax ? 0 : 1,
          ) ??
          state.passingTonnesDraft,
      clearActionFailure: true,
    );
  }

  void updateTyres(String? value) {
    if (value == null) {
      return;
    }
    state = state.copyWith(
      tyresDraft: value,
      fieldErrors: _withoutErrors(const <String>['tyres']),
      clearActionFailure: true,
    );
  }

  void updateCapacityTonnes(String value) {
    state = state.copyWith(
      capacityTonnesDraft: value,
      fieldErrors: _withoutErrors(const <String>['capacity_tonnes']),
      clearActionFailure: true,
    );
  }

  Future<Result<String?>> uploadRcDocument(ImageSource source) async {
    final ownerId = _currentUserId();
    final targetTruckId = state.editingTruckId ?? 'draft-truck';
    if (ownerId == null) {
      return const Failure<String?>(UnauthorizedFailure());
    }

    state = state.copyWith(isUploadingDocument: true, clearActionFailure: true);
    final result = await _uploadService.pickCompressAndUploadRcDocument(
      ownerId: ownerId,
      truckId: targetTruckId,
      source: source,
    );
    result.when(
      success: (path) {
        state = state.copyWith(
          isUploadingDocument: false,
          rcDocumentPathDraft: path ?? state.rcDocumentPathDraft,
          fieldErrors: _withoutErrors(const <String>['rc_document_path']),
          clearActionFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isUploadingDocument: false,
          actionFailure: failure,
        );
      },
    );
    return result;
  }

  Future<Result<void>> archiveTruck(String truckId) async {
    final result = await _repository.archiveTruck(truckId);
    result.when(
      success: (_) => load(),
      failure: (failure) => state = state.copyWith(actionFailure: failure),
    );
    return result;
  }

  Future<Result<void>> reactivateTruck(String truckId) async {
    final result = await _repository.reactivateTruck(truckId);
    result.when(
      success: (_) => load(),
      failure: (failure) => state = state.copyWith(actionFailure: failure),
    );
    return result;
  }

  Future<Result<String?>> getRcDocumentPreviewUrl(TruckerFleetTruck truck) async {
    return _repository.getRcDocumentPreviewUrl(truck.rcDocumentPath);
  }

  Future<Result<void>> save([AppLocalizations? l10n]) async {
    if (state.isSaving) {
      return const Failure<void>(
        BusinessRuleFailure(message: TruckerFleetErrorCodes.saveAlreadyInProgress),
      );
    }

    final fieldErrors = _validate(l10n);
    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: fieldErrors, clearActionFailure: true);
      return Failure<void>(
        ValidationFailure(
          message: TruckerFleetErrorCodes.validationFailed,
          fieldErrors: fieldErrors,
        ),
      );
    }

    state = state.copyWith(isSaving: true, clearActionFailure: true, fieldErrors: const <String, String>{});

    final truckNumber = state.truckNumberDraft.trim().toUpperCase();
    final bodyType = state.bodyTypeDraft.trim();
    final tyres = int.parse(state.tyresDraft.trim());
    final capacityTonnes = double.parse(state.capacityTonnesDraft.trim());
    final passingTonnes = double.tryParse(state.passingTonnesDraft.trim());
    final rcDocumentPath = state.rcDocumentPathDraft!.trim();

    final Result<void> result;
    if (state.isEditing) {
      final existingTruck = state.editingTruck;
      if (existingTruck == null) {
        result = const Failure<void>(
          NotFoundFailure(message: TruckerFleetErrorCodes.truckNotFound),
        );
      } else {
        result = await _repository.updateTruck(
          existingTruck: existingTruck,
          truckNumber: truckNumber,
          bodyType: bodyType,
          vehicleCategoryCode: state.vehicleCategoryCodeDraft.trim().isEmpty
              ? null
              : state.vehicleCategoryCodeDraft.trim(),
          vehicleBodyStyleCode: state.vehicleBodyStyleCodeDraft,
          configurationCode: state.configurationCodeDraft,
          tyres: tyres,
          capacityTonnes: capacityTonnes,
          passingTonnes: passingTonnes,
          rcDocumentPath: rcDocumentPath,
        );
      }
    } else {
      final createResult = await _repository.createTruck(
        truckNumber: truckNumber,
        bodyType: bodyType,
        vehicleCategoryCode: state.vehicleCategoryCodeDraft.trim().isEmpty
            ? null
            : state.vehicleCategoryCodeDraft.trim(),
        vehicleBodyStyleCode: state.vehicleBodyStyleCodeDraft,
        configurationCode: state.configurationCodeDraft,
        tyres: tyres,
        capacityTonnes: capacityTonnes,
        passingTonnes: passingTonnes,
        rcDocumentPath: rcDocumentPath,
      );
      result = createResult.when(
        success: (_) => const Success<void>(null),
        failure: (failure) => Failure<void>(failure),
      );
    }

    result.when(
      success: (_) async {
        await load();
        state = state.copyWith(
          isSaving: false,
          truckNumberDraft: '',
          bodyTypeDraft: truckerFleetBodyTypes.first,
          vehicleCategoryCodeDraft: '',
          clearVehicleBodyStyleCodeDraft: true,
          clearConfigurationCodeDraft: true,
          tyresDraft: '${truckerFleetTyreOptions[2]}',
          capacityTonnesDraft: '',
          passingTonnesDraft: '',
          clearRcDocumentPathDraft: true,
          clearEditingTruckId: true,
          fieldErrors: const <String, String>{},
          clearActionFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(isSaving: false, actionFailure: failure);
      },
    );

    return result;
  }

  Map<String, String> _validate(AppLocalizations? l10n) {
    final errors = <String, String>{};
    if (state.truckNumberDraft.trim().length < 6) {
      errors['truck_number'] = l10n?.truckerFleetValidationTruckNumber ?? '';
    }
    final tyres = int.tryParse(state.tyresDraft.trim());
    if (tyres == null || !truckerFleetTyreOptions.contains(tyres)) {
      errors['tyres'] = l10n?.truckerFleetValidationTyreCount ?? '';
    }
    final capacityTonnes = double.tryParse(state.capacityTonnesDraft.trim());
    if (capacityTonnes == null || capacityTonnes <= 0 || capacityTonnes > 100) {
      errors['capacity_tonnes'] = l10n?.truckerFleetValidationCapacityTonnes ?? '';
    }
    if ((state.rcDocumentPathDraft ?? '').trim().isEmpty) {
      errors['rc_document_path'] = l10n?.truckerFleetValidationRcDocument ?? '';
    }
    return errors;
  }

  Map<String, String> _withoutErrors(List<String> keys) {
    final next = Map<String, String>.from(state.fieldErrors);
    for (final key in keys) {
      next.remove(key);
    }
    return next;
  }

  String _mapCatalogBodyStyleToLegacyBodyType(String? label) {
    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized.contains('container')) return 'container';
    if (normalized.contains('trailer')) return 'trailer';
    if (normalized.contains('tanker')) return 'tanker';
    if (normalized.contains('reefer') || normalized.contains('refrigerated')) return 'refrigerated';
    return 'open';
  }
}

final truckerFleetProvider = StateNotifierProvider.autoDispose<TruckerFleetController, TruckerFleetState>((ref) {
  final repository = ref.watch(truckerFleetRepositoryProvider);
  final uploadService = ref.watch(truckDocumentUploadServiceProvider);
  return TruckerFleetController(
    repository,
    uploadService,
    () => ref.watch(supabaseClientProvider)?.auth.currentUser?.id,
  );
});

final truckerFleetVehicleCatalogProvider = FutureProvider.autoDispose<VehicleCatalog>((ref) async {
  final repository = ref.watch(truckerMarketplaceRepositoryProvider);
  final result = await repository.getVehicleCatalog();
  return result.when(
    success: (catalog) => catalog,
    failure: (failure) => throw failure,
  );
});
