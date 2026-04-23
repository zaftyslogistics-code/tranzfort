---
title: Bot Feature - Brainstorm & Implementation Plan
date: April 22, 2026
version: 1.0
purpose: Comprehensive review of deferred bot feature, existing infrastructure, and proposed implementation roadmap
status: DEFERRED

# Bot Feature - Brainstorm & Implementation Plan

> **⚠️ STATUS: DEFERRED (April 22, 2026)**
>
> This bot integration plan is deferred due to AI integration being rolled back.
>
> **Decision:** Bot integration deferred until AI assistant is successfully implemented.
> **Reason:** AI assistant (which bot depends on) was rolled back due to inference time and quality issues.
> **Future Plan:** Bot integration will be revisited after AI assistant is successfully implemented with a different approach.
>
> **Infrastructure Retained:** TTS, STT, and city search services remain available for non-AI use cases (accessibility, general functionality).
>
> See `TODO-22-april.md` for complete AI rollback details.

## 1. SITUATION SUMMARY

### Current State: INFRASTRUCTURE READY, BOT NOT BUILT

| Component | Status | File/Location |
|-----------|--------|--------------|
| **TTS Service** | ✅ Built | `lib/src/core/services/contextual_tts_service.dart` |
| **TTS State Provider** | ✅ Built | `lib/src/core/providers/tts_state_provider.dart` |
| **TTS Action Button** | ✅ Built | `lib/src/shared/widgets/tts_action_button.dart` |
| **STT Service** | ✅ Built | `lib/src/core/services/stt_service.dart` |
| **Offline City JSON** | ✅ Built | `assets/data/indian_cities.json` (7,000+ cities) |
| **City Search Service** | ✅ Built | `lib/src/features/trucker/data/trucker_city_search_service.dart` |
| **Bot Spec Document** | ✅ Locked | `docs/62-bot-intent-and-interaction-spec.md` |
| **Bot Phase Tracker** | ✅ Defined | `docs/TODO&Progress/phase-07-communication-chat-bot.md` P7.7 |
| **Bot Chat Screen** | ❌ NOT BUILT | Missing |
| **Bot Service (Intent Matching)** | ❌ NOT BUILT | Missing |
| **Bot Chat Provider** | ❌ NOT BUILT | Missing |
| **Bot Route** | ❌ NOT BUILT | Missing from router |

### Key Insight

**The hard infrastructure work is DONE.** TTS, STT, offline city database, and the locked bot spec are all in place. What remains is:
1. Building the conversational engine (intent matcher + slot filler)
2. Building the chat UI screen
3. Wiring up the providers and navigation
4. Testing the end-to-end flows

---

## 2. EXISTING INFRASTRUCTURE ANALYSIS

### 2.1 TTS (Text-to-Speech) - READY TO USE

**Service**: `ContextualTtsService`
- Language: Auto-detects `hi-IN` vs `en-IN` from app locale
- Speech rate: Fixed at `0.5` (normal Hindi pace)
- Queue: Sequential, no overlap
- Emoji stripping: Automatic (regex removes all emoji before speaking)
- Max length: 500 chars (auto-truncated at word boundary)
- Mute control: SharedPreferences `tts_muted` key
- Stop on navigate: TTS cancels when user leaves screen

**Provider**: `TtsPlaybackController`
- `.play(context, message)` - speaks a message, saves for replay
- `.stop()` - stops current speech
- Sets global `ttsSpeakingProvider` state for UI pulsing animation

**UI**: `TtsActionButton`
- Shows in app bar of key screens
- Pulsing animation when speaking
- Tap to stop / replay / mute toggle
- Tooltip adapts to state

**Usage for Bot**:
```dart
// Every bot response auto-spoken if TTS enabled
final controller = ref.read(ttsPlaybackControllerProvider);
await controller.play(context: context, message: botResponseText);
```

### 2.2 STT (Speech-to-Text) - READY TO USE

**Service**: `SttService`
- Engine: `speech_to_text` plugin
- Locale: Auto `hi_IN` / `en_IN` from language setting
- Timeout: 15 seconds silence auto-stop
- Partial results: Real-time transcription shown in input field
- Permission handling: Returns `SttStartOutcome` enum
- Error handling: `_lastErrorMessage` for recovery

