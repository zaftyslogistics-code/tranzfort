import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'verification_draft_secure_storage.dart';
import 'verification_provider.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../trucker/data/truck_document_upload_service.dart';
import '../../trucker/data/trucker_fleet_repository.dart';
import '../data/verification_document_upload_service.dart';
import '../data/verification_location_service.dart';
import '../data/verification_repository.dart';
import 'verification_wizard_upload_helper.dart';
import 'verification_wizard_validation_helper.dart';

import 'verification_wizard_state.dart';

part 'verification_wizard_provider.navigation.dart';
part 'verification_wizard_provider.identity.dart';
part 'verification_wizard_provider.truck.dart';
part 'verification_wizard_provider.business.dart';
part 'verification_wizard_provider.location.dart';
part 'verification_wizard_provider.submit.dart';
part 'verification_wizard_provider.upload_handlers.dart';
part 'verification_wizard_field_errors.dart';

class VerificationWizardController extends StateNotifier<VerificationWizardState> {
  final VerificationRepository _repository;
  final VerificationDocumentUploadService _uploadService;
  final TruckDocumentUploadService _truckUploadService;
  final VerificationLocationService _locationService;
  final TruckerFleetRepository? _fleetRepository;
  final String? _currentUserId;
  final AppUserRole _role;
  final VerificationDraftSecureStorage _secureStorage;
  final VerificationDetail? _initialDetail;
  late final VerificationWizardUploadHelper _uploadHelper;
  late final VerificationWizardValidationHelper _validationHelper;

  VerificationWizardController({
    required VerificationRepository repository,
    required VerificationDocumentUploadService uploadService,
    required TruckDocumentUploadService truckUploadService,
    required VerificationLocationService locationService,
    required AppUserRole role,
    TruckerFleetRepository? fleetRepository,
    String? currentUserId,
    VerificationDraftSecureStorage? secureStorage,
    VerificationDetail? initialDetail,
  })  : _repository = repository,
        _uploadService = uploadService,
        _truckUploadService = truckUploadService,
        _locationService = locationService,
        _fleetRepository = fleetRepository,
        _currentUserId = currentUserId,
        _role = role,
        _secureStorage = secureStorage ?? VerificationDraftSecureStorage(),
        _initialDetail = initialDetail,
        super(VerificationWizardState.initial(role)) {
    _uploadHelper = VerificationWizardUploadHelper(
      repository: _repository,
      uploadService: _uploadService,
      truckUploadService: _truckUploadService,
      currentUserId: _currentUserId,
    );
    _validationHelper = VerificationWizardValidationHelper(role: _role);
    _verificationLoadExistingData();
  }

  void _setState(VerificationWizardState newState, {bool persistDraft = true}) {
    state = newState;
    if (!persistDraft) {
      return;
    }
    unawaited(_verificationPersistDraft(state.draft));
  }

}

final verificationWizardProvider = StateNotifierProvider.autoDispose<
    VerificationWizardController, VerificationWizardState>((ref) {
  final role = ref.watch(currentAuthStateProvider).role;
  final repository = ref.watch(verificationRepositoryProvider);
  final uploadService = ref.watch(verificationDocumentUploadServiceProvider);
  final truckUploadService = ref.watch(truckDocumentUploadServiceProvider);
  final locationService = ref.watch(verificationLocationServiceProvider);
  final client = ref.watch(supabaseClientProvider);
  final verificationDetail = ref.read(verificationProvider).detail;

  TruckerFleetRepository? fleetRepo;
  if (role == AppUserRole.trucker) {
    fleetRepo = TruckerFleetRepository(
      SupabaseTruckerFleetBackend(client),
      () => client?.auth.currentUser?.id,
    );
  }

  return VerificationWizardController(
    repository: repository,
    uploadService: uploadService,
    truckUploadService: truckUploadService,
    locationService: locationService,
    role: role,
    fleetRepository: fleetRepo,
    currentUserId: client?.auth.currentUser?.id,
    initialDetail: verificationDetail,
  );
});
