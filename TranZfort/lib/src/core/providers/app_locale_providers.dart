import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_repository.dart';
import '../error/app_failure.dart';
import '../error/result.dart';
import 'app_state_providers.dart';

const _appLanguagePreferenceKey = 'app_language';

/// Default UI language for new installs (India / low-literacy launch).
const String kDefaultAppLanguageCode = 'hi';

class AppLocaleState {
  final Locale locale;
  final bool isInitialized;
  final bool isSaving;
  final AppFailure? failure;

  const AppLocaleState({
    required this.locale,
    required this.isInitialized,
    required this.isSaving,
    required this.failure,
  });

  factory AppLocaleState.initial() {
    return const AppLocaleState(
      locale: Locale(kDefaultAppLanguageCode),
      isInitialized: false,
      isSaving: false,
      failure: null,
    );
  }

  AppLocaleState copyWith({
    Locale? locale,
    bool? isInitialized,
    bool? isSaving,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return AppLocaleState(
      locale: locale ?? this.locale,
      isInitialized: isInitialized ?? this.isInitialized,
      isSaving: isSaving ?? this.isSaving,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class AppLocaleController extends StateNotifier<AppLocaleState> {
  final AuthRepository _authRepository;
  final String? _profileLanguageCode;

  AppLocaleController(
    this._authRepository, {
    String? profileLanguageCode,
  })  : _profileLanguageCode = profileLanguageCode,
        super(AppLocaleState.initial()) {
    _loadInitialLocale();
  }

  Future<void> _loadInitialLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguageCode = _normalizeLanguageCode(preferences.getString(_appLanguagePreferenceKey));
    final profileLanguageCode = _normalizeLanguageCode(_profileLanguageCode);
    final resolvedLanguageCode =
        savedLanguageCode ?? profileLanguageCode ?? kDefaultAppLanguageCode;
    if (savedLanguageCode == null) {
      await preferences.setString(
        _appLanguagePreferenceKey,
        profileLanguageCode ?? kDefaultAppLanguageCode,
      );
    }
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      locale: Locale(resolvedLanguageCode),
      isInitialized: true,
      clearFailure: true,
    );
  }

  Future<Result<void>> setLanguage(String languageCode) async {
    final normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    if (normalizedLanguageCode == null) {
      final failure = const ValidationFailure(
        message: 'Select a supported language',
        fieldErrors: {'preferred_language': 'Supported languages are English and Hindi'},
      );
      state = state.copyWith(failure: failure, isSaving: false, isInitialized: true);
      return const Failure<void>(
        ValidationFailure(
          message: 'Select a supported language',
          fieldErrors: {'preferred_language': 'Supported languages are English and Hindi'},
        ),
      );
    }

    state = state.copyWith(
      locale: Locale(normalizedLanguageCode),
      isInitialized: true,
      isSaving: true,
      clearFailure: true,
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appLanguagePreferenceKey, normalizedLanguageCode);
    final result = await _authRepository.updatePreferredLanguage(normalizedLanguageCode);

    if (!mounted) {
      return result;
    }

    state = state.copyWith(
      isSaving: false,
      failure: result.failureOrNull,
      clearFailure: result.isSuccess,
    );
    return result;
  }

  String? _normalizeLanguageCode(String? rawValue) {
    return switch ((rawValue ?? '').trim().toLowerCase()) {
      'hi' => 'hi',
      'en' => 'en',
      _ => null,
    };
  }
}

final appLocaleProvider = StateNotifierProvider<AppLocaleController, AppLocaleState>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return AppLocaleController(
    ref.watch(authRepositoryProvider),
    profileLanguageCode: profile?.preferredLanguage,
  );
});
