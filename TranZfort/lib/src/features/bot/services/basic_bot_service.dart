import '../models/bot_intent.dart';
import 'conversation_state.dart';
import 'entity_extractor.dart';
import '../../../core/services/tts_service.dart';

class BasicBotService {
  final BotChatNotifier _notifier;
  final TtsService _tts;

  BasicBotService(this._notifier, this._tts);

  Future<void> handleInput(String input, ConversationState state) async {
    _notifier.setProcessing(true);
    _notifier.addMessage(input, isUser: true);
    
    // Simulate slight processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (input.toLowerCase().contains('cancel') || input.toLowerCase().contains('rehne do')) {
      _notifier.clearSlots();
      _respond('Thik hai, main process cancel kar raha hoon. Aur kuch?');
      return;
    }

    BotIntent intent = state.currentIntent;
    
    if (intent == BotIntent.unknown) {
      intent = EntityExtractor.determineIntent(input);
      _notifier.setIntent(intent);
    }

    switch (intent) {
      case BotIntent.findLoad:
        await _handleFindLoad(input, state);
        break;
      case BotIntent.postLoad:
        await _handlePostLoad(input, state);
        break;
      case BotIntent.myLoads:
        _respondWithAction('Aapke loads yahan hain.', '/my-loads', 'View Loads');
        _notifier.clearSlots();
        break;
      case BotIntent.myTrips:
        _respondWithAction('Aapke trips yahan hain.', '/my-trips', 'View Trips');
        _notifier.clearSlots();
        break;
      case BotIntent.checkStatus:
        _respondWithAction('Aapki booking status yahan check karein.', '/my-trips', 'Check Status');
        _notifier.clearSlots();
        break;
      case BotIntent.help:
        _respond('Main aapki load dhundhne, post karne aur trips check karne me madad kar sakta hoon. Boliye "load dhundho".');
        _notifier.clearSlots();
        break;
      case BotIntent.greeting:
        _respond('Namaste! Main TranZfort bot hoon. Bataiye, aaj main aapki kya madad kar sakta hoon?');
        _notifier.clearSlots();
        break;
      case BotIntent.unknown:
        _respond('Main samajh nahi paaya. Aap "load dhundho", "load dalna hai", ya "trip status" bol sakte hain.');
        break;
    }

    _notifier.setProcessing(false);
  }

  Future<void> _handleFindLoad(String input, ConversationState state) async {
    var origin = state.slots['origin'] as String?;
    var dest = state.slots['dest'] as String?;

    if (state.activeSlotKey == 'origin') {
      // Very basic extraction, assume the whole input is the city if not a known trigger
      origin = input;
      _notifier.updateSlot('origin', origin);
      _notifier.setActiveSlot('');
    } else if (state.activeSlotKey == 'dest') {
      dest = input;
      _notifier.updateSlot('dest', dest);
      _notifier.setActiveSlot('');
    }

    if (origin == null) {
      _notifier.setActiveSlot('origin');
      _respond('Kahan se? (Origin city batayein)');
      return;
    }

    if (dest == null) {
      _notifier.setActiveSlot('dest');
      _respond('Kahan tak? (Destination city batayein)');
      return;
    }

    _respondWithAction(
      '$origin se $dest ke liye loads dhundh raha hoon. Dekhein?', 
      '/find-loads', 
      'View Loads',
    );
    _notifier.clearSlots();
  }

  Future<void> _handlePostLoad(String input, ConversationState state) async {
    var origin = state.slots['origin'] as String?;
    var dest = state.slots['dest'] as String?;
    var mat = state.slots['material'] as String?;
    
    if (state.activeSlotKey == 'origin') {
      origin = input;
      _notifier.updateSlot('origin', origin);
      _notifier.setActiveSlot('');
    } else if (state.activeSlotKey == 'dest') {
      dest = input;
      _notifier.updateSlot('dest', dest);
      _notifier.setActiveSlot('');
    } else if (state.activeSlotKey == 'material') {
      mat = EntityExtractor.extractMaterial(input) ?? input;
      _notifier.updateSlot('material', mat);
      _notifier.setActiveSlot('');
    }

    if (origin == null) {
      _notifier.setActiveSlot('origin');
      _respond('Kahan se load bhejenge?');
      return;
    }

    if (dest == null) {
      _notifier.setActiveSlot('dest');
      _respond('Kahan bhejna hai?');
      return;
    }

    if (mat == null) {
      _notifier.setActiveSlot('material');
      _respond('Kaunsa material bhejna hai? (Jaise: Coal, Steel)');
      return;
    }

    _respondWithAction(
      '$mat ko $origin se $dest bhejne ke liye load post karein?', 
      '/post-load', 
      'Post Load',
    );
    _notifier.clearSlots();
  }

  void _respond(String text) {
    _notifier.addMessage(text, isUser: false);
    _tts.speak(text);
  }

  void _respondWithAction(String text, String route, String label) {
    _notifier.setProcessing(false);
    _notifier.addActionMessage(text, route, label);
    _tts.speak(text);
  }
}
