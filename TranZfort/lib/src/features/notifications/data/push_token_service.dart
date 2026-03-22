import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_state_providers.dart';
import 'push_runtime_service.dart';

class PushTokenService {
  final SupabaseClient? _client;
  final FirebaseMessaging? _injectedMessaging;

  PushTokenService(
    this._client, {
    FirebaseMessaging? messaging,
  }) : _injectedMessaging = messaging;

  FirebaseMessaging? get _messaging {
    if (_injectedMessaging != null) return _injectedMessaging;
    try {
      Firebase.app();
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<bool> syncCurrentToken() async {
    final messaging = _messaging;
    final userId = _client?.auth.currentUser?.id;
    if (userId == null || messaging == null) {
      return true;
    }

    try {
      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return true;
      }
      await _updatePushToken(userId, token.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<String> watchTokenRefresh() {
    final messaging = _messaging;
    if (messaging == null) return const Stream.empty();
    return messaging.onTokenRefresh.map((token) => token.trim()).where((token) => token.isNotEmpty);
  }

  Future<bool> syncRefreshedToken(String token) async {
    final userId = _client?.auth.currentUser?.id;
    if (userId == null || token.trim().isEmpty) {
      return true;
    }

    try {
      await _updatePushToken(userId, token.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updatePushToken(String userId, String token) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    await _client.rpc('set_push_token', params: {'p_token': token});
  }
}

final pushTokenServiceProvider = Provider<PushTokenService>((ref) {
  return PushTokenService(ref.watch(supabaseClientProvider));
});

final pushTokenLifecycleProvider = Provider<void>((ref) {
  final authState = ref.watch(currentAuthStateProvider);
  final service = ref.watch(pushTokenServiceProvider);
  StreamSubscription<String>? refreshSubscription;

  void setPushRuntimeIssue(PushRuntimeIssue issue, bool hasIssue) {
    final next = <PushRuntimeIssue>{...ref.read(pushRuntimeIssuesProvider)};
    if (hasIssue) {
      next.add(issue);
    } else {
      next.remove(issue);
    }
    ref.read(pushRuntimeIssuesProvider.notifier).state = next;
  }

  if (authState.hasSession) {
    unawaited(() async {
      final ok = await service.syncCurrentToken();
      setPushRuntimeIssue(PushRuntimeIssue.tokenSyncFailed, !ok);
    }());
    refreshSubscription = service.watchTokenRefresh().listen((token) {
      unawaited(() async {
        final ok = await service.syncRefreshedToken(token);
        setPushRuntimeIssue(PushRuntimeIssue.tokenSyncFailed, !ok);
      }());
    });
  } else {
    Future.microtask(() => setPushRuntimeIssue(PushRuntimeIssue.tokenSyncFailed, false));
  }

  ref.onDispose(() async {
    await refreshSubscription?.cancel();
  });
});
