import '../models/bot_intent.dart';
import 'conversation_state.dart';
import 'entity_extractor.dart';
import '../../../core/services/tts_service.dart';
import '../../../l10n/app_localizations.dart';

class BasicBotService {
  final BotChatNotifier _notifier;
  final TtsService _tts;

  BasicBotService(this._notifier, this._tts);

  Future<void> handleInput(
    String input,
    ConversationState state,
    AppLocalizations l10n,
  ) async {
    _notifier.setProcessing(true);
    _notifier.addMessage(input, isUser: true);

    // Simulate slight processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (input.toLowerCase().contains('cancel') ||
        input.toLowerCase().contains('rehne do')) {
      _notifier.clearSlots();
      _respond(l10n.botCancelResponse);
      return;
    }

    BotIntent intent = state.currentIntent;

    if (intent == BotIntent.unknown) {
      intent = EntityExtractor.determineIntent(input);
      _notifier.setIntent(intent);
    }

    switch (intent) {
      case BotIntent.findLoad:
        await _handleFindLoad(input, state, l10n);
        break;
      case BotIntent.postLoad:
        await _handlePostLoad(input, state, l10n);
        break;
      case BotIntent.myLoads:
        _respondWithAction(
          l10n.botMyLoadsResponse,
          '/my-loads',
          l10n.botViewLoadsAction,
        );
        _notifier.clearSlots();
        break;
      case BotIntent.myTrips:
        _respondWithAction(
          l10n.botMyTripsResponse,
          '/my-trips',
          l10n.botViewTripsAction,
        );
        _notifier.clearSlots();
        break;
      case BotIntent.checkStatus:
        _respondWithAction(
          l10n.botCheckStatusResponse,
          '/my-trips',
          l10n.botCheckStatusAction,
        );
        _notifier.clearSlots();
        break;
      case BotIntent.help:
        _respond(l10n.botHelpResponse);
        _notifier.clearSlots();
        break;
      case BotIntent.greeting:
        _respond(l10n.botGreetingResponse);
        _notifier.clearSlots();
        break;
      case BotIntent.unknown:
        _respond(l10n.botUnknownResponse);
        break;
    }

    _notifier.setProcessing(false);
  }

  Future<void> _handleFindLoad(
    String input,
    ConversationState _,
    AppLocalizations l10n,
  ) async {
    final state = _notifier.currentState;
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

    final updatedState = _notifier.currentState;

    if (origin == null && updatedState.activeSlotKey == null) {
      _notifier.setActiveSlot('origin');
      _respond(l10n.botAskOrigin);
      return;
    }

    if (dest == null && updatedState.activeSlotKey == null) {
      _notifier.setActiveSlot('dest');
      _respond(l10n.botAskDestination);
      return;
    }

    if (origin != null && dest != null) {
      _respondWithAction(
        l10n.botFindLoadSummary(origin, dest),
        '/find-loads',
        l10n.botViewLoadsAction,
      );
      _notifier.clearSlots();
    }
  }

  Future<void> _handlePostLoad(
    String input,
    ConversationState _,
    AppLocalizations l10n,
  ) async {
    final state = _notifier.currentState;
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

    final updatedState = _notifier.currentState;

    if (origin == null && updatedState.activeSlotKey == null) {
      _notifier.setActiveSlot('origin');
      _respond(l10n.botAskPostOrigin);
      return;
    }

    if (dest == null && updatedState.activeSlotKey == null) {
      _notifier.setActiveSlot('dest');
      _respond(l10n.botAskPostDestination);
      return;
    }

    if (mat == null && updatedState.activeSlotKey == null) {
      _notifier.setActiveSlot('material');
      _respond(l10n.botAskPostMaterial);
      return;
    }

    if (origin != null && dest != null && mat != null) {
      _respondWithAction(
        l10n.botPostLoadSummary(mat, origin, dest),
        '/post-load',
        l10n.postLoadAction,
      );
      _notifier.clearSlots();
    }
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