**Usage for Bot**:
```dart
final stt = ref.read(sttServiceProvider);
final outcome = await stt.startListening(
  languageCode: 'hi',
  onPartialResult: (text) => updateInputField(text),
  onFinalResult: (text) => processUserMessage(text),
);
```

**Android Manifest Requirement** (already added):
```xml
<queries>
  <intent>
    <action android:name="android.speech.RecognitionService" />
  </intent>
</queries>
```

### 2.3 Offline City Database - READY TO USE

**Data**: `assets/data/indian_cities.json`
- ~7,000 Indian cities
- Fields: `name`, `district`, `state`, `lat`, `lng`
- Loaded via rootBundle on first search, then cached

**Service**: `TruckerCitySearchService`
- Searches Google Places API first (if key available)
- Falls back to offline JSON (contains search)
- Returns `TruckerCitySuggestion` with city, state, lat, lng, placeId, source

**Usage for Bot Entity Extraction**:
```dart
// Bot can reuse this service for city fuzzy matching
final cities = await citySearchService.searchCities(userInput);
// For fuzzy matching: Levenshtein distance ≤ 2
```

---

## 3. LOCKED BOT SPEC REVIEW (from docs/62)

### 3.1 Architecture Constraint

**V1 Rule**: Rule-based ONLY. No LLM or on-device AI in production path. LLM is an optional feature-flagged experiment only.

### 3.2 Screen Layout

```
AppBar: [←] TranZfort Bot      [🔄 New]
Body: Chat-style message list
      • Bot bubbles (left, light surface, 🤖 avatar)
      • User bubbles (right, brand primary tint)
      • Inline CTA buttons in bot bubbles
      • Typing indicator (animated dots)
Input: [Text field __________] [🎤 Mic]
```

### 3.3 7 Locked Intents

| # | Intent | Trigger (Hindi) | Trigger (English) | Slots | Action |
|---|--------|-----------------|-------------------|-------|--------|
| 1 | `findLoad` | "load dhundho", "load chahiye" | "find load", "search load" | origin, destination | Navigate to find-loads with filters |
| 2 | `postLoad` | "load dalna hai", "naya load" | "post load", "new load" | origin, destination, material, weight, price | Create load via RPC or navigate to form |
| 3 | `myLoads` | "meri loads" | "my loads" | None | Navigate to /my-loads |
| 4 | `myTrips` | "meri trips", "trip status" | "my trips", "trip status" | None | Navigate to trips screen |
| 5 | `checkStatus` | "booking ka status", "kya hua" | "check status", "what happened" | None | Query latest trip, report status |
| 6 | `help` | "madad", "kya kar sakte ho" | "help", "what can you do" | None | Show command list |
| 7 | `greeting` | "namaste", "hello" | "hello", "hi" | None | Context-aware greeting |

### 3.4 Slot-Filling Flow: findLoad

```
User: "Load dhundho Chandrapur se Mumbai"
Bot:  "Chandrapur se Mumbai ke liye 15 loads mile. Dekhein?"
      [View Loads →]

User: "Load dhundho"
Bot:  "Kahan se? (Origin city batayein)"
User: "Chandrapur"
Bot:  "Kahan tak? (Destination city batayein)"
User: "Mumbai"
Bot:  "Chandrapur se Mumbai ke liye 15 loads mile. Dekhein?"
      [View Loads →]
```

**Navigation Action**: `GoRouter.push('/find-loads?origin={origin}&dest={destination}')`

### 3.5 Slot-Filling Flow: postLoad (5 questions)

```
User: "Load dalna hai"
Bot:  "Kahan se?"           → captures origin
Bot:  "Kahan tak?"          → captures destination  
Bot:  "Kya material hai?"   → captures material
Bot:  "Kitna weight hai?"   → captures weight (tonnes)
Bot:  "Kitna price hai?"    → captures price (₹)
Bot:  "Summary + smart defaults"
      [Post Load] [More Options]
```

**Smart Defaults**:
- `price_type = negotiable`
- `advance = 80%`
- `truck_type = Any`
- `tyres = Any`
- `pickup_date = tomorrow`
- `trucks_needed = 1`

### 3.6 Entity Extraction Rules

