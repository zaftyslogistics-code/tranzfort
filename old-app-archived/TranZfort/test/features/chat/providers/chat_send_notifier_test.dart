import 'dart:io';

import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/chat_repository.dart';
import 'package:app/src/core/repositories/load_repository.dart';
import 'package:app/src/core/services/location_service.dart';
import 'package:app/src/core/services/storage_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/chat/providers/chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockLoadRepository extends Mock implements LoadRepository {}

class FakeStorageService extends Fake implements StorageService {}

class FakeLocationService extends Fake implements LocationService {
  @override
  Future<CapturedLocation?> captureCurrentLocation() async {
    return const CapturedLocation(lat: 19.076, lng: 72.8777);
  }
}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'token',
    'token_type': 'bearer',
    'user': {'id': 'user-1', 'email': 'user@example.com'},
  });
  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  group('ChatSendNotifier', () {
    test('sendText success returns true', () async {
      final chatRepository = MockChatRepository();
      when(
        () => chatRepository.sendMessage(
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: 'text',
          textContent: 'hello',
        ),
      ).thenAnswer((_) async => Success({'id': 'msg-1'}));

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(chatSendProvider.notifier);
      final ok = await notifier.sendText('conv-1', 'hello');

      expect(ok, isTrue);
      expect(container.read(chatSendProvider), isA<AsyncData<void>>());
    });

    test('sendMapCard failure when location unavailable', () async {
      final chatRepository = MockChatRepository();
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
          chatLocationServiceProvider.overrideWithValue(_NullLocation()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(chatSendProvider.notifier);
      final ok = await notifier.sendMapCard('conv-1');

      expect(ok, isFalse);
      expect(container.read(chatSendProvider), isA<AsyncError<void>>());
    });

    test('sendVoice uploads and sends message', () async {
      final chatRepository = MockChatRepository();
      final storage = _FakeStorageService();
      when(
        () => chatRepository.sendMessage(
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: 'voice',
          voiceUrl: 'private/path',
          voiceDurationSeconds: 5,
        ),
      ).thenAnswer((_) async => Success({'id': 'msg-1'}));

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          chatStorageServiceProvider.overrideWithValue(storage),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final file = File('${Directory.systemTemp.path}/voice.m4a')
        ..writeAsBytesSync([1, 2, 3]);
      final notifier = container.read(chatSendProvider.notifier);
      final ok = await notifier.sendVoice(
        conversationId: 'conv-1',
        audioFile: file,
        durationSeconds: 5,
      );

      expect(ok, isTrue);
      expect(container.read(chatSendProvider), isA<AsyncData<void>>());
    });

    test('bookFromConversation success sends system message', () async {
      final chatRepository = MockChatRepository();
      final loadRepository = MockLoadRepository();

      when(() => chatRepository.getConversationById('conv-1'))
          .thenAnswer((_) async => Success({'load_id': 'load-1'}));
      when(() => loadRepository.getVerifiedTrucks('user-1')).thenAnswer(
        (_) async => Success([
          {'id': 'truck-1'}
        ]),
      );
      when(
        () => loadRepository.bookLoad(
          parentLoadId: 'load-1',
          truckerId: 'user-1',
          truckId: 'truck-1',
        ),
      ).thenAnswer((_) async => const Success(null));
      when(
        () => chatRepository.sendMessage(
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: 'system',
          textContent: 'Booking request sent from chat.',
        ),
      ).thenAnswer((_) async => Success({'id': 'msg-2'}));

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          chatLoadRepositoryProvider.overrideWithValue(loadRepository),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
          userProfileProvider.overrideWith(
            (ref) async => {
              'id': 'user-1',
              'verification_status': 'verified',
              'user_role_type': 'trucker',
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(chatSendProvider.notifier);
      final result = await notifier.bookFromConversation('conv-1');

      expect(result, isA<Success<void>>());
      expect(container.read(chatSendProvider), isA<AsyncData<void>>());
    });
  });
}

class _FakeStorageService extends Fake implements StorageService {
  @override
  Future<Result<String>> uploadPrivateFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('private/path');
  }
}

class _NullLocation extends Fake implements LocationService {
  _NullLocation();

  @override
  Future<CapturedLocation?> captureCurrentLocation() async {
    return null;
  }
}
