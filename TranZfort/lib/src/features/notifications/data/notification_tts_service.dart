import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/tts_audio_language_provider.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../l10n/tts_localizations.dart';
import 'notification_repository.dart';

class NotificationTtsService {
  final ContextualTtsService _contextualTtsService;

  NotificationTtsService({
    required ContextualTtsService contextualTtsService,
  }) : _contextualTtsService = contextualTtsService;

  Future<void> speakNotificationOpen({
    required AppNotification notification,
    required AppUserRole role,
    required String audioLanguageCode,
  }) async {
    if (role != AppUserRole.trucker || notification.type != AppNotificationType.bookingUpdate) {
      return;
    }

    final languageCode =
        TtsAudioLanguageNotifier.normalizeLanguageCode(audioLanguageCode) ?? 'en';
    final phrase = _bookingPhrase(notification, languageCode: languageCode);
    if (phrase == null) {
      return;
    }

    await _contextualTtsService.speakSummary(
      languageCode: languageCode,
      message: phrase,
    );
  }

  String? _bookingPhrase(
    AppNotification notification, {
    required String languageCode,
  }) {
    final title = _normalizeNotificationTitle(notification.titleText);
    final tts = lookupTtsLocalizations(Locale(languageCode));
    if (title.contains('reject')) {
      return tts.ttsBookingRejected;
    }
    if (title.contains('approv')) {
      return tts.ttsBookingApproved;
    }
    return null;
  }

  static String _normalizeNotificationTitle(String? title) {
    return (title ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[!?.]+'), '');
  }

  Future<void> dispose() async {
    await _contextualTtsService.stop();
  }
}

final notificationTtsServiceProvider = Provider<NotificationTtsService>((ref) {
  final service = NotificationTtsService(
    contextualTtsService: ref.watch(contextualTtsServiceProvider),
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
