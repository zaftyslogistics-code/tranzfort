import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/communication/providers/chat_providers.dart';
import 'package:tranzfort/src/features/shell/presentation/shell_destinations.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _NoopChatBackend implements ChatBackend {
  const _NoopChatBackend();

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async => const <Map<String, dynamic>>[];

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) => const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async => const <Map<String, dynamic>>[];

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) => const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async => null;

  @override
  Future<bool> fetchHasUnread({required String conversationId, required String currentUserId}) async => false;

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({required String loadId, required String truckerId}) async => null;

  @override
  Future<String> createOrGetConversation({required String supplierId, required String truckerId, required String loadId}) async => 'conversation-1';

  @override
  Future<String> sendMessage({required String conversationId, required ChatMessageType type, String? messageId, String? textBody, String? attachmentPath, Map<String, dynamic>? structuredPayload}) async => 'message-1';

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async {}

  @override
  Future<int> fetchUnreadConversationCount() async => 0;
}

class _TestInboxController extends InboxController {
  _TestInboxController(this._initialState)
      : super(
          ChatRepository(
            const _NoopChatBackend(),
            () => 'profile-1',
            () => AppUserRole.supplier,
          ),
        ) {
    state = _initialState;
  }

  final InboxState _initialState;

  @override
  Future<void> load() async {}
}

ConversationPreview _conversation({
  required String id,
  required String loadId,
  required String routeLabel,
  required String truckerName,
  required String supplierName,
  String? supplierCompanyName,
  String? truckDisplayLabel,
  String? bookingStatusLabel,
  String? bookingRequestId,
  String latestMessagePreview = 'Latest update',
  bool hasUnread = false,
}) {
  return ConversationPreview(
    id: id,
    supplierId: 'supplier-1',
    truckerId: 'trucker-1',
    loadId: loadId,
    tripId: 'trip-1',
    routeLabel: routeLabel,
    loadMaterial: 'Coal',
    loadPriceAmount: 62500,
    loadStatusLabel: 'active',
    pickupDate: DateTime(2026, 3, 11),
    supplierName: supplierName,
    supplierMobile: '+919876543210',
    supplierCompanyName: supplierCompanyName,
    truckerName: truckerName,
    truckerMobile: '+919812345678',
    truckDisplayLabel: truckDisplayLabel,
    bookingRequestId: bookingRequestId,
    bookingStatusLabel: bookingStatusLabel,
    latestMessagePreview: latestMessagePreview,
    lastMessageAt: DateTime(2026, 3, 10, 9),
    hasUnread: hasUnread,
    isArchived: false,
    createdAt: DateTime(2026, 3, 10, 8),
  );
}

Widget _buildApp({
  required AppUserRole role,
  required InboxState inboxState,
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
      inboxProvider.overrideWith((ref) => _TestInboxController(inboxState)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MessagesScreen()),
    ),
  );
}