**City Extraction**:
- Primary: `indian_cities.json` offline match
- Fuzzy: Levenshtein distance ≤ 2 ("Chandrapor" → "Chandrapur")
- Fallback: Google Places API (if online)
- Failure: "'{input}' city nahi mili. Dubara try karein."

**Material Extraction**:
- Match against: Coal, Steel, Cement, Iron Ore, Limestone, Sand, Grain, Rice, Wheat, Sugar, Fertilizer, Cotton, Timber, Chemicals, Petroleum, Other
- Hindi equivalents: "koyla" → Coal, "chawal" → Rice

**Price Extraction**:
- "62500" → ₹62,500
- "62.5k" → ₹62,500
- "1 lakh" → ₹1,00,000
- "1.5 lakh" → ₹1,50,000

**Weight Extraction**:
- "25 ton" → 25 tonnes
- "25T" → 25 tonnes
- "25 metric ton" → 25 tonnes

### 3.7 Error Recovery (8 Scenarios)

| Situation | Hindi Response | English Response |
|-----------|---------------|----------------|
| Unrecognized intent | "Main samajh nahi paaya..." | "I didn't understand..." |
| City not found | "'{input}' city nahi mili..." | "City '{input}' not found..." |
| Material not found | "'{input}' material nahi mila..." | "Material '{input}' not recognized..." |
| Invalid price/weight | "Sahi number dalein..." | "Please enter a valid number..." |
| User says cancel | "Theek hai, cancel kar diya." | "OK, cancelled." |
| User corrects slot | Re-ask specific slot | Re-ask specific slot |
| Empty search results | "Koi load nahi mila..." | "No loads found..." |
| Network error | "Abhi search nahi ho pa raha..." | "Search failed..." |

### 3.8 Bot Entry Points (Locked)

- ✅ Dashboard quick action (both roles) - ALREADY EXISTS as placeholder
- ✅ Drawer utility section - ALREADY EXISTS
- ❌ Must NOT appear on Find Loads feed (would reduce content area)

### 3.9 TTS/STT Integration for Bot

**TTS Rules**:
- Every bot response auto-spoken if TTS enabled
- Language follows app setting (`hi-IN` / `en-IN`)
- Speech rate: 0.5
- Emoji stripped before TTS
- Queue: No overlap
- Cancel on navigate away
- Max 500 chars

**STT Rules**:
- Tap mic → start listening
- Tap again → stop
- `localeId: 'hi_IN'` or `'en_IN'`
- Auto-stop after 15s silence
- Partial results shown in input field
- If RECORD_AUDIO denied → show permission dialog, fallback to text

---

## 4. WHAT'S MISSING - GAP ANALYSIS

### 4.1 Missing Code Components

| # | Component | Priority | Estimated Lines |
|---|-----------|----------|-----------------|
| 1 | **BotService** (intent matcher + entity extractor) | 🔴 Critical | ~400 lines |
| 2 | **BotChatProvider** (conversation state + slot filling) | 🔴 Critical | ~300 lines |
| 3 | **BotChatScreen** (UI with chat bubbles + input + mic) | 🔴 Critical | ~350 lines |
| 4 | **Bot Route** in app_router.dart | 🔴 Critical | ~10 lines |
| 5 | **BotMessage models** (BotMessage, BotIntent, SlotState) | 🟡 High | ~100 lines |
| 6 | **Bot entry point buttons** (dashboard + drawer) | 🟡 High | ~50 lines |
| 7 | **Tests** (intent matching, slot filling, entity extraction) | 🟡 High | ~200 lines |
| 8 | **Bot error recovery widget** | 🟢 Medium | ~80 lines |

**Total New Code**: ~1,500 lines (manageable, well within team capacity)

### 4.2 Missing Data Assets

| Asset | Status | Action |
|-------|--------|--------|
| Material name mapping (Hindi ↔ English) | ❌ Missing | Need to create `assets/data/material_names.json` |
| Price regex patterns ("lakh", "k", etc.) | ❌ Missing | Hardcode in entity extractor |
| Weight regex patterns ("ton", "tonne", "T") | ❌ Missing | Hardcode in entity extractor |
| Intent trigger phrases list | ⚠️ In spec only | Need to code into BotService |

### 4.3 Missing Navigation Wiring

