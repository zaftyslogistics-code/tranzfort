import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/contextual_tts_service.dart';
import 'notification_repository.dart';

class NotificationTtsService {
  final ContextualTtsService _contextualTtsService;

  NotificationTtsService({
    required ContextualTtsService contextualTtsService,
  }) : _contextualTtsService = contextualTtsService;

  Future<void> speakNotificationOpen(AppNotification notification, AppUserRole role) async {
    if (role != AppUserRole.trucker || notification.type != AppNotificationType.bookingUpdate) {
      return;
    }

    final title = (notification.titleText ?? '').trim().toLowerCase();
    String? phrase;
    if (title == 'booking rejected') {
      phrase = 'Booking reject ho gaya. Doosra load dhundein.';
    } else if (title == 'booking approved!') {
      phrase = 'Booking manjoor ho gaya. Pickup ki taraf chalein.';
    }

    if (phrase == null) {
      return;
    }

    await _contextualTtsService.speakSummary(
      languageCode: 'hi',
      message: phrase,
    );
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
