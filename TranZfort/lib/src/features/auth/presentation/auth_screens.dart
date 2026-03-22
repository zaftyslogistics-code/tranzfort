import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../features/notifications/data/push_runtime_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../data/auth_repository.dart';

part 'auth_screen_sections.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final ContextualTtsService _contextualTtsService;
  bool _started = false;
  bool _showFirstRunSetup = false;
  bool _isContinuing = false;
  PushPermissionSnapshot _pushSnapshot = const PushPermissionSnapshot(PushPermissionStatus.unavailable);
  bool _voiceEnabled = true;
  bool _locationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.denied;

  AppLocalizations get l10n => AppLocalizations.of(context);

  bool get _locationReady =>
      _locationServiceEnabled &&
      _locationPermission != LocationPermission.denied &&
      _locationPermission != LocationPermission.deniedForever;

  @override
  void initState() {
    super.initState();
    _contextualTtsService = ref.read(contextualTtsServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) {
      return;
    }
    _started = true;

    final preferences = await SharedPreferences.getInstance();
    final hasSeenSplash = preferences.getBool('has_seen_splash') ?? false;

    if (!hasSeenSplash) {
      await _contextualTtsService.speakSummary(
            languageCode: 'hi',
            message: l10n.authTtsSplashWelcome,
          );
      await preferences.setBool('has_seen_splash', true);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    await _routeAfterSplash();
  }

  Future<void> _loadFirstRunSetupState() async {
    final pushSnapshot = await ref.read(pushRuntimeServiceProvider).fetchPermissionSnapshot();
    final preferences = await SharedPreferences.getInstance();
    final voiceEnabled = !(preferences.getBool('tts_muted') ?? false);
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    final locationPermission = await Geolocator.checkPermission();
    if (!mounted) {
      return;
    }
    setState(() {
      _pushSnapshot = pushSnapshot;
      _voiceEnabled = voiceEnabled;
      _locationServiceEnabled = locationServiceEnabled;
      _locationPermission = locationPermission;
    });
  }

  Future<void> _routeAfterSplash() async {
    if (_showFirstRunSetup) {
      return;
    }

    bool authRefreshFailed = false;
    try {
      await ref.read(authStateProvider.future).timeout(const Duration(seconds: 6));
    } catch (_) {
      authRefreshFailed = true;
    }

    if (!mounted) {
      return;
    }

    if (authRefreshFailed) {
      AppSnackbar.show(
        context: context,
        message: l10n.authSessionRefreshFailureMessage,
        variant: AppSnackbarVariant.error,
      );
    }

    final authState = ref.read(currentAuthStateProvider);
    final profileCompleteness = ref.read(profileCompletenessProvider);

    if (!authState.hasSession) {
      context.go(AppRoutes.authPath);
      return;
    }

    if (authState.isDeactivated) {
      context.go(AppRoutes.deleteAccountPath);
      return;
    }

    if (authState.isBanned) {
      context.go(AppRoutes.bannedPath);
      return;
    }

    if (!profileCompleteness.isComplete) {
      context.go(AppRoutes.onboardingPath);
      return;
    }

    if (authState.role == AppUserRole.supplier) {
      context.go(AppRoutes.supplierDashboardPath);
    } else {
      context.go(AppRoutes.truckerDashboardPath);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final ok = await ref.read(pushRuntimeServiceProvider).requestPermission();
    if (!mounted) {
      return;
    }
    if (!ok) {
      AppSnackbar.show(
        context: context,
        message: l10n.authNotificationPermissionFailureMessage,
        variant: AppSnackbarVariant.error,
      );
    }
    await _loadFirstRunSetupState();
  }

  Future<void> _enableVoiceGuidance() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('tts_muted', false);
    await _contextualTtsService.speakSummary(
      languageCode: 'hi',
      message: l10n.authTtsVoiceGuidanceEnabled,
    );
    if (!mounted) {
      return;
    }
    setState(() => _voiceEnabled = true);
  }

  Future<void> _requestLocationAccess() async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      await Geolocator.openLocationSettings();
      await _loadFirstRunSetupState();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    await _loadFirstRunSetupState();
  }

  Future<void> _continueFromFirstRunSetup() async {
    if (_isContinuing) {
      return;
    }
    setState(() => _isContinuing = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('has_seen_splash', true);
    if (!mounted) {
      return;
    }
    setState(() {
      _showFirstRunSetup = false;
      _isContinuing = false;
    });
    await _routeAfterSplash();
  }

  @override
  void dispose() {
    unawaited(_contextualTtsService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    if (_showFirstRunSetup) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/images/splash-screen-logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                if (!appConfig.isSupabaseConfigured) ...[
                  WarningBlock(
                    title: l10n.authConfigIncompleteTitle,
                    message: l10n.authConfigIncompleteMessage,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.splashSetupTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.splashSetupSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _SetupActionCard(
                  title: l10n.settingsPushNotificationsTitle,
                  status: _pushSnapshot.label,
                  actionLabel: l10n.settingsPushRequestPermission,
                  onPressed: _requestNotificationPermission,
                ),
                const SizedBox(height: 16),
                _SetupActionCard(
                  title: l10n.shellTooltipVoiceAssistance,
                  status: _voiceEnabled ? l10n.commonHearSummary : l10n.commonVoiceMuted,
                  actionLabel: l10n.splashSetupEnableVoiceAction,
                  onPressed: _enableVoiceGuidance,
                ),
                const SizedBox(height: 16),
                _SetupActionCard(
                  title: l10n.verificationLocationTitle,
                  status: _locationReady ? l10n.verificationLocationCapturedStatus : l10n.verificationLocationRequiredStatus,
                  actionLabel: _locationServiceEnabled
                      ? l10n.verificationCaptureLocationAction
                      : l10n.splashSetupOpenLocationSettingsAction,
                  onPressed: _requestLocationAccess,
                ),
                const Spacer(),
                PrimaryButton(
                  label: l10n.onboardingContinue,
                  onPressed: _continueFromFirstRunSetup,
                  isLoading: _isContinuing,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/splash-screen-logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
 }