```dart
// Add to app_router.dart:
GoRoute(
  path: '/bot-chat',
  builder: (context, state) => const BotChatScreen(),
  // Pre-fill slots from query params if coming from other screens
)

// Pre-fill support:
// /bot-chat?intent=findLoad&origin=Mumbai&destination=Delhi
```

### 4.4 Missing Backend Support

| Feature | Backend Needed | Status |
|---------|---------------|--------|
| Bot conversation persistence | Table `bot_conversations` | ⚠️ Not required (per-session only) |
| Bot analytics | Events to monitoring | 🟢 Can reuse MonitoringService |
| Bot-specific API | None | ✅ All APIs already exist (loads, trips, etc.) |

---

## 5. PROPOSED IMPLEMENTATION PLAN

### Phase A: Foundation (Week 1)

**Goal**: Build the conversational engine

**Tasks**:
1. **A1**: Create `BotMessage` data models
   - `BotMessage` (id, text, sender: bot|user, timestamp, actions: List<BotAction>)
   - `BotAction` (label, route, params)
   - `BotIntent` enum (findLoad, postLoad, myLoads, myTrips, checkStatus, help, greeting)
   - `SlotState` (currentIntent, filledSlots: Map<String, dynamic>, pendingSlot: String?)

2. **A2**: Create `BotService` (pure logic, no Flutter deps)
   - `matchIntent(String text)` → returns BotIntent or null
   - `extractEntity(String text, EntityType type)` → returns extracted value or null
   - `getNextResponse(SlotState state)` → returns BotMessage
   - `fillSlot(SlotState state, String slotName, dynamic value)` → updated SlotState
   - City fuzzy matching (reuse offline JSON)
   - Material matching (with Hindi support)
   - Price parsing (regex for numbers, "k", "lakh")
   - Weight parsing (regex for ton/tonne/T)

3. **A3**: Create `BotChatProvider`
   - `StateNotifier<BotChatState>`
   - Methods: `sendMessage(String text)`, `startNewConversation()`, `cancelCurrentFlow()`
   - Integrates with `BotService` for intent matching
   - Manages slot-filling state machine
   - Auto-invokes TTS on bot responses

4. **A4**: Add bot route to `app_router.dart`

**Deliverable**: Can test intent matching and slot filling in isolation (no UI yet)

### Phase B: UI & Integration (Week 2)

**Goal**: Build the chat screen and wire everything up

**Tasks**:
1. **B1**: Create `BotChatScreen`
   - AppBar: Back arrow, "TranZfort Bot" title, "New" button
   - Message list: Scrollable, bot bubbles left, user bubbles right
   - Inline CTA buttons inside bot bubbles
   - Typing indicator (animated dots)
   - Input bar: Text field + mic button (STT integration)
   - "New" button clears conversation

2. **B2**: Integrate STT into input bar
   - Mic button → start listening (SttService)
   - Show partial results in text field
   - Auto-submit on final result
   - Handle permission denied → show dialog

3. **B3**: Integrate TTS into bot responses
   - Every bot message auto-spoken via `ContextualTtsService`
   - Follows user's language preference
   - Strip emojis before TTS
   - Cancel TTS on screen exit

4. **B4**: Add entry points
   - Dashboard quick action button (both roles)
   - Drawer menu item
   - NOT on Find Loads feed (per spec)

**Deliverable**: Fully functional bot chat screen, voice-enabled

### Phase C: Intent Implementation (Week 3)

**Goal**: Implement all 7 intents with real navigation/actions

**Tasks**:
1. **C1**: `greeting` intent
   - Context-aware: checks active trips/loads count via providers
   - Personalized greeting with user's name

2. **C2**: `help` intent
   - Static response with available commands list
   - Bilingual (Hindi/English based on locale)

3. **C3**: `findLoad` intent + slot filling
   - 2-slot flow: origin → destination
   - Fuzzy city matching (Levenshtein)
   - Execute search via existing LoadRepository
   - Show "View Loads →" CTA that navigates to `/find-loads?origin=X&dest=Y`

4. **C4**: `postLoad` intent + slot filling (Supplier only)
   - 5-slot flow: origin → destination → material → weight → price
   - Show summary with smart defaults
   - "Post Load" CTA → calls `create_load` RPC
   - "More Options" CTA → navigates to PostLoadScreen with pre-filled values

