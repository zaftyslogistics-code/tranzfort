part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Location Capture
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardLocation on VerificationWizardController {
  Future<LocationCaptureResult> captureLocation() async {
    return _verificationCaptureLocation();
  }

  Future<void> setManualLocation({
    required String city,
    String? region,
    required double latitude,
    required double longitude,
  }) async {
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        location: WizardLocation(
          city: city,
          state: region,
          latitude: latitude,
          longitude: longitude,
          source: 'manual',
        ),
      ),
    ));
  }

  void clearLocation() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(location: null),
    ));
  }

  Future<LocationCaptureResult> _verificationCaptureLocation() async {
    _setState(
      state.copyWith(isCapturingLocation: true, clearError: true),
      persistDraft: false,
    );

    try {
      final location = await _locationService.captureSupplierVerificationLocation();

      if (location == null) {
        _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
        return LocationCaptureResult.error(LocationCaptureError.unknown);
      }

      _setState(state.copyWith(
        isCapturingLocation: false,
        draft: state.draft.copyWith(
          location: WizardLocation(
            city: location.city,
            state: location.state,
            latitude: location.latitude,
            longitude: location.longitude,
            source: 'gps',
          ),
        ),
      ));

      return LocationCaptureResult.success(location);
    } on LocationServiceDisabledException {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.serviceDisabled);
    } on LocationPermissionDeniedException {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.permissionDenied);
    } on LocationPermissionDeniedForeverException {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.permissionDeniedForever);
    } catch (_) {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.unknown);
    }
  }
}
