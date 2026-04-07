import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/repositories/load_repository.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/repositories/chat_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/utils/verification_status_utils.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

final chatStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final chatLocationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final chatLoadRepositoryProvider = Provider<LoadRepository>((ref) {
  return LoadRepository(ref.watch(supabaseClientProvider));
});

final canStartSupplierChatProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final role = (profile?['user_role_type'] ?? '').toString();
  final verificationStatus = normalizeVerificationStatus(
    profile?['verification_status'],
  );

  return role == 'trucker' && verificationStatus == 'verified';
});

final chatInboxProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final result = await ref.watch(chatRepositoryProvider).getConversations();
  return switch (result) {
    Success(data: final data) => data,
    Failure() => const <Map<String, dynamic>>[],
  };
});

final unreadCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final result = await ref
      .watch(chatRepositoryProvider)
      .getUnreadCountsByConversation();
  return switch (result) {
    Success(data: final data) => data,
    Failure() => const <String, int>{},
  };
});

final conversationDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      conversationId,
    ) async {
      final result = await ref
          .watch(chatRepositoryProvider)
          .getConversationById(conversationId);
      return switch (result) {
        Success(data: final data) => data,
        Failure() => null,
      };
    });

final chatMessagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      conversationId,
    ) async* {
      final repo = ref.watch(chatRepositoryProvider);
      final userId = ref.watch(authSessionProvider).value?.session?.user.id;
      final controller = StreamController<List<Map<String, dynamic>>>();

      Future<void> fetchAndEmit() async {
        final result = await repo.getMessages(conversationId);
        final messages = switch (result) {
          Success(data: final data) => data,
          Failure() => const <Map<String, dynamic>>[],
        };

        if (!controller.isClosed) {
          controller.add(messages);
        }

        if (userId != null) {
          await repo.markMessagesAsRead(conversationId, userId);
          ref.invalidate(unreadCountsProvider);
        }
      }

      await fetchAndEmit();

      final channel = repo.subscribeToMessages(conversationId, (_) async {
        await fetchAndEmit();
      });

      ref.onDispose(() {
        channel.unsubscribe();
        controller.close();
      });

      yield* controller.stream;
    });

class ChatSendNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ChatSendNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> sendText(String conversationId, String text) async {
    if (text.trim().isEmpty) return false;

    final userId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (userId == null) return false;

    state = const AsyncLoading();

