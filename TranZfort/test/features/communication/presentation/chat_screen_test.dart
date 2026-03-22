import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/communication/data/voice_message_service.dart';
import 'package:tranzfort/src/features/communication/data/voice_playback_service.dart';
import 'package:tranzfort/src/features/communication/presentation/chat_screen.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/load_detail_provider.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_profile_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_providers.dart';
import 'package:tranzfort/src/features/trucker/data/diesel_price_repository.dart';

class _UnusedChatBackend implements ChatBackend {
  const _UnusedChatBackend();

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async => throw UnimplementedError();

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async => throw UnimplementedError();

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async => throw UnimplementedError();

  @override
  Future<bool> fetchHasUnread({required String conversationId, required String currentUserId}) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({required String loadId, required String truckerId}) async => throw UnimplementedError();

  @override
  Future<String> createOrGetConversation({required String supplierId, required String truckerId, required String loadId}) async => throw UnimplementedError();

  @override
  Future<String> sendMessage({required String conversationId, required ChatMessageType type, String? messageId, String? textBody, String? attachmentPath, Map<String, dynamic>? structuredPayload}) async => throw UnimplementedError();

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async => throw UnimplementedError();
}

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository({
    required this.conversations,
    required this.messages,
  }) : super(const _UnusedChatBackend(), () => 'trucker-1', () => AppUserRole.trucker);

  final List<ConversationPreview> conversations;
  final List<ChatMessage> messages;
  final StreamController<Result<List<ConversationPreview>>> conversationStreamController =
      StreamController<Result<List<ConversationPreview>>>.broadcast();
  final StreamController<Result<List<ChatMessage>>> messageStreamController =
      StreamController<Result<List<ChatMessage>>>.broadcast();

  String? markedReadConversationId;
  String? lastSentConversationId;
  String? lastSentText;
  String? lastVoiceAttachmentPath;
  Completer<Result<String>>? sendCompleter;
  Result<String>? sendTextResult;
  Result<List<ChatMessage>>? getMessagesResult;

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async => Success<List<ConversationPreview>>(conversations);

  @override
  Stream<Result<List<ConversationPreview>>> watchConversations() => conversationStreamController.stream;

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    return getMessagesResult ?? Success<List<ChatMessage>>(messages);
  }

  @override
  Stream<Result<List<ChatMessage>>> watchMessages(String conversationId) => messageStreamController.stream;

  @override
  Future<Result<String>> sendTextMessage({required String conversationId, required String text}) async {
    lastSentConversationId = conversationId;
    lastSentText = text;
    if (sendTextResult != null) {
      return sendTextResult!;
    }
    if (sendCompleter != null) {
      return sendCompleter!.future;
    }
    return const Success<String>('message-2');
  }

  @override
  Future<Result<String>> sendVoiceMessage({
    required String conversationId,
    String? messageId,
    required String attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async {
    lastSentConversationId = conversationId;
    lastVoiceAttachmentPath = attachmentPath;
    return const Success<String>('message-voice');
  }

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    markedReadConversationId = conversationId;
    return const Success<void>(null);
  }

  void dispose() {
    conversationStreamController.close();
    messageStreamController.close();
  }
}

class _FakeVoicePlaybackService extends VoicePlaybackService {
  _FakeVoicePlaybackService() : super(null);

  String? signedUrl = 'https://example.com/test-voice.m4a';
  int signedUrlCalls = 0;

  @override
  Future<String?> createSignedUrl(String path) async {
    signedUrlCalls += 1;
    return signedUrl;
  }
}

class _FakeVoicePlaybackController implements VoicePlaybackController {
  final ValueNotifier<VoicePlaybackSnapshot> _snapshot =
      ValueNotifier<VoicePlaybackSnapshot>(const VoicePlaybackSnapshot.initial());

  int toggleCalls = 0;
  String? lastUrl;
  Object? toggleError;

  @override
  ValueListenable<VoicePlaybackSnapshot> get snapshot => _snapshot;