5. **C5**: `myLoads` intent (Supplier only)
   - Direct navigation to `/my-loads`
   - "Aapke {count} active loads hain"

6. **C6**: `myTrips` intent (Both roles)
   - Role-aware navigation (supplier-trips vs trips)
   - "Aapke {count} active trips hain"

7. **C7**: `checkStatus` intent
   - Query latest active booking/trip
   - Report current status in natural language

**Deliverable**: All 7 intents working end-to-end

### Phase D: Polish & Testing (Week 4)

**Goal**: Error handling, edge cases, tests

**Tasks**:
1. **D1**: Implement all 8 error recovery scenarios
2. **D2**: Cancel handling ("rehne do", "cancel")
3. **D3**: Slot correction (user changes previous answer)
4. **D4**: Network error handling during searches
5. **D5**: Empty result handling
6. **D6**: Write unit tests for BotService
7. **D7**: Write widget tests for BotChatScreen
8. **D8**: Integration tests for full flows

**Deliverable**: Production-ready bot with tests

---

## 6. DECISIONS TO MAKE

### 6.1 Should we persist bot conversations?

**Spec says**: Per-session only. Closing and reopening starts fresh.

**Option A**: Follow spec (no persistence)
- Simpler, no backend changes
- User starts fresh every time
- "New" button just clears in-memory state

**Option B**: Add light persistence (last 10 messages in SharedPreferences)
- Better UX if user accidentally exits
- Still resets on "New" button
- No backend changes needed

**Recommendation**: Option A for V1. Bot is an accessibility tool, not a primary interface. Per-session is fine.

### 6.2 Hindi transliteration support?

**Problem**: Users might type in Roman Hindi ("load dhundho" written in English script)

**Current plan**: Spec already has trigger phrases in Roman Hindi. This is sufficient for V1.

**Future**: Devanagari support would require more complex text processing. Defer to V2.

### 6.3 Should bot be available offline?

**Current infrastructure**: City search works offline (JSON). Everything else needs network.

**Spec says**: No offline requirement for bot V1.

**Recommendation**: Bot works when online. Show "Network required" message when offline. This matches current app behavior.

### 6.4 Should we add bot analytics?

**MonitoringService** already exists (from Navigation Plan C).

**Events to track**:
- Intent matched
- Slot filled successfully
- Slot filling failed (entity extraction error)
- Navigation action triggered from bot
- TTS/STT usage in bot
- Error recovery triggered

**Recommendation**: Yes, reuse MonitoringService. Minimal effort, valuable data.

### 6.5 Should postLoad directly create load or navigate to form?

**Spec says**: Both options.
- "Post Load" CTA → calls `create_load` RPC directly
- "More Options" CTA → navigates to form with pre-filled values

**Risk**: Direct creation might skip validation users expect.

**Recommendation**: Follow spec. Quick users can post directly. Detail-oriented users can review in form. Show clear confirmation before direct creation.

---

## 7. TECHNICAL ARCHITECTURE

### 7.1 Data Flow

```
User speaks/texts → BotChatScreen → BotChatProvider → BotService
                                           │
                                           ├──→ Intent Matcher
                                           ├──→ Entity Extractor
                                           ├──→ Slot Filler
                                           │
                                           ↓
                                    BotMessage (response)
                                           │
                                           ├──→ TTS (auto-speak)
                                           ├──→ UI (display bubble)
                                           └──→ Navigation (if CTA tapped)
```

### 7.2 File Structure

```
lib/src/features/bot/
├── data/
│   ├── bot_service.dart              # Intent matching, entity extraction
│   └── bot_constants.dart          # Trigger phrases, material names
├── domain/
│   ├── bot_intent.dart               # BotIntent enum
│   ├── bot_message.dart              # BotMessage, BotAction models
│   └── slot_state.dart             # SlotState, SlotName enum
├── presentation/
│   ├── bot_chat_screen.dart          # Main chat screen
│   ├── widgets/
│   │   ├── bot_message_bubble.dart   # Bot message bubble
│   │   ├── user_message_bubble.dart  # User message bubble
│   │   ├── bot_action_button.dart    # Inline CTA button
│   │   ├── typing_indicator.dart     # Animated dots
│   │   └── bot_input_bar.dart        # Text + mic input
│   └── providers/
│       └── bot_chat_provider.dart    # State management
```

