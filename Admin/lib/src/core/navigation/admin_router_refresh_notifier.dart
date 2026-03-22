import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

class AdminRouterRefreshNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;
  ProviderSubscription<AsyncValue<AdminAuthStateSnapshot>>? _authStateSubscription;

  AdminRouterRefreshNotifier(Ref ref) {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    } catch (_) {
      _authSubscription = null;
    }

    _authStateSubscription = ref.listen<AsyncValue<AdminAuthStateSnapshot>>(
      adminAuthStateProvider,
      (previous, next) {
        final previousSnapshot = previous?.valueOrNull;
        final nextSnapshot = next.valueOrNull;
        if (previousSnapshot == null || nextSnapshot == null) {
          return;
        }

        if (previousSnapshot.hasSession != nextSnapshot.hasSession ||
            previousSnapshot.role != nextSnapshot.role ||
            previousSnapshot.isActive != nextSnapshot.isActive ||
            previousSnapshot.verificationFailed != nextSnapshot.verificationFailed ||
            previousSnapshot.isLoading != nextSnapshot.isLoading) {
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authStateSubscription?.close();
    super.dispose();
  }
}
