import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/tts_utterance_utils.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../providers/auth_providers.dart';

part 'auth_screen_sections.dart';
part 'auth_screens_email_password.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final ContextualTtsService _contextualTtsService;
  bool _started = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

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
            languageCode: ui.PlatformDispatcher.instance.locale.languageCode,
            message: l10n.authTtsSplashWelcome,
          );
      await preferences.setBool('has_seen_splash', true);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    await _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {

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

  @override
  void dispose() {
    unawaited(_contextualTtsService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
