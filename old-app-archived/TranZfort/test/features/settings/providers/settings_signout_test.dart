import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/auth_repository.dart';
import 'package:app/src/features/settings/providers/settings_provider.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SettingsNotifier signOut', () {
    test('clears prefs except has_seen_splash', () async {
      SharedPreferences.setMockInitialValues({
        'has_seen_splash': true,
        'tts_muted': true,
        'push_enabled': false,
      });

      final authRepository = MockAuthRepository();
      when(() => authRepository.signOut())
          .thenAnswer((_) async => const Success(null));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_splash'), isTrue);
      expect(prefs.getBool('tts_muted'), isNull);
      expect(prefs.getBool('push_enabled'), isNull);
    });
  });
}