  @override
  Future<void> togglePlayback(String signedUrl) async {
    if (toggleError != null) {
      throw toggleError!;
    }
    toggleCalls += 1;
    lastUrl = signedUrl;
    _snapshot.value = _snapshot.value.copyWith(
      isPlaying: !_snapshot.value.isPlaying,
      duration: const Duration(seconds: 12),
      position: _snapshot.value.isPlaying ? Duration.zero : const Duration(seconds: 4),
      isLoading: false,
    );
  }

  @override
  Future<void> dispose() async {
    _snapshot.dispose();
  }
}

class _FakeVoiceMessageService extends VoiceMessageService {
  _FakeVoiceMessageService() : super(null);

  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  Result<void> startResult = const Success<void>(null);
  Result<VoiceMessageUpload> stopResult = const Success<VoiceMessageUpload>(
    VoiceMessageUpload(
      messageId: 'message-voice',
      attachmentPath: 'conversation-1/test-voice.m4a',
      durationSeconds: 3,
    ),
  );

  @override
  Future<Result<void>> startRecording({required String conversationId}) async {
    startCalls += 1;
    return startResult;
  }

  @override
  Future<Result<VoiceMessageUpload>> stopAndUpload({required String conversationId}) async {
    stopCalls += 1;
    return stopResult;
  }

  @override
  Future<void> cancelRecording() async {
    cancelCalls += 1;
  }
}

class _NoopSupplierLoadBackend implements SupplierLoadBackend {
  @override
  Future<String> approveBookingRequest(String bookingId) async => 'trip-1';

  @override
  Future<String> createLoad(Map<String, dynamic> params) async => 'load-new';