    final result = await _ref
        .read(chatRepositoryProvider)
        .sendMessage(
          conversationId: conversationId,
          senderId: userId,
          messageType: 'text',
          textContent: text.trim(),
        );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(chatInboxProvider);
        _ref.invalidate(unreadCountsProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to send message', StackTrace.current);
        return false;
    }
  }

  Future<bool> sendVoice({
    required String conversationId,
    required File audioFile,
    required int durationSeconds,
  }) async {
    final userId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (userId == null) return false;

    state = const AsyncLoading();

    final storagePath =
        '$conversationId/${DateTime.now().millisecondsSinceEpoch}_$userId.m4a';
    final uploadResult = await _ref
        .read(chatStorageServiceProvider)
        .uploadPrivateFileAtPath(
          bucketName: 'voice-messages',
          fullPath: storagePath,
          file: audioFile,
        );

    late final String savedPath;
    switch (uploadResult) {
      case Success(data: final path):
        savedPath = path;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Failed to upload voice message',
          StackTrace.current,
        );
        return false;
    }

    final result = await _ref
        .read(chatRepositoryProvider)
        .sendMessage(
          conversationId: conversationId,
          senderId: userId,
          messageType: 'voice',
          voiceUrl: savedPath,
          voiceDurationSeconds: durationSeconds,
        );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(chatInboxProvider);
        _ref.invalidate(unreadCountsProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Failed to send voice message',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<bool> sendMapCard(String conversationId) async {
    final userId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (userId == null) return false;

    state = const AsyncLoading();

    CapturedLocation? captured;
    try {
      captured = await _ref
          .read(chatLocationServiceProvider)
          .captureCurrentLocation();
    } catch (_) {
      captured = null;
    }

    if (captured == null) {
      state = AsyncError('Location permission unavailable', StackTrace.current);
      return false;
    }

    final result = await _ref
        .read(chatRepositoryProvider)
        .sendMessage(
          conversationId: conversationId,
          senderId: userId,
          messageType: 'map_card',
          payload: {'lat': captured.lat, 'lng': captured.lng},
        );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(chatInboxProvider);
        _ref.invalidate(unreadCountsProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Failed to share map card',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<bool> sendBookingAction(String conversationId) async {
    final userId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (userId == null) return false;

    state = const AsyncLoading();

    final result = await _ref
        .read(chatRepositoryProvider)
        .sendMessage(
          conversationId: conversationId,
          senderId: userId,
          messageType: 'truck_card',
          textContent: 'Tap to book this load from chat.',
          payload: const {'action': 'book_load', 'label': 'Book This Load'},
        );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(chatInboxProvider);
        _ref.invalidate(unreadCountsProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Failed to send booking action',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<Result<void>> bookFromConversation(String conversationId) async {
    final userId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (userId == null) {
      return const Failure(
        AppFailureType.auth,
        debugMessage: 'Not authenticated',
      );
    }

    final profile = await _ref.read(userProfileProvider.future);
    final verificationStatus = normalizeVerificationStatus(
      profile?['verification_status'],
    );
    if (verificationStatus != 'verified') {
      return const Failure(
        AppFailureType.validation,
        debugMessage: 'You must be verified to book loads',
      );
    }

    final conversationResult = await _ref
        .read(chatRepositoryProvider)
        .getConversationById(conversationId);

    late final Map<String, dynamic> conversation;
    switch (conversationResult) {
      case Success(data: final data):
        conversation = data;
      case Failure(type: final type, debugMessage: final msg):
        return Failure(type, debugMessage: msg ?? 'Conversation not found');
    }

    final loadId = (conversation['load_id'] ?? '').toString();
    if (loadId.isEmpty) {
      return const Failure(
        AppFailureType.notFound,
        debugMessage: 'Load not found for this conversation',
      );
    }

    final trucksResult = await _ref
        .read(chatLoadRepositoryProvider)
        .getVerifiedTrucks(userId);

    late final List<Map<String, dynamic>> trucks;
    switch (trucksResult) {
      case Success(data: final data):
        trucks = data;
      case Failure(type: final type, debugMessage: final msg):
        return Failure(type, debugMessage: msg ?? 'Could not load trucks');
    }

    if (trucks.isEmpty) {
      return const Failure(
        AppFailureType.validation,
        debugMessage: 'No verified trucks available',
      );
    }

    final truckId = (trucks.first['id'] ?? '').toString();
    if (truckId.isEmpty) {
      return const Failure(
        AppFailureType.validation,
        debugMessage: 'Invalid truck',
      );
    }

    state = const AsyncLoading();
    final bookResult = await _ref
        .read(chatLoadRepositoryProvider)
        .bookLoad(parentLoadId: loadId, truckerId: userId, truckId: truckId);

    switch (bookResult) {
      case Success():
        await _ref
            .read(chatRepositoryProvider)
            .sendMessage(
              conversationId: conversationId,
              senderId: userId,
              messageType: 'system',
              textContent: 'Booking request sent from chat.',
            );
        state = const AsyncData(null);
        _ref.invalidate(chatInboxProvider);
        _ref.invalidate(unreadCountsProvider);
        return const Success(null);
      case Failure(type: final type, debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Unable to book from chat',
          StackTrace.current,
        );
        return Failure(type, debugMessage: msg ?? 'Unable to book from chat');
    }
  }
}

final chatSendProvider =
    StateNotifierProvider<ChatSendNotifier, AsyncValue<void>>((ref) {
      return ChatSendNotifier(ref);
    });
