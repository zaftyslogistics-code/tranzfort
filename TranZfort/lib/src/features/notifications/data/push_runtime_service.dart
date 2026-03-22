import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/providers/app_state_providers.dart';
import 'notification_route_resolver.dart';

enum PushPermissionStatus {
  authorized,
  provisional,
  denied,
  notDetermined,
  unavailable,
}

enum PushRuntimeIssue {
  permissionRequestFailed,
  localNotificationsInitFailed,
  localNotificationDisplayFailed,
  tokenSyncFailed,
}

class PushPermissionSnapshot {
  final PushPermissionStatus status;

  const PushPermissionSnapshot(this.status);

  bool get isEnabled =>
      status == PushPermissionStatus.authorized ||
      status == PushPermissionStatus.provisional;

  bool get canPromptAgain => status == PushPermissionStatus.notDetermined;

  String get label => switch (status) {
        PushPermissionStatus.authorized => 'Allowed',
        PushPermissionStatus.provisional => 'Allowed quietly',
        PushPermissionStatus.denied => 'Blocked in system settings',
        PushPermissionStatus.notDetermined => 'Not requested yet',
        PushPermissionStatus.unavailable => 'Unavailable on this device/build',
      };

  String get guidance => switch (status) {
        PushPermissionStatus.authorized =>
          'Foreground and opened push flows are enabled when Firebase delivery is configured.',
        PushPermissionStatus.provisional =>
          'Push is allowed quietly. You can promote alerts in the device notification settings if needed.',
        PushPermissionStatus.denied =>
          'Push notifications are blocked. Open your device notification settings for TranZfort to enable alerts again.',
        PushPermissionStatus.notDetermined =>
          'Push permission has not been requested yet on this device session.',
        PushPermissionStatus.unavailable =>
          'Push runtime is unavailable here until Firebase/device support is fully configured.',
      };
}

class PushRuntimeService {
  final FirebaseMessaging? _injectedMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<String> _localTapRoutes = StreamController<String>.broadcast();
  bool _localNotificationsInitialized = false;