  @override
  Future<void> cancelLoad(String loadId) async {}

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {}

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({required String supplierId, required String loadId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({required String supplierId, required String loadId}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({required String supplierId, required String loadId}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({required String supplierId, required LoadFilters filters, required int page, required int pageSize}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {}
}

class _TestLoadDetailController extends LoadDetailController {
  _TestLoadDetailController(LoadDetailState state)
      : super(
          SupplierLoadRepository(_NoopSupplierLoadBackend(), () => 'supplier-1'),
          state.loadId,
        ) {
    this.state = state;
  }

  @override
  Future<void> load() async {}
}

ConversationPreview _conversation({String bookingStatusLabel = 'approved'}) {
  return ConversationPreview(
    id: 'conversation-1',
    supplierId: 'supplier-1',
    truckerId: 'trucker-1',
    loadId: 'load-1',
    tripId: 'trip-1',
    routeLabel: 'Chandrapur, Maharashtra → Mumbai, Maharashtra',
    loadMaterial: 'Coal',
    loadPriceAmount: 62500,
    loadStatusLabel: 'active',
    pickupDate: DateTime(2026, 3, 11),
    supplierName: 'Amit Supplier',
    supplierMobile: '+919876543210',
    supplierCompanyName: 'Amit Logistics',
    truckerName: 'Ravi Trucker',
    truckerMobile: '+919812345678',
    truckDisplayLabel: 'MH12AB1234 • Tata Ace Gold',
    bookingRequestId: 'booking-1',
    bookingStatusLabel: bookingStatusLabel,
    latestMessagePreview: 'Report after unloading',
    lastMessageAt: DateTime(2026, 3, 10, 9),
    hasUnread: true,
    isArchived: false,
    createdAt: DateTime(2026, 3, 10, 8),
  );
}

ChatMessage _message({required String id, required String textBody, required bool isFromCurrentUser}) {
  return ChatMessage(
    id: id,
    conversationId: 'conversation-1',
    senderProfileId: isFromCurrentUser ? 'trucker-1' : 'supplier-1',
    type: ChatMessageType.text,
    textBody: textBody,
    attachmentPath: null,
    structuredPayload: null,
    isRead: true,
    readAt: DateTime(2026, 3, 10, 9, 1),
    createdAt: DateTime(2026, 3, 10, 9, isFromCurrentUser ? 2 : 0),
    isFromCurrentUser: isFromCurrentUser,
  );
}

ChatMessage _typedMessage({
  required String id,
  required ChatMessageType type,
  String? textBody,
  String? attachmentPath,
  Map<String, dynamic>? structuredPayload,
}) {
  return ChatMessage(
    id: id,
    conversationId: 'conversation-1',
    senderProfileId: 'supplier-1',
    type: type,
    textBody: textBody,
    attachmentPath: attachmentPath,
    structuredPayload: structuredPayload,
    isRead: true,
    readAt: DateTime(2026, 3, 10, 9, 1),
    createdAt: DateTime(2026, 3, 10, 9, 3),
    isFromCurrentUser: false,
  );
}

Widget _buildApp(
  _FakeChatRepository repository, {
  _FakeVoiceMessageService? voiceMessageService,
  _FakeVoicePlaybackService? voicePlaybackService,
  _FakeVoicePlaybackController? voicePlaybackController,
  Map<String, double>? dieselPriceMap,
  TruckerProfile? truckerProfile,
  AppUserRole role = AppUserRole.trucker,
  LoadDetailState? loadDetailState,
}) {
  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        AuthStateSnapshot(
          hasSession: true,
          role: role,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
      chatRepositoryProvider.overrideWithValue(repository),
      truckerProfileProvider.overrideWith((ref) async => truckerProfile ?? _verifiedTruckerProfile()),
      voiceMessageServiceProvider.overrideWithValue(voiceMessageService ?? _FakeVoiceMessageService()),
      voicePlaybackServiceProvider.overrideWithValue(voicePlaybackService ?? _FakeVoicePlaybackService()),
      voicePlaybackControllerFactoryProvider.overrideWithValue(
        () => voicePlaybackController ?? _FakeVoicePlaybackController(),
      ),
      if (dieselPriceMap != null) dieselPriceMapProvider.overrideWith((ref) async => dieselPriceMap),
      if (loadDetailState != null) loadDetailProvider(loadDetailState.loadId).overrideWith((ref) => _TestLoadDetailController(loadDetailState)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChatScreen(conversationId: 'conversation-1'),
    ),
  );
}

Widget _buildRoutedApp(
  _FakeChatRepository repository, {
  Map<String, double>? dieselPriceMap,
  TruckerProfile? truckerProfile,
  void Function(ReportIssueContext context)? onReportIssue,
}) {
  final router = GoRouter(
    initialLocation: '${AppRoutes.chatPath}/conversation-1',
    routes: [
      GoRoute(
        path: '${AppRoutes.chatPath}/:conversationId',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, state) => Scaffold(
          body: Text('Load ${state.pathParameters['loadId'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.messagesPath,
        builder: (context, state) => const Scaffold(body: Text('Messages opened')),
      ),
      GoRoute(
        path: AppRoutes.truckerVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Trucker verification opened')),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
      ),
      GoRoute(
        path: AppRoutes.reportIssuePath,
        builder: (context, state) {
          final extra = state.extra as ReportIssueContext;
          onReportIssue?.call(extra);
          return const Scaffold(body: Text('Report issue opened'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
      chatRepositoryProvider.overrideWithValue(repository),
      truckerProfileProvider.overrideWith((ref) async => truckerProfile ?? _verifiedTruckerProfile()),
      voiceMessageServiceProvider.overrideWithValue(_FakeVoiceMessageService()),
      voicePlaybackServiceProvider.overrideWithValue(_FakeVoicePlaybackService()),
      voicePlaybackControllerFactoryProvider.overrideWithValue(() => _FakeVoicePlaybackController()),
      if (dieselPriceMap != null) dieselPriceMapProvider.overrideWith((ref) async => dieselPriceMap),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

TruckerProfile _verifiedTruckerProfile() {
  return const TruckerProfile(
    id: 'trucker-1',
    fullName: 'Ravi Trucker',
    mobile: '+919812345678',
    email: 'trucker@example.com',
    verificationStatus: 'verified',
    dlNumber: 'DL-12345',
    rating: 4.5,
    totalTrips: 10,
    completedTrips: 8,
    totalTrucks: 1,
    approvedTrucks: 1,
  );
}

void main() {
  testWidgets('renders chat thread and marks conversation read on open', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Booking approved!', isFromCurrentUser: false),
        _message(id: 'message-2', textBody: 'On my way', isFromCurrentUser: true),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Amit Supplier'), findsOneWidget);
    expect(find.text('Load context'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('Booking approved!'), findsOneWidget);
    expect(find.text('On my way'), findsOneWidget);
    expect(repository.markedReadConversationId, 'conversation-1');
  });

  testWidgets('chat screen falls back to unknown for unsupported booking status', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation(bookingStatusLabel: 'needs_manual_review')],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Please wait for manual review.', isFromCurrentUser: false),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('UNKNOWN'), findsOneWidget);
    expect(find.text('Needs Manual Review'), findsNothing);
  });

  testWidgets('sends text messages from composer', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Reached unloading point');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(repository.lastSentConversationId, 'conversation-1');
    expect(repository.lastSentText, 'Reached unloading point');
  });

  testWidgets('shows sanitized text-send failure copy', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    )..sendTextResult = const Failure<String>(UnknownFailure(message: 'PostgrestException: leaked detail'));

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Reached unloading point');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.text('We could not send your message right now. Retry shortly from this chat.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('shows sanitized thread-load failure copy', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: const <ChatMessage>[],
    )..getMessagesResult = const Failure<List<ChatMessage>>(UnknownFailure(message: 'PostgrestException: leaked detail'));

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('We could not load this conversation right now. Retry shortly to refresh the latest messages and booking context.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('shows sanitized booking action failure copy', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Booking pending action', isFromCurrentUser: false),
      ],
    );

    await tester.pumpWidget(
      _buildApp(
        repository,
        role: AppUserRole.supplier,
        loadDetailState: LoadDetailState(
          loadId: 'load-1',
          detail: null,
          bookingRequests: const <LoadBookingRequest>[],
          linkedTrips: const <LinkedTrip>[],
          isLoading: false,
          isCancelling: false,
          isClosingFilledOutsideApp: false,
          approvingBookingId: null,
          rejectingBookingId: null,
          failure: null,
          actionFailure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking action unavailable'), findsOneWidget);
    expect(
      find.text('The latest booking action could not be completed from this chat. Review the booking state and retry shortly.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('shows optimistic sending state before send completes', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    )..sendCompleter = Completer<Result<String>>();

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Reached unloading point');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(find.text('sending...'), findsOneWidget);
    expect(repository.lastSentConversationId, 'conversation-1');
    expect(repository.lastSentText, 'Reached unloading point');

    repository.sendCompleter!.complete(const Success<String>('message-2'));
    await tester.pumpAndSettle();

    expect(find.text('sending...'), findsNothing);
  });

  testWidgets('blocks trucker replies until verification is complete', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );

    await tester.pumpWidget(
      _buildApp(
        repository,
        truckerProfile: const TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919812345678',
          email: 'trucker@example.com',
          verificationStatus: 'unverified',
          dlNumber: null,
          rating: 0,
          totalTrips: 0,
          completedTrips: 0,
          totalTrucks: 0,
          approvedTrucks: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chat and call gating'), findsOneWidget);
    expect(
      find.text('Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.'),
      findsOneWidget,
    );
    expect(find.text('Open verification'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Reached unloading point');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(repository.lastSentConversationId, isNull);
    expect(repository.lastSentText, isNull);
  });

  testWidgets('blocked trucker chat readiness action opens trucker verification when verification is incomplete', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );

    await tester.pumpWidget(
      _buildRoutedApp(
        repository,
        truckerProfile: const TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919812345678',
          email: 'trucker@example.com',
          verificationStatus: 'unverified',
          dlNumber: null,
          rating: 0,
          totalTrips: 0,
          completedTrips: 0,
          totalTrucks: 0,
          approvedTrucks: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification opened'), findsOneWidget);
  });

  testWidgets('blocked trucker chat readiness action opens fleet when verification is complete but no approved truck exists', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );

    await tester.pumpWidget(
      _buildRoutedApp(
        repository,
        truckerProfile: const TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919812345678',
          email: 'trucker@example.com',
          verificationStatus: 'verified',
          dlNumber: 'DL-0099',
          rating: 4.8,
          totalTrips: 20,
          completedTrips: 18,
          totalTrucks: 0,
          approvedTrucks: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open fleet'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet opened'), findsOneWidget);
  });

  testWidgets('chat menu report issue action opens report issue route with conversation context', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );
    ReportIssueContext? receivedContext;

    await tester.pumpWidget(
      _buildRoutedApp(
        repository,
        onReportIssue: (context) => receivedContext = context,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report spam or abuse'));
    await tester.pumpAndSettle();

    expect(find.text('Report issue opened'), findsOneWidget);
    expect(receivedContext, isNotNull);
    expect(receivedContext!.initialCategory, 'spam_or_scam');
    expect(receivedContext!.relatedLoadId, 'load-1');
    expect(receivedContext!.relatedTripId, 'trip-1');
    expect(receivedContext!.sourceLabel, 'Chat • Chandrapur, Maharashtra → Mumbai, Maharashtra');
  });

  testWidgets('unavailable conversation recovery action opens messages route', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: const <ConversationPreview>[],
      messages: const <ChatMessage>[],
    );

    await tester.pumpWidget(_buildRoutedApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Conversation unavailable'), findsOneWidget);
    expect(find.text('Back to messages'), findsOneWidget);

    await tester.tap(find.text('Back to messages'));
    await tester.pumpAndSettle();

    expect(find.text('Messages opened'), findsOneWidget);
  });

  testWidgets('renders richer supported non-text message types', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _typedMessage(
          id: 'voice-1',
          type: ChatMessageType.voice,
          structuredPayload: {'voice_duration_seconds': 12},
        ),
        _typedMessage(
          id: 'location-1',
          type: ChatMessageType.location,
          structuredPayload: {'label': 'Factory gate', 'lat': '19.0760', 'lng': '72.8777'},
        ),
        _typedMessage(
          id: 'document-1',
          type: ChatMessageType.document,
          attachmentPath: 'invoice.pdf',
        ),
        _typedMessage(
          id: 'map-1',
          type: ChatMessageType.mapCard,
          structuredPayload: {
            'route_label': 'Chandrapur → Mumbai',
            'material': 'Coal',
            'weight_label': '25T',
            'price_label': '₹62,500',
            'trip_cost_label': '₹15,200',
          },
        ),
        _typedMessage(
          id: 'truck-1',
          type: ChatMessageType.truckCard,
          structuredPayload: {
            'truck_display_label': 'MH12AB1234 • Tata Ace Gold',
            'body_type': 'Open body',
            'tyres': '6',
          },
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);
    expect(find.text('Factory gate'), findsOneWidget);
    expect(find.text('invoice.pdf'), findsOneWidget);
    expect(find.text('Chandrapur → Mumbai'), findsOneWidget);
    expect(find.text('Coal • 25T • ₹62,500 • ₹15,200'), findsOneWidget);
    expect(find.text('MH12AB1234 • Tata Ace Gold'), findsOneWidget);
    expect(find.text('Open body • 6 tyres'), findsOneWidget);
  });

  testWidgets('toggles voice recording and sends voice message on second tap', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );
    final voiceService = _FakeVoiceMessageService();

    await tester.pumpWidget(_buildApp(repository, voiceMessageService: voiceService));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voice recording'));
    await tester.pump();

    expect(voiceService.startCalls, 1);
    expect(find.byTooltip('Stop recording'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop recording'));
    await tester.pumpAndSettle();

    expect(voiceService.stopCalls, 1);
    expect(repository.lastSentConversationId, 'conversation-1');
  });

  testWidgets('shows sanitized voice-start failure copy', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _message(id: 'message-1', textBody: 'Need update', isFromCurrentUser: false),
      ],
    );
    final voiceService = _FakeVoiceMessageService()
      ..startResult = const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail'));

    await tester.pumpWidget(_buildApp(repository, voiceMessageService: voiceService));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voice recording'));
    await tester.pumpAndSettle();

    expect(find.text('We could not start voice recording right now. Retry shortly from this chat.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('plays and pauses a voice message bubble with signed playback url', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _typedMessage(
          id: 'voice-1',
          type: ChatMessageType.voice,
          attachmentPath: 'conversation-1/test-voice.m4a',
          structuredPayload: {'voice_duration_seconds': 12},
        ),
      ],
    );
    final playbackService = _FakeVoicePlaybackService();
    final playbackController = _FakeVoicePlaybackController();

    await tester.pumpWidget(
      _buildApp(
        repository,
        voicePlaybackService: playbackService,
        voicePlaybackController: playbackController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play voice message'));
    await tester.pump();

    expect(playbackService.signedUrlCalls, 1);
    expect(playbackController.toggleCalls, 1);
    expect(playbackController.lastUrl, 'https://example.com/test-voice.m4a');
    expect(find.byTooltip('Pause voice message'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause voice message'));
    await tester.pump();

    expect(playbackService.signedUrlCalls, 1);
    expect(playbackController.toggleCalls, 2);
    expect(find.byTooltip('Play voice message'), findsOneWidget);
  });

  testWidgets('shows unavailable copy when voice playback signed url cannot be created', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _typedMessage(
          id: 'voice-1',
          type: ChatMessageType.voice,
          attachmentPath: 'conversation-1/test-voice.m4a',
          structuredPayload: {'voice_duration_seconds': 12},
        ),
      ],
    );
    final playbackService = _FakeVoicePlaybackService()
      ..signedUrl = null;
    final playbackController = _FakeVoicePlaybackController();

    await tester.pumpWidget(
      _buildApp(
        repository,
        voicePlaybackService: playbackService,
        voicePlaybackController: playbackController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play voice message'));
    await tester.pumpAndSettle();

    expect(playbackService.signedUrlCalls, 1);
    expect(playbackController.toggleCalls, 0);
    expect(find.text('Voice playback is unavailable right now.'), findsOneWidget);
  });

  testWidgets('shows playback failure copy when voice playback controller throws', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _typedMessage(
          id: 'voice-1',
          type: ChatMessageType.voice,
          attachmentPath: 'conversation-1/test-voice.m4a',
          structuredPayload: {'voice_duration_seconds': 12},
        ),
      ],
    );
    final playbackService = _FakeVoicePlaybackService();
    final playbackController = _FakeVoicePlaybackController()
      ..toggleError = StateError('Playback failed');

    await tester.pumpWidget(
      _buildApp(
        repository,
        voicePlaybackService: playbackService,
        voicePlaybackController: playbackController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play voice message'));
    await tester.pumpAndSettle();

    expect(playbackService.signedUrlCalls, 1);
    expect(find.text('We could not play this voice message right now.'), findsOneWidget);
  });

  testWidgets('derives map card trip cost from distance and diesel price payload fields', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _typedMessage(
          id: 'map-raw-1',
          type: ChatMessageType.mapCard,
          structuredPayload: {
            'route_label': 'Chandrapur → Mumbai',
            'material': 'Coal',
            'weight_tonnes': 25,
            'price_amount': 62500,
            'route_distance_km': 300,
            'origin_state': 'Maharashtra',
          },
        ),
      ],
    );

    await tester.pumpWidget(
      _buildApp(
        repository,
        dieselPriceMap: const <String, double>{'maharashtra': 92},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coal • 25T • ₹62,500 • ₹12,440'), findsOneWidget);
  });

  testWidgets('opens load detail when map card view route is tapped', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    final repository = _FakeChatRepository(
      conversations: <ConversationPreview>[_conversation()],
      messages: <ChatMessage>[
        _typedMessage(
          id: 'map-route-1',
          type: ChatMessageType.mapCard,
          structuredPayload: {
            'load_id': 'load-1',
            'route_label': 'Chandrapur → Mumbai',
            'material': 'Coal',
            'weight_tonnes': 25,
            'price_amount': 62500,
          },
        ),
      ],
    );

    await tester.pumpWidget(_buildRoutedApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View route'));
    await tester.pumpAndSettle();

    expect(find.text('Load load-1'), findsOneWidget);
  });
}
