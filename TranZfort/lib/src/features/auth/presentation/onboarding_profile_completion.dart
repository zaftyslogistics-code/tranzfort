import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../providers/auth_providers.dart';
import '../../verification/data/verification_location_service.dart' as location_service;
import '../../supplier/data/supplier_location_services.dart';

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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved profile changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
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
          state: _state,
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
        message: failure is BusinessRuleFailure && failure.message == OnboardingController.termsAcceptanceRequiredCode
            ? l10n.onboardingTermsAcceptance
            : l10n.onboardingProfileSaveFailure,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services (GPS) to capture your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Enable GPS'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Please grant location permission to capture your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final granted = await Geolocator.requestPermission();
              if (granted == LocationPermission.whileInUse || granted == LocationPermission.always) {
                if (mounted) {
                  _handleCaptureLocation();
                }
              } else if (granted == LocationPermission.denied) {
                if (mounted) {
                  AppSnackbar.show(
                    context: context,
                    message: 'Permission denied. Please try again.',
                    variant: AppSnackbarVariant.error,
                  );
                }
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('Location permission was permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManualLocation() async {
    final l10n = AppLocalizations.of(context);
    final searchController = TextEditingController();
    PlaceSuggestion? selectedSuggestion;
    List<PlaceSuggestion> suggestions = [];
    bool isSearching = false;

    final result = await showDialog<PlaceSuggestion>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search your location'),
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
                            setDialogState(() => selectedSuggestion = suggestion);
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
    final ttsSummary = '${l10n.onboardingCompleteProfileTitle}. ${l10n.onboardingCompleteProfileHeading}. ${l10n.onboardingCompleteProfileSubtitle}';

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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text(
                  l10n.onboardingCompleteProfileHeading,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.onboardingCompleteProfileSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  label: l10n.onboardingFullNameLabel,
                  hintText: l10n.onboardingFullNameHint,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _mobileController,
                  label: l10n.onboardingMobileLabel,
                  hintText: profile?.mobile?.isNotEmpty == true ? profile!.mobile : '+91XXXXXXXXXX',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Location capture section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_city != null && _state != null)
                        Text(
                          '$_city, $_state',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                        )
                      else
                        Text(
                          'No location added',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isCapturingLocation ? null : _handleCaptureLocation,
                              icon: const Icon(Icons.location_on, size: 18),
                              label: Text(_isCapturingLocation ? 'Capturing...' : 'Use current location'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isCapturingLocation ? null : _handleManualLocation,
                              icon: const Icon(Icons.edit_location, size: 18),
                              label: const Text('Add manually'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_city != null && _state != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isCapturingLocation ? null : () {
                            setState(() {
                              _city = null;
                              _state = null;
                              _latitude = null;
                              _longitude = null;
                            });
                          },
                          child: const Text('Clear location', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                        child: Text(l10n.onboardingTermsAcceptance),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PrimaryButton(
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
