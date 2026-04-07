import 'package:flutter_test/flutter_test.dart';
import 'package:app/src/features/bot/models/bot_intent.dart';
import 'package:app/src/features/bot/services/conversation_state.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:app/src/features/bot/services/entity_extractor.dart';
import 'package:app/src/features/bot/services/basic_bot_service.dart';
import 'package:app/src/core/services/tts_service.dart';

class _TestTtsService implements TtsService {
  final List<String> spoken = [];
  
  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
  
  @override
  Future<void> stop() async {}

  @override
  Future<void> previewVoice(String text) async {
    spoken.add(text);
  }
}

class _MockAppLocalizations implements AppLocalizations {
  @override
  String get botCancelResponse => 'Thik hai, main process cancel kar raha hoon. Aur kuch?';
  @override
  String get botMyLoadsResponse => 'Aapke loads yahan hain.';
  @override
  String get botViewLoadsAction => 'View Loads';
  @override
  String get botMyTripsResponse => 'Aapke trips yahan hain.';
  @override
  String get botViewTripsAction => 'View Trips';
  @override
  String get botCheckStatusResponse => 'Aapki booking status yahan check karein.';
  @override
  String get botCheckStatusAction => 'Check Status';
  @override
  String get botHelpResponse => 'Main aapki load dhundhne, post karne aur trips check karne me madad kar sakta hoon. Boliye "load dhundho".';
  @override
  String get botGreetingResponse => 'Namaste! Main TranZfort bot hoon. Bataiye, aaj main aapki kya madad kar sakta hoon?';
  @override
  String get botUnknownResponse => 'Main samajh nahi paaya. Aap "load dhundho", "load dalna hai", ya "trip status" bol sakte hain.';
  @override
  String get botAskOrigin => 'Kahan se? (Origin city batayein)';
  @override
  String get botAskDestination => 'Kahan tak? (Destination city batayein)';
  @override
  String botFindLoadSummary(String origin, String dest) => '$origin se $dest ke liye loads dhundh raha hoon. Dekhein?';
  @override
  String get botAskPostOrigin => 'Kahan se load bhejenge?';
  @override
  String get botAskPostDestination => 'Kahan bhejna hai?';
  @override
  String get botAskPostMaterial => 'Kaunsa material bhejna hai? (Jaise: Coal, Steel)';
  @override
  String botPostLoadSummary(String mat, String origin, String dest) => '$mat ko $origin se $dest bhejne ke liye load post karein?';
  @override
  String get postLoadAction => 'Post Load';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ConversationState copyWith', () {
    test('updates intent, slots, and processing flags', () {
      const initial = ConversationState();

      final updated = initial.copyWith(
        currentIntent: BotIntent.findLoad,
        slots: const {'origin': 'Mumbai'},
        isProcessing: true,
      );

      expect(updated.currentIntent, BotIntent.findLoad);
      expect(updated.slots['origin'], 'Mumbai');
      expect(updated.isProcessing, isTrue);
    });

