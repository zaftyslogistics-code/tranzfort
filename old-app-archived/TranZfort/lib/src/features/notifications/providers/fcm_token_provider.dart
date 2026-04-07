import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_providers.dart';

class FcmTokenNotifier extends StateNotifier<String?> {
  final Ref _ref;

  FcmTokenNotifier(this._ref) : super(null) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pushEnabled = prefs.getBool('push_enabled') ?? true;
      if (!pushEnabled) {
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          await _saveToken(token);
        }

        messaging.onTokenRefresh.listen(_saveToken);
      }
    } catch (_) {}
  }

  Future<void> _saveToken(String token) async {
    state = token;
    final user = _ref.read(authSessionProvider).value?.session?.user;

    if (user != null) {
      try {
        await _ref
            .read(supabaseClientProvider)
            .from('profiles')
            .update({'push_token': token})
            .eq('id', user.id);
      } catch (_) {}
    }
  }
}

final fcmTokenProvider = StateNotifierProvider<FcmTokenNotifier, String?>((
  ref,
) {
  return FcmTokenNotifier(ref);
});
