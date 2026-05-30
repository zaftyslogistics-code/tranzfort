import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/tts_utterance_utils.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../data/auth_repository_profile_ops.dart';
import '../providers/auth_providers.dart';
import 'onboarding_ui_widgets.dart';
import '../../verification/data/verification_location_service.dart' as location_service;
import '../../supplier/data/supplier_location_services.dart';

String _onboardingProfileSaveFailureMessage(AppLocalizations l10n, AppFailure? failure) {
  if (failure is BusinessRuleFailure &&
      failure.message == OnboardingController.termsAcceptanceRequiredCode) {
    return l10n.onboardingTermsAcceptance;
  }
  if (failure is ValidationFailure &&
      failure.message == AuthProfileErrorCodes.roleRequired) {
    return l10n.onboardingRoleSaveFailure;
  }
  if (failure is ValidationFailure &&
      failure.message == AuthProfileErrorCodes.nameTooShort) {
    return l10n.onboardingProfileSaveFailure;
  }
  if (failure is ValidationFailure &&
      failure.message == AuthProfileErrorCodes.mobileRequired) {
    return l10n.onboardingProfileSaveFailure;
  }
  if (failure is ConflictFailure) {
    return failure.message;
  }
  if (failure is ServerFailure && failure.message.trim().isNotEmpty) {
    return failure.message;
  }
  return l10n.onboardingProfileSaveFailure;
}

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _initialized = false;
  bool _termsAccepted = false;
  String? _city;
  String? _state;
  double? _latitude;
  double? _longitude;
  bool _isCapturingLocation = false;
  
  // Track initial values for unsaved changes detection
  String? _initialName;
  String? _initialMobile;
  bool _initialTermsAccepted = false;
  String? _initialCity;
  String? _initialState;
  double? _initialLatitude;
  double? _initialLongitude;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final profileAsync = ref.read(currentProfileProvider);
    if (profileAsync.isLoading) {
      return;
    }

    final profile = profileAsync.valueOrNull;
    _nameController.text = profile?.fullName ?? '';
    _mobileController.text = profile?.mobile ?? '';
    
    // Store initial values
    _initialName = profile?.fullName ?? '';
    _initialMobile = profile?.mobile ?? '';
    _initialTermsAccepted = false;
    _initialCity = null;
    _initialState = null;
    _initialLatitude = null;
    _initialLongitude = null;
    
    _initialized = true;
  }

  bool _hasUnsavedChanges() {
    return _nameController.text != (_initialName ?? '') ||
        _mobileController.text != (_initialMobile ?? '') ||
        _termsAccepted != _initialTermsAccepted ||
        _city != _initialCity ||
        _state != _initialState ||
        _latitude != _initialLatitude ||
        _longitude != _initialLongitude;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.onboardingDiscardChangesTitle),
        content: Text(l10n.onboardingDiscardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDiscardAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final updateResult = await ref.read(onboardingControllerProvider.notifier).updateProfile(
          fullName: _nameController.text,
          mobile: _mobileController.text,
          termsAccepted: _termsAccepted,
          city: _city,
          regionState: _state,
          latitude: _latitude,
          longitude: _longitude,
        );

    if (!mounted) {
      return;
    }

    if (updateResult.isFailure) {
      final failure = updateResult.failureOrNull;
      AppSnackbar.show(
        context: context,
        message: _onboardingProfileSaveFailureMessage(l10n, failure),
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final refreshedAuthState = await ref.read(authStateProvider.future);
    if (!mounted) {
      return;
    }

    if (refreshedAuthState.role == AppUserRole.supplier) {
      context.go(AppRoutes.supplierDashboardPath);
    } else {
      context.go(AppRoutes.truckerDashboardPath);
    }
  }

  Future<void> _handleCaptureLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      final locationService = ref.read(location_service.verificationLocationServiceProvider);
      
      // Check if location service is enabled first
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) {
        if (!mounted) return;
        _showLocationServiceDisabledDialog();
        return;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showPermissionDeniedForeverDialog();
        return;
      }

      final locationData = await locationService.captureSupplierVerificationLocation();
      if (!mounted) return;

      if (locationData != null) {
        setState(() {
          _city = locationData.city;
          _state = locationData.state;
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
        });
      } else {
        AppSnackbar.show(
          context: context,
          message: 'Failed to capture location. Please try again or add manually.',
          variant: AppSnackbarVariant.error,
        );
      }
    } on location_service.LocationServiceDisabledException catch (_) {
      if (!mounted) return;
      _showLocationServiceDisabledDialog();
    } on location_service.LocationPermissionDeniedException catch (_) {
      if (!mounted) return;
      _showPermissionDeniedDialog();
    } on location_service.LocationPermissionDeniedForeverException catch (_) {
      if (!mounted) return;
      _showPermissionDeniedForeverDialog();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        message: 'Failed to capture location. Please try again or add manually.',
        variant: AppSnackbarVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingLocation = false);
      }
    }
  }

  void _showLocationServiceDisabledDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationServicesDisabled),
        content: Text(l10n.locationEnableServicesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final opened = await Geolocator.openLocationSettings();
              if (opened && mounted) {
                // Retry after user enables GPS
                await Future.delayed(const Duration(seconds: 2));
                _handleCaptureLocation();
              }
            },
            child: Text(l10n.locationEnableGps),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationPermissionRequired),
        content: Text(l10n.locationGrantPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            // ignore: use_build_context_synchronously
            onPressed: () async {
              final snackbarContext = context;
              Navigator.pop(context);
              final granted = await Geolocator.requestPermission();
              if (granted == LocationPermission.whileInUse || granted == LocationPermission.always) {
                if (mounted) {
                  _handleCaptureLocation();
                }
              } else if (granted == LocationPermission.denied) {
                if (!mounted) return;
                AppSnackbar.show(
                  // ignore: use_build_context_synchronously
                  context: snackbarContext,
                  message: 'Permission denied. Please try again.',
                  variant: AppSnackbarVariant.error,
                );
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationPermissionDenied),
        content: Text(l10n.locationPermissionDeniedForeverMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: Text(l10n.locationOpenSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManualLocation() async {
    final l10n = AppLocalizations.of(context);
    final searchController = TextEditingController();
    List<PlaceSuggestion> suggestions = [];
    bool isSearching = false;

    final result = await showDialog<PlaceSuggestion>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.searchYourLocation),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search city',
                    hintText: 'e.g., Mumbai',
                    suffixIcon: isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  autofocus: true,
                  onChanged: (value) async {
                    if (value.length < 2) {
                      setDialogState(() => suggestions = []);
                      return;
                    }
                    setDialogState(() => isSearching = true);
                    try {
                      final locationService = ref.read(supplierLocationServiceProvider);
                      final results = await locationService.searchCities(value);
                      if (mounted) {
                        setDialogState(() {
                          suggestions = results;
                          isSearching = false;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setDialogState(() => isSearching = false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (suggestions.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return ListTile(
                          title: Text(suggestion.label),
                          subtitle: suggestion.source == 'google_places'
                              ? Text(l10n.commonSuggestionSourceGooglePlaces)
                              : Text(l10n.commonSuggestionSourceOffline),
                          onTap: () {
                            Navigator.pop(context, suggestion);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    searchController.dispose();

    if (result != null) {
      // Resolve the suggestion to get coordinates if needed
      final locationService = ref.read(supplierLocationServiceProvider);
      final resolved = await locationService.resolveSuggestion(result);
      
      if (mounted) {
        setState(() {
          _city = resolved.city;
          _state = resolved.state;
          _latitude = resolved.lat;
          _longitude = resolved.lng;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final onboardingState = ref.watch(onboardingControllerProvider);
    final ttsL10n = TtsLocalizations.of(context);
    final ttsSummary = limitTtsSentences(ttsL10n.ttsOnboardingCompleteProfile);

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges()) {
          final navigator = Navigator.of(context);
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Reset to initial values when discarding changes
            if (mounted) {
              setState(() {
                _nameController.text = _initialName ?? '';
                _mobileController.text = _initialMobile ?? '';
                _termsAccepted = _initialTermsAccepted;
                _city = _initialCity;
                _state = _initialState;
                _latitude = _initialLatitude;
                _longitude = _initialLongitude;
              });
              // Navigate back
              navigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.onboardingCompleteProfileTitle),
          actions: const [
            TtsActionButton(),
            LanguageToggleAction(),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.onboardingCompleteProfileHeading,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.onboardingCompleteProfileSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OnboardingFieldSection(
                      label: l10n.onboardingFullNameLabel,
                      ttsMessage: ttsL10n.ttsOnboardingProfileFullName,
                      child: AppTextField(
                        controller: _nameController,
                        hintText: l10n.onboardingFullNameHint,
                        enlarged: true,
                        scrollPadding: const EdgeInsets.only(bottom: 160),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OnboardingFieldSection(
                      label: l10n.onboardingMobileLabel,
                      ttsMessage: ttsL10n.ttsOnboardingProfileMobile,
                      child: AppTextField(
                        controller: _mobileController,
                        hintText: profile?.mobile?.isNotEmpty == true ? profile!.mobile : '+91XXXXXXXXXX',
                        keyboardType: TextInputType.phone,
                        enlarged: true,
                        scrollPadding: const EdgeInsets.only(bottom: 160),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OnboardingFieldSection(
                      label: l10n.locationLabel,
                      ttsMessage: ttsL10n.ttsOnboardingProfileLocation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_city != null && _state != null)
                            Text(
                              '$_city, $_state',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                          else
                            Text(
                              l10n.locationNotAdded,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlineButton(
                                  label: _isCapturingLocation ? l10n.locationCapturing : l10n.useCurrentLocation,
                                  onPressed: _isCapturingLocation ? null : _handleCaptureLocation,
                                  height: 48,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlineButton(
                                  label: l10n.addManually,
                                  onPressed: _isCapturingLocation ? null : _handleManualLocation,
                                  height: 48,
                                ),
                              ),
                            ],
                          ),
                          if (_city != null && _state != null)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextActionButton(
                                  label: l10n.clearLocation,
                                  height: 40,
                                  onPressed: _isCapturingLocation
                                      ? null
                                      : () {
                                          setState(() {
                                            _city = null;
                                            _state = null;
                                            _latitude = null;
                                            _longitude = null;
                                          });
                                        },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _termsAccepted,
                            onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                            child: Text(
                              l10n.onboardingTermsAcceptance,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GradientButton(
                      label: l10n.onboardingSaveAndContinue,
                      onPressed: _submit,
                      isLoading: onboardingState.isSubmitting,
                    ),
                  ],
                ),
              ),
              TtsScreenSummaryEffect(
                summary: ttsSummary,
                screenKey: AppRoutes.onboardingProfilePath,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