  PushRuntimeService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _injectedMessaging = messaging,
       _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  FirebaseMessaging? get _messaging {
    if (_injectedMessaging != null) return _injectedMessaging;
    try {
      Firebase.app();
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PushPermissionSnapshot> fetchPermissionSnapshot() async {
    final messaging = _messaging;
    if (messaging == null) {
      return const PushPermissionSnapshot(PushPermissionStatus.unavailable);
    }
    try {
      final settings = await messaging.getNotificationSettings();
      return PushPermissionSnapshot(_mapAuthorizationStatus(settings.authorizationStatus));
    } catch (_) {
      return const PushPermissionSnapshot(PushPermissionStatus.unavailable);
    }
  }

  Future<bool> initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return true;
    }

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final route = normalizePushPayloadRoute(response.payload);
          if (route == null) {
            return;
          }
          _localTapRoutes.add(route);
        },
      );
      _localNotificationsInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<String> tappedNotificationRoutes() {
    return _localTapRoutes.stream;
  }

  PushPermissionStatus _mapAuthorizationStatus(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => PushPermissionStatus.authorized,
      AuthorizationStatus.provisional => PushPermissionStatus.provisional,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
    };
  }

  Stream<RemoteMessage> foregroundMessages() {
    try {
      Firebase.app();
      return FirebaseMessaging.onMessage;
    } catch (_) {
      return const Stream.empty();
    }
  }

  Stream<RemoteMessage> openedMessages() {
    try {
      Firebase.app();
      return FirebaseMessaging.onMessageOpenedApp;
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<RemoteMessage?> getInitialMessage() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      return await messaging.getInitialMessage();
    } catch (_) {
      return null;
    }
  }

  Future<bool> showForegroundMessage(RemoteMessage message, {String? payloadRoute}) async {
    final notification = message.notification;
    if (notification == null) {
      return true;
    }

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification.title ?? 'New notification',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tranzfort_foreground_notifications',
            'Foreground Notifications',
            channelDescription: 'Foreground push notifications for TranZfort',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payloadRoute,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final pushRuntimeServiceProvider = Provider<PushRuntimeService>((ref) {
  return PushRuntimeService();
});

final pendingPushRouteProvider = StateProvider<String?>((ref) => null);

final pushRuntimeIssuesProvider = StateProvider<Set<PushRuntimeIssue>>((ref) => <PushRuntimeIssue>{});

final pushPermissionRefreshProvider = StateProvider<int>((ref) => 0);

final pushPermissionSnapshotProvider = FutureProvider<PushPermissionSnapshot>((ref) async {
  ref.watch(pushPermissionRefreshProvider);
  final authState = ref.watch(currentAuthStateProvider);
  if (!authState.hasSession) {
    return const PushPermissionSnapshot(PushPermissionStatus.unavailable);
  }
  return ref.watch(pushRuntimeServiceProvider).fetchPermissionSnapshot();
});

final pushRuntimeLifecycleProvider = Provider<void>((ref) {
  final authState = ref.watch(currentAuthStateProvider);
  final service = ref.watch(pushRuntimeServiceProvider);
  StreamSubscription<String>? localTapSubscription;
  StreamSubscription<RemoteMessage>? messageSubscription;
  StreamSubscription<RemoteMessage>? openSubscription;

  if (authState.hasSession) {
    unawaited(() async {
      try {
        final ok = await service.requestPermission();
        _setPushRuntimeIssue(ref, PushRuntimeIssue.permissionRequestFailed, !ok);
      } catch (e) {
        debugPrint('Push permission request error: $e');
        _setPushRuntimeIssue(ref, PushRuntimeIssue.permissionRequestFailed, true);
      }
    }());
    unawaited(() async {
      try {
        final ok = await service.initializeLocalNotifications();
        _setPushRuntimeIssue(ref, PushRuntimeIssue.localNotificationsInitFailed, !ok);
      } catch (e) {
        debugPrint('Local notifications init error: $e');
        _setPushRuntimeIssue(ref, PushRuntimeIssue.localNotificationsInitFailed, true);
      }
    }());
    localTapSubscription = service.tappedNotificationRoutes().listen((route) {
      ref.read(pendingPushRouteProvider.notifier).state = route;
    });
    messageSubscription = service.foregroundMessages().listen((message) {
      final route = routeFromPushMessage(message, authState.role);
      unawaited(() async {
        try {
          final shown = await service.showForegroundMessage(message, payloadRoute: route);
          _setPushRuntimeIssue(ref, PushRuntimeIssue.localNotificationDisplayFailed, !shown);
        } catch (e) {
          debugPrint('Foreground message display error: $e');
          _setPushRuntimeIssue(ref, PushRuntimeIssue.localNotificationDisplayFailed, true);
        }
      }());
    });
    openSubscription = service.openedMessages().listen((message) {
      ref.read(pendingPushRouteProvider.notifier).state = routeFromPushMessage(message, authState.role);
    });
    unawaited(() async {
      try {
        final initialMessage = await service.getInitialMessage();
        if (initialMessage == null) {
          return;
        }
        ref.read(pendingPushRouteProvider.notifier).state = routeFromPushMessage(initialMessage, authState.role);
      } catch (e) {
        debugPrint('Initial push message fetch error: $e');
      }
    }());
  } else {
    Future.microtask(() {
      ref.read(pushRuntimeIssuesProvider.notifier).state = <PushRuntimeIssue>{};
    });
  }

  ref.onDispose(() {
    unawaited(localTapSubscription?.cancel() ?? Future<void>.value());
    unawaited(messageSubscription?.cancel() ?? Future<void>.value());
    unawaited(openSubscription?.cancel() ?? Future<void>.value());
  });
});

void _setPushRuntimeIssue(Ref ref, PushRuntimeIssue issue, bool hasIssue) {
  final current = ref.read(pushRuntimeIssuesProvider);
  final next = <PushRuntimeIssue>{...current};
  if (hasIssue) {
    next.add(issue);
  } else {
    next.remove(issue);
  }
  ref.read(pushRuntimeIssuesProvider.notifier).state = next;
}

String routeFromPushMessage(RemoteMessage message, AppUserRole role) {
  return routeFromPushData(message.data, role);
}

String routeFromPushData(Map<String, dynamic> data, AppUserRole role) {
  return resolveNotificationRouteData(
    role: role,
    actionRouteHint: data['action_route_hint']?.toString() ?? data['route']?.toString(),
    relatedLoadId: data['related_load_id']?.toString() ?? data['loadId']?.toString(),
    relatedTripId: data['related_trip_id']?.toString() ?? data['tripId']?.toString(),
    relatedCaseId: data['related_case_id']?.toString() ?? data['caseId']?.toString(),
  );
}

String? normalizePushPayloadRoute(String? payload) {
  final raw = payload?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}
