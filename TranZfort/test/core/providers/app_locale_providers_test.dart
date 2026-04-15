import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';

class _FakeAuthRepository extends AuthRepository {
  String? lastPreferredLanguage;
  Result<void> updatePreferredLanguageResult;

  _FakeAuthRepository()
      : updatePreferredLanguageResult = const Success<void>(null),
        super(null);

  @override
  Future<Result<void>> updatePreferredLanguage(String languageCode) async {
    lastPreferredLanguage = languageCode;
    return updatePreferredLanguageResult;
  }
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _waitForLocaleInitialization(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(appLocaleProvider).isInitialized) {
      return;
    }
    await _flushAsync();
  }
  fail('App locale provider did not initialize in time.');
}

void main() {
  test('app locale provider loads saved language from shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'app_language': 'hi'});
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    await _waitForLocaleInitialization(container);

    expect(container.read(appLocaleProvider).locale.languageCode, 'hi');
    expect(container.read(appLocaleProvider).isInitialized, isTrue);
  });

  test('app locale provider falls back to profile preferred language when no saved language exists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith(
          (ref) => Stream.value(
            const UserProfile(
              id: 'user-1',
              fullName: 'Aarav Singh',
              mobile: '9999999999',
              email: 'aarav@example.com',
              roleType: 'supplier',
              preferredLanguage: 'hi',
              isBanned: false,
              accountDeletionStatus: 'active',
              trustSafetyStatus: 'normal',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForLocaleInitialization(container);

    expect(container.read(appLocaleProvider).locale.languageCode, 'hi');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'hi');
  });

  test('app locale provider persists language updates locally and through auth repository', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'app_language': 'en'});
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    await _waitForLocaleInitialization(container);
    final result = await container.read(appLocaleProvider.notifier).setLanguage('hi');

    expect(result.isSuccess, isTrue);
    expect(container.read(appLocaleProvider).locale.languageCode, 'hi');
    expect(repository.lastPreferredLanguage, 'hi');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'hi');
  });
}
