import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../auth/providers/auth_providers.dart';

class FcmTokenNotifier extends StateNotifier<String?> {
  final Ref _ref;

  FcmTokenNotifier(this._ref) : super(null) {
    _initialize();
  }

  Future<void> _initialize() async {
    // If permission not granted, request it
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen(_saveToken);
    }
  }

  Future<void> _saveToken(String token) async {
    state = token;
    final user = _ref.read(authSessionProvider).value?.session?.user;
    
    if (user != null) {
      try {
        await _ref.read(supabaseClientProvider)
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
      } catch (e) {
        // Silently fail if unable to save token to DB
      }
    }
  }
}

final fcmTokenProvider = StateNotifierProvider<FcmTokenNotifier, String?>((ref) {
  return FcmTokenNotifier(ref);
});