    test('clears active slot when requested', () {
      const initial = ConversationState(activeSlotKey: 'origin');

      final cleared = initial.copyWith(clearActiveSlot: true);

      expect(cleared.activeSlotKey, isNull);
    });
  });

  group('BotChatNotifier behavior', () {
    test('addMessage appends user message with timestamp', () {
      final notifier = BotChatNotifier();

      notifier.addMessage('Hello', isUser: true);

      expect(notifier.state.messages.length, 1);
      final message = notifier.state.messages.first;
      expect(message['text'], 'Hello');
      expect(message['is_user'], isTrue);
      expect(message['timestamp'], isNotNull);
    });

    test('addActionMessage includes route and label', () {
      final notifier = BotChatNotifier();

      notifier.addActionMessage('View Loads', '/my-loads', 'Open');

      final message = notifier.state.messages.single;
      expect(message['action_route'], '/my-loads');
      expect(message['action_label'], 'Open');
    });

    test('clearSlots resets intent and slots', () {
      final notifier = BotChatNotifier();
      notifier.updateSlot('origin', 'Mumbai');
      notifier.setIntent(BotIntent.postLoad);

      notifier.clearSlots();

      expect(notifier.state.slots, isEmpty);
      expect(notifier.state.currentIntent, BotIntent.unknown);
      expect(notifier.state.activeSlotKey, isNull);
    });
  });

  group('EntityExtractor.determineIntent', () {
    test('detects core intents from text', () {
      expect(
        EntityExtractor.determineIntent('load dhundho'),
        BotIntent.findLoad,
      );
      expect(
        EntityExtractor.determineIntent('naya load dalna hai'),
        BotIntent.postLoad,
      );
      expect(EntityExtractor.determineIntent('meri trips'), BotIntent.myTrips);
      expect(EntityExtractor.determineIntent('help'), BotIntent.help);
    });

    test('defaults to unknown for unrelated input', () {
      expect(EntityExtractor.determineIntent('random text'), BotIntent.unknown);
    });
  });

  group('EntityExtractor parsing helpers', () {
    test('extractCity matches from catalog', () {
      final city = EntityExtractor.extractCity(
        'Truck from Mumbai to Pune',
        const ['Mumbai', 'Pune'],
      );

      expect(city, 'Mumbai');
    });

    test('extractMaterial picks known materials', () {
      expect(EntityExtractor.extractMaterial('steel rods'), 'steel');
      expect(EntityExtractor.extractMaterial('coal shipment'), 'coal');
      expect(EntityExtractor.extractMaterial('unknown material'), isNull);
    });

    test('extractWeight parses tonnage', () {
      expect(EntityExtractor.extractWeight('12 ton'), 12);
      expect(EntityExtractor.extractWeight('2.5 tonnes'), 2.5);
      expect(EntityExtractor.extractWeight('no weight'), isNull);
    });

    test('extractPrice handles lakh, thousand, and exact formats', () {
      expect(EntityExtractor.extractPrice('1.5 lakh'), 150000);
      expect(EntityExtractor.extractPrice('50k'), 50000);
      expect(EntityExtractor.extractPrice('₹ 120000'), 120000);
      expect(EntityExtractor.extractPrice('no price'), isNull);
    });
  });

  group('BasicBotService action paths', () {
    test('responds with simple text', () async {
      final notifier = BotChatNotifier();
      final tts = _TestTtsService();
      final service = BasicBotService(notifier, tts);
      final mockL10n = _MockAppLocalizations();
      
      await service.handleInput('namaste', notifier.state, mockL10n);
      
      expect(notifier.state.messages, isNotEmpty);
      expect(notifier.state.messages.last['is_user'], false);
      expect(tts.spoken, isNotEmpty);
    });

    test('can cancel flow', () async {
      final notifier = BotChatNotifier();
      final tts = _TestTtsService();
      final service = BasicBotService(notifier, tts);
      final mockL10n = _MockAppLocalizations();
      
      await service.handleInput('cancel', notifier.state, mockL10n);
      
      expect(notifier.state.activeSlotKey, null);
      expect(notifier.state.slots, isEmpty);
    });
  });

  group('Slot filling integration', () {
    late _TestTtsService mockTts;
    late BotChatNotifier notifier;
    late _MockAppLocalizations mockL10n;

    setUp(() {
      notifier = BotChatNotifier();
      mockTts = _TestTtsService();
      mockL10n = _MockAppLocalizations();
    });

    test('starts find load and asks origin', () async {
      final service = BasicBotService(notifier, mockTts);
      
      await service.handleInput('load dhundho', notifier.state, mockL10n);
      
      expect(notifier.state.currentIntent, BotIntent.findLoad);
      expect(notifier.state.activeSlotKey, 'origin');
    });

    test('updates slots based on activeSlotKey', () async {
      notifier.setIntent(BotIntent.findLoad);
      notifier.setActiveSlot('origin');
      final service = BasicBotService(notifier, mockTts);
      
      await service.handleInput('Pune', notifier.state, mockL10n);
      
      expect(notifier.state.slots['origin'], 'Pune');
    });

    test('navigates when all slots filled', () async {
      notifier.setIntent(BotIntent.findLoad);
      notifier.updateSlot('origin', 'Pune');
      notifier.updateSlot('dest', 'Mumbai');

      final service = BasicBotService(notifier, mockTts);
      
      await service.handleInput('chalo dekhte hain', notifier.state, mockL10n);
      
      final action = notifier.state.messages.last;
      expect(action['action_route'], '/find-loads');
      expect(mockTts.spoken.last, contains('loads dhundh')); 
    });

    test('completes post load flow after origin/dest/material inputs', () async {
      final notifier = BotChatNotifier();
      final tts = _TestTtsService();
      final service = BasicBotService(notifier, tts);
      final mockL10n = _MockAppLocalizations();

      await service.handleInput('load dalna hai', notifier.state, mockL10n);
      expect(notifier.state.activeSlotKey, 'origin');

      notifier.setIntent(BotIntent.postLoad);
      notifier.setActiveSlot('origin');
      await service.handleInput('Mumbai', notifier.state, mockL10n);
      expect(notifier.state.activeSlotKey, 'dest');

      notifier.setIntent(BotIntent.postLoad);
      notifier.setActiveSlot('dest');
      await service.handleInput('Pune', notifier.state, mockL10n);
      expect(notifier.state.activeSlotKey, 'material');

      notifier.setIntent(BotIntent.postLoad);
      notifier.setActiveSlot('material');
      await service.handleInput('coal', notifier.state, mockL10n);
      
      final action = notifier.state.messages.last;
      expect(action['action_route'], '/post-load');
    });  
  });
}