### 7.3 Provider Dependencies

```
BotChatProvider depends on:
├── BotService (intent + entity logic)
├── TtsPlaybackController (auto-speak)
├── SttService (voice input)
├── TruckerCitySearchService (city extraction)
├── LoadRepository (for findLoad execution)
├── TripRepository (for myTrips, checkStatus)
└── AuthState (for user profile, role)
```

---

## 8. REUSE OPPORTUNITIES (What We Don't Need to Build)

| Component | Already Exists | Reuse Strategy |
|-----------|---------------|----------------|
| TTS speaking | `ContextualTtsService` | Direct injection |
| TTS muting | `ttsMutedProvider` | Read state before speak |
| TTS button | `TtsActionButton` | Already on AppBar |
| STT engine | `SttService` | Inject into BotInputBar |
| City search | `TruckerCitySearchService` | Inject for entity extraction |
| City JSON | `assets/data/indian_cities.json` | Already bundled |
| Navigation | `NavigationService` / `GoRouter` | Use existing routing |
| Monitoring | `MonitoringService` | Add bot event tracking |
| Chat bubbles UI | `ChatScreen` patterns | Adapt message bubble styles |
| Language/locale | `Localizations.localeOf(context)` | Follow app setting |

---

## 9. RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| STT accuracy low in noisy environments (trucker use case) | High | Medium | Strong fallback to text input, clear mic permission guidance |
| Hindi speech recognition quality varies by device | Medium | Medium | Test on target devices, fallback to text |
| Intent matching too rigid (users use variations) | Medium | High | Add more trigger phrases, fuzzy matching, analytics to discover missed intents |
| Slot filling feels robotic (too many questions) | Low | Medium | Keep flows short (max 5 slots), allow skip/shortcuts |
| Bot conflicts with existing TTS (screen summaries) | Low | Medium | Bot TTS cancels other TTS, use shared queue |
| Performance: Large city JSON slows search | Low | Low | Already optimized (cached, filtered, limited results) |

---

## 10. SUCCESS CRITERIA

**Minimum Viable Bot (V1 Launch)**:
- ✅ All 7 intents functional
- ✅ Hindi and English support
- ✅ Voice input (STT) and output (TTS)
- ✅ Slot filling for findLoad and postLoad
- ✅ Navigation actions work (CTA buttons route correctly)
- ✅ Error recovery for all 8 scenarios
- ✅ Per-session conversation (no persistence needed)
- ✅ Works on Android target devices
- ✅ Unit tests for BotService logic
- ✅ No crashes or ANRs

**Nice to Have (Post-Launch)**:
- 🟡 Conversation persistence (last session)
- 🟡 More trigger phrase variations (discovered via analytics)
- 🟡 Smarter entity extraction (context-aware)
- 🟡 Bot usage analytics dashboard
- 🟡 LLM fallback (feature-flagged experiment)

---

## 11. ESTIMATED EFFORT

| Phase | Duration | Developer Focus |
|-------|----------|-----------------|
| A: Foundation | 3-4 days | BotService logic, models, provider |
| B: UI & Integration | 4-5 days | Chat screen, STT/TTS wiring, entry points |
| C: Intent Implementation | 3-4 days | All 7 intents, navigation, API calls |
| D: Polish & Testing | 2-3 days | Error handling, edge cases, tests |
| **Total** | **12-16 days** | **~2-3 weeks for one developer** |

**Parallelizable**: Phases A and B can be partially parallel (UI mockup while engine builds)

---

## 12. RECOMMENDATION

**Build the bot. The infrastructure investment is sunk cost — TTS, STT, and city database are all built and working. The remaining work is the conversational engine and UI, which is well-defined by the locked spec.**

**Suggested Priority**: After current UI/UX phase completes (TODO-21-april), bot is a strong candidate for the next feature sprint. It provides significant value to truckers (voice-first interaction) and differentiates the product.

**Start with**: Phase A (BotService + models + provider) — this can be developed and tested in isolation without touching UI. Then build UI around the working engine.

---

*End of Bot Brainstorm & Implementation Plan*
*Last Updated: April 22, 2026*
