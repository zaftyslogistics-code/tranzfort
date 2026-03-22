import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_state_providers.dart';

class AuthRouterRefreshNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;
  ProviderSubscription<AsyncValue<AuthStateSnapshot>>? _profileSubscription;

  AuthRouterRefreshNotifier(Ref ref) {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    } catch (_) {
      _authSubscription = null;
    }

    _profileSubscription = ref.listen<AsyncValue<AuthStateSnapshot>>(
      authStateProvider,
      (previous, next) {
        final prevSnapshot = previous?.valueOrNull;
        final nextSnapshot = next.valueOrNull;
        if (prevSnapshot == null || nextSnapshot == null) return;

        if (prevSnapshot.isBanned != nextSnapshot.isBanned ||
            prevSnapshot.isDeactivated != nextSnapshot.isDeactivated ||
            prevSnapshot.role != nextSnapshot.role ||
            prevSnapshot.hasSession != nextSnapshot.hasSession) {
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.close();
    super.dispose();
  }
}
