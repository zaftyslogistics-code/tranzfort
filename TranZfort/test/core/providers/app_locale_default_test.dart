import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);

  @override
  Future<Result<void>> updatePreferredLanguage(String languageCode) async {
    return const Success<void>(null);
  }
}

void main() {
  test('defaults to Hindi when no saved language and no profile', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        currentProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    for (var attempt = 0; attempt < 20; attempt++) {
      if (container.read(appLocaleProvider).isInitialized) {
        break;
      }
      await Future<void>.delayed(Duration.zero);
    }

    expect(container.read(appLocaleProvider).locale.languageCode, 'hi');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'hi');
  });
}
