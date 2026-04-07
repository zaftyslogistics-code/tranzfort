import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_locale_providers.dart';
import '../../core/providers/app_state_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'feedback_components.dart';

/// Language toggle action button for app bar.
/// 
/// Shows a text-based icon:
/// - 'A' when current language is English
/// - 'अ' when current language is Hindi
/// 
/// Tapping toggles between English and Hindi immediately.
class LanguageToggleAction extends ConsumerWidget {
  const LanguageToggleAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeState = ref.watch(appLocaleProvider);
    final localeController = ref.read(appLocaleProvider.notifier);
    final currentLang = localeState.locale.languageCode;

    return IconButton(
      onPressed: () async {
        final newLang = currentLang == 'hi' ? 'en' : 'hi';
        final result = await localeController.setLanguage(newLang);

        if (!context.mounted) return;

        AppSnackbar.show(
          context: context,
          message: result.isSuccess
              ? (newLang == 'hi'
                  ? l10n.settingsLanguageSavedHindi
                  : l10n.settingsLanguageSavedEnglish)
              : l10n.settingsLanguageSaveFailed,
          variant: result.isSuccess
              ? AppSnackbarVariant.success
              : AppSnackbarVariant.error,
        );

        if (result.isSuccess) {
          ref.invalidate(authStateProvider);
        }
      },
      icon: Text(
        currentLang == 'hi' ? 'A' : 'अ',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      tooltip: l10n.appBarLanguageToggleTooltip,
    );
  }
}