Widget _buildRoutedApp({
  required AppUserRole role,
  required InboxState inboxState,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: MessagesScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.chatPath}/:conversationId',
        builder: (context, state) => Scaffold(
          body: Text('Chat ${state.pathParameters['conversationId'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads opened')),
      ),
      GoRoute(
        path: AppRoutes.findLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('Find loads opened')),
      ),
    ],
  );

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
      inboxProvider.overrideWith((ref) => _TestInboxController(inboxState)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('renders supplier grouped messages inbox', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[
            _conversation(
              id: 'conversation-1',
              loadId: 'load-1',
              routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
              truckerName: 'Ravi Trucker',
              supplierName: 'Amit Supplier',
              truckDisplayLabel: 'MH12AB1234 - Tata Ace Gold',
              bookingRequestId: 'booking-1',
              bookingStatusLabel: 'approved',
              latestMessagePreview: 'Truck reached destination',
              hasUnread: true,
            ),
            _conversation(
              id: 'conversation-2',
              loadId: 'load-1',
              routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
              truckerName: 'Suresh Trucker',
              supplierName: 'Amit Supplier',
              truckDisplayLabel: 'MH14CD5678 - Eicher Pro 6025',
              bookingRequestId: 'booking-2',
              bookingStatusLabel: 'submitted',
              latestMessagePreview: 'Waiting at gate',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Grouped inbox'), findsOneWidget);
    expect(find.textContaining('2 active conversations'), findsOneWidget);
    await tester.tap(find.textContaining('2 active conversations'));
    await tester.pumpAndSettle();
    expect(find.text('Ravi Trucker'), findsOneWidget);
    expect(find.text('Suresh Trucker'), findsOneWidget);
    expect(find.text('MH12AB1234 - Tata Ace Gold'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
  });

  testWidgets('supplier grouped inbox falls back to unknown for unsupported booking status', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[
            _conversation(
              id: 'conversation-1',
              loadId: 'load-1',
              routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
              truckerName: 'Ravi Trucker',
              supplierName: 'Amit Supplier',
              truckDisplayLabel: 'MH12AB1234 - Tata Ace Gold',
              bookingRequestId: 'booking-1',
              bookingStatusLabel: 'needs_manual_review',
              latestMessagePreview: 'Truck reached destination',
              hasUnread: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('1 active conversations'));
    await tester.pumpAndSettle();

    expect(find.text('UNKNOWN'), findsOneWidget);
    expect(find.text('NEEDS MANUAL REVIEW'), findsNothing);
  });

  testWidgets('renders trucker flat messages inbox', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[
            _conversation(
              id: 'conversation-1',
              loadId: 'load-1',
              routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
              truckerName: 'Ravi Trucker',
              supplierName: 'Amit Supplier',
              supplierCompanyName: 'Amit Logistics',
              latestMessagePreview: 'Report after unloading',
              hasUnread: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flat inbox'), findsOneWidget);
    expect(find.textContaining('Amit Supplier - Amit Logistics'), findsOneWidget);
    expect(find.textContaining('Report after unloading'), findsOneWidget);
  });

  testWidgets('supplier grouped inbox conversation opens chat route', (tester) async {
    await tester.pumpWidget(
      _buildRoutedApp(
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[
            _conversation(
              id: 'conversation-1',
              loadId: 'load-1',
              routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
              truckerName: 'Ravi Trucker',
              supplierName: 'Amit Supplier',
              truckDisplayLabel: 'MH12AB1234 - Tata Ace Gold',
              bookingRequestId: 'booking-1',
              bookingStatusLabel: 'approved',
              latestMessagePreview: 'Truck reached destination',
              hasUnread: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('1 active conversation'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ravi Trucker'));
    await tester.pumpAndSettle();

    expect(find.text('Chat conversation-1'), findsOneWidget);
  });

  testWidgets('trucker flat inbox conversation opens chat route', (tester) async {
    await tester.pumpWidget(
      _buildRoutedApp(
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[
            _conversation(
              id: 'conversation-1',
              loadId: 'load-1',
              routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
              truckerName: 'Ravi Trucker',
              supplierName: 'Amit Supplier',
              supplierCompanyName: 'Amit Logistics',
              latestMessagePreview: 'Report after unloading',
              hasUnread: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Amit Supplier - Amit Logistics'));
    await tester.pumpAndSettle();

    expect(find.text('Chat conversation-1'), findsOneWidget);
  });

  testWidgets('renders messages empty state', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('supplier empty messages state opens my loads route', (tester) async {
    await tester.pumpWidget(
      _buildRoutedApp(
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open my loads'), findsOneWidget);

    await tester.tap(find.text('Open my loads'));
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });

  testWidgets('trucker empty messages state opens find loads route', (tester) async {
    await tester.pumpWidget(
      _buildRoutedApp(
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find loads'), findsOneWidget);

    await tester.tap(find.text('Find loads'));
    await tester.pumpAndSettle();

    expect(find.text('Find loads opened'), findsOneWidget);
  });

  testWidgets('renders sanitized messages failure copy', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
          failure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load messages'), findsOneWidget);
    expect(
      find.text('We could not load your messages right now. Retry shortly to refresh the latest conversations.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });
}
