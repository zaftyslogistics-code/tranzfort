# 07: Communications, Chat & The AI Bot

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define every screen, message type, bubble spec, bot command, TTS rule, voice message flow, and realtime sync detail for the chat system and rule-based bot. A junior developer should build the entire communications layer from this document.

---

## 1. Context-Grouped Inboxes

### 1.1 The Problem
A supplier posts a bulk load for 50 trucks → 50 truckers message them. A flat inbox (WhatsApp-style) becomes unmanageable — the supplier can't tell which trucker is discussing which load.

### 1.2 Supplier Inbox (`/messages`) — Two-Level Navigation
```
┌────────────────────────────────────┐
│ Messages                [🔔][👤]  │
├────────────────────────────────────┤
│ § Group by Load:                   │
│ ┌──────────────────────────────┐   │
│ │ Coal: Chandrapur → Mumbai    │   │
│ │ 3 active conversations       │   │
│ │ "Suresh: Haan, kal aa raha"  │   │
│ │ 2 min ago                    │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ Steel: Jamshedpur → Kolkata  │   │
│ │ 1 active conversation        │   │
│ │ "Ramesh: Rate thoda kam..."  │   │
│ │ 1h ago                       │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [Home] [My Loads] [Super] [Chat]   │
└────────────────────────────────────┘
```

**Level 1:** List of loads with active conversations, sorted by `last_message_at DESC`.
- Shows: Load route, number of active conversations, latest message preview, timestamp.

**Tap a load → Level 2:**
```
┌────────────────────────────────────┐
│ [←] Coal: Chandrapur → Mumbai      │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ [👤] Suresh Kumar            │   │
│ │ MH 12 AB 1234 · Tata 407    │   │
│ │ "Haan, kal aa raha hoon"     │   │
│ │ [PENDING APPROVAL] · 2m ago  │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ [👤] Ramesh Singh            │   │
│ │ MH 14 CD 5678 · Eicher      │   │
│ │ "Rate thoda kam karo"        │   │
│ │ [BOOKED] · 1h ago            │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

**Level 2:** List of trucker conversations for that load.
- Shows: Trucker name + avatar, truck number + model, last message preview, booking status badge, timestamp.

### 1.3 Trucker Inbox (`/messages`) — Flat List
Truckers manage 1-2 loads at a time, so a flat inbox works:
```
┌────────────────────────────────────┐
│ Messages                [🔔][👤]  │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ [👤] Rajesh Industries       │   │
│ │ Coal: Chandrapur → Mumbai    │   │
│ │ "Booking approved! Aaja"     │   │
│ │ 5 min ago · [🔵 unread]     │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ [👤] Steel Corp              │   │
│ │ Steel: Jamshedpur → Kolkata  │   │
│ │ "Documents bhej do"          │   │
│ │ 3h ago                       │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [Find] [My Trips] [Fleet] [Chat]  │
└────────────────────────────────────┘
```

**Empty State:** `EmptyStateView("No messages yet", "Start a chat by booking a load.")`

---

## 2. Chat Screen (`/chat/:conversationId`)

### 2.1 Screen Layout
```
┌────────────────────────────────────┐
│ [←] Suresh Kumar       [📞][⋮]   │
│ Coal: Chandrapur → Mumbai · ₹62.5K│
│ [PENDING APPROVAL]  [Approve][Rej]│
│ (load context banner — collapsible)│
├────────────────────────────────────┤
│ ┌─── system ────────────────────┐  │
│ │ 🚛 Route: Chandrapur → Mumbai│  │
│ │ ⛏ Coal · 25T · ₹62,500      │  │
│ │ 📅 Pickup: 28 Feb            │  │
│ │ ⛽ Est. Cost: ₹15,200        │  │
│ │ [View Route →]               │  │
│ └───────────────────────────────┘  │
│                                    │
│         [Suresh] Haan bhai, kal    │
│         subah aa raha hoon.        │
│         10:15 AM ✓✓                │
│                                    │
│ [You] Theek hai, factory gate      │
│ pe milte hain.                     │
│ 10:16 AM ✓                         │
│                                    │
│         [Suresh] 🎤 Voice 0:12    │
│         10:20 AM ✓✓                │
│                                    │
├────────────────────────────────────┤
│ [📎] [________________] [🎤/➤]   │
│ (attach)(text input)    (mic/send) │
└────────────────────────────────────┘
```

### 2.2 Message Types & Bubble Specs

| Type | Bubble Content | Visual |
|------|---------------|--------|
| `text` | Text content, left-aligned (other) or right-aligned (self) | Standard chat bubble, 16px padding, `bodyMedium` |
| `voice` | Play button + waveform + duration text | Rounded bubble, blue waveform graphic, "0:12" |
| `location` | "📍 Location shared" + mini-map preview | Map thumbnail 200×100, tappable → opens Google Maps |
| `map_card` | Rich load summary card (route, cargo, price, est. cost) | Full-width card, auto-sent on first conversation |
| `truck_card` | Truck details shared by trucker | Truck number, model, body type, RC thumbnail |
| `document` | Document attachment | File icon + filename, tappable |
| `system` | System messages (booking approved, trip started, etc.) | Centered, gray text, no bubble, `bodySmall` |

### 2.3 Bubble Colors
| Sender | Background | Text Color |
|--------|-----------|-----------|
| Self (right-aligned) | `#E3F2FD` (light blue) | `#1A1A2E` (dark) |
| Other (left-aligned) | `#F5F5F5` (light gray) | `#1A1A2E` (dark) |
| System (centered) | Transparent | `#9E9E9E` (gray) |

### 2.4 Message Input Bar
- **Text field:** `TextField` with hint "Type a message…", max 1000 chars.
- **Mic button:** Shows when text field is empty. Tap to record voice message.
- **Send button:** Shows when text field has content. Tap to send text message.
- **Attach button:** Opens bottom sheet: "Camera", "Gallery", "Location", "Document".
- **Voice recording:** Hold mic button → recording indicator (red dot + timer). Release → sends. Tap to toggle (start/stop).

### 2.5 Voice Message Flow
1. User taps mic button → `record` package starts recording (AAC/M4A format).
2. Recording indicator: red dot + elapsed time counter.
3. User taps mic again → recording stops.
4. Audio file compressed (max 5MB, up to 2 minutes).
5. Upload to `voice-messages/{conversation_id}/{message_id}.m4a`.
6. INSERT into `messages` with `message_type = 'voice'`, `voice_url`, `voice_duration_seconds`.
7. Other party sees voice bubble → tap play → `just_audio` plays from signed URL.

### 2.6 Map Card (Auto-Sent)
When a conversation is first created (trucker initiates chat from a load):
1. System auto-sends a `map_card` message with the load details.
2. Card shows: route, material, weight, price, estimated trip cost.
3. "View Route" button → opens route preview screen.
4. This ensures the load context is always visible in the chat without scrolling.

---

## 3. Realtime Sync

### 3.1 Supabase Realtime Subscription
```dart
final subscription = supabase
    .from('messages')
    .stream(primaryKey: ['id'])
    .eq('conversation_id', conversationId)
    .order('created_at')
    .listen((messages) {
      // Update local message list
    });
```

### 3.2 Optimistic Updates
1. User sends message → immediately add to local list with `status: 'sending'` (clock icon).
2. INSERT into DB → on success → update local status to `status: 'sent'` (single tick ✓).
3. When other party's `is_read` updates → show double blue ticks ✓✓.

### 3.3 Read Receipts
- When user opens a conversation, mark all unread messages from the other party as `is_read = true`, `read_at = NOW()`.
- Batch update: `UPDATE messages SET is_read = true WHERE conversation_id = X AND sender_id != me AND is_read = false`.
- The other party sees blue ticks via Supabase Realtime subscription on their messages.

### 3.4 Inbox Realtime
- Inbox (conversation list) subscribes to `conversations` table changes.
- On INSERT/UPDATE → refresh conversation list → show updated `last_message_text` and `last_message_at`.
- Unread badge: Count of conversations where latest message `sender_id != me AND is_read = false`.

---

## 4. Smart In-Chat Actions

### 4.1 Load Context Banner
At the top of every chat screen, a collapsible banner shows:
- Load route: "Coal: Chandrapur → Mumbai"
- Price: "₹62,500"
- Load status badge
- **If `status = 'pending_approval'` and viewer is supplier:** Show `[Approve]` and `[Reject]` buttons right in the banner.

### 4.2 In-Chat Booking Actions
The supplier can approve/reject a booking **without leaving the chat**:
- Tap "Approve" → confirmation dialog → calls `approve_booking` RPC.
- Tap "Reject" → confirmation dialog with optional reason → calls `reject_booking` RPC.
- System message auto-sent: "Booking approved ✓" or "Booking rejected ✗".

---

## 5. The Voice Bot (`/bot-chat`)

### 5.1 Architecture Overview
```
User speaks → STT → Text → Rule Engine → Response Text → TTS → User hears
                              │
                      (if no match)
                              │
                         LLM Fallback → Response Text → TTS
                              │
                      (if LLM unavailable)
                              │
                         "Main samajh nahi paaya" → TTS
```

**V1 Rule:** The bot is **rule-based only**. No on-device LLM or AI in V1 production. The LLM fallback is an optional experiment, hidden behind a feature flag.

### 5.2 Bot Screen Layout
```
┌────────────────────────────────────┐
│ [←] TranZfort Bot       [🔄 New]  │
├────────────────────────────────────┤
│ ┌─── bot ───────────────────────┐  │
│ │ 🤖 Namaste! Main aapka       │  │
│ │ TranZfort bot hoon. Aap       │  │
│ │ mujhse load dhundh sakte      │  │
│ │ hain, load post kar sakte     │  │
│ │ hain, ya trip status check    │  │
│ │ kar sakte hain.               │  │
│ │ 10:00 AM                     │  │
│ └───────────────────────────────┘  │
│                                    │
│ [User] Load dhundho Chandrapur     │
│ se Mumbai                          │
│ 10:01 AM                           │
│                                    │
│ ┌─── bot ───────────────────────┐  │
│ │ 🤖 Chandrapur se Mumbai ke    │  │
│ │ liye 15 loads mile. Dekhein?  │  │
│ │ [View Loads →]               │  │
│ │ 10:01 AM                     │  │
│ └───────────────────────────────┘  │
│                                    │
│         [⋯ typing indicator]       │
├────────────────────────────────────┤
│ [________________]        [🎤]    │
│ (text input)           (mic btn)   │
└────────────────────────────────────┘
```

### 5.3 Bot Intent Catalog
| Intent | Trigger Phrases (Hindi/English) | Bot Action |
|--------|-------------------------------|-----------|
| `findLoad` | "load dhundho", "find load", "load chahiye" | Ask origin → dest → execute search → show results count + "View Loads" CTA |
| `postLoad` | "load dalna hai", "post load", "naya load" | 5-question slot fill: origin, dest, material, weight, price → post with defaults |
| `myLoads` | "meri loads", "my loads", "posted loads" | Navigate to My Loads screen |
| `myTrips` | "meri trips", "my trips", "trip status" | Navigate to My Trips screen |
| `checkStatus` | "booking ka status", "check status", "kya hua" | Look up latest booking → report status |
| `help` | "help", "madad", "kya kar sakte ho" | List available commands |
| `greeting` | "namaste", "hello", "hi" | Context-aware greeting: if user has active trips → mention them |

### 5.4 Slot-Filling Flow (Example: Find Load)
```
User: "Load dhundho"
Bot:  "Kahan se? (Origin city batayein)"           → asks origin slot
User: "Chandrapur"
Bot:  "Kahan tak? (Destination city batayein)"      → asks dest slot
User: "Mumbai"
Bot:  "Chandrapur se Mumbai ke liye 15 loads mile.
       Dekhein?" [View Loads →]                     → executes search
```

**Slot extraction:** Uses `EntityExtractor` class with:
- City name matching against offline city JSON.
- Fuzzy Levenshtein matching (threshold ≤ 2 edits) for typos.
- Material matching against `LoadConstants.materials` list.
- Price extraction: regex for numbers with optional "lakh", "k", "thousand" suffixes.
- Weight extraction: regex for numbers with "ton", "tonne", "T" suffixes.

### 5.5 Bot Error Recovery
| Situation | Bot Response |
|-----------|-------------|
| Unrecognized intent | "Main samajh nahi paaya. Aap 'load dhundho', 'load dalna hai', ya 'trip status' bol sakte hain." |
| Slot value not found | "'{input}' city nahi mili. Dubara try karein." |
| User says "cancel" / "rehne do" | Clears current slot-filling state, returns to idle |
| User corrects previous slot | `clearLastSlot()` → re-asks the slot |
| Empty search results | "Koi load nahi mila. Filters badal ke try karein." |

### 5.6 Bot Navigation Actions
When bot says "View Loads →" or similar CTAs, tapping the button:
- Navigates to the appropriate screen with pre-filled parameters.
- Example: `GoRouter.push('/find-loads?origin=Chandrapur&dest=Mumbai')`.

---

## 6. TTS Rules

### 6.1 When TTS Speaks
| Screen | Trigger | What TTS Says |
|--------|---------|--------------|
| Splash (first open) | Auto | "Namaste, TranZfort mein aapka swagat hai." |
| Auth screen | Auto | "Google se continue karein ya phone number se." |
| Role selection | Auto | "Aap supplier hain ya trucker? Chunein." |
| Bot greeting | Auto (on bot open) | Context greeting with active trips/loads info |
| Bot responses | Auto (every response) | The bot's response text |
| Booking approved (trucker) | Push notification open | "Booking manjoor ho gaya. Pickup ki taraf chalein." |
| Booking rejected (trucker) | Push notification open | "Booking reject ho gaya. Doosra load dhundein." |

### 6.2 TTS Implementation Rules
1. **Emoji Stripping:** Always strip emojis from text before passing to TTS engine. Regex: `[\u{1F000}-\u{1FFFF}]` and similar ranges.
2. **Language:** Primary Hindi (hi-IN). Use `flutter_tts` with `setLanguage('hi-IN')`.
3. **Speed:** `setSpeechRate(0.5)` (normal Hindi pace).
4. **Mute Respect:** Check `SharedPreferences('tts_muted')`. If true, skip all TTS. User can toggle via Settings.
5. **Queue:** TTS requests are queued — do not overlap. If user navigates away, cancel current TTS.
6. **Max Length:** Truncate TTS text to 500 characters to prevent excessively long speech.

### 6.3 STT Implementation Rules
1. **Engine:** `speech_to_text` plugin (primary). Whisper via `whisper_flutter_new` (experimental, feature-flagged).
2. **Activation:** Tap mic button → start listening. Tap again → stop.
3. **Language Hint:** `localeId: 'hi_IN'` for Hindi.
4. **Timeout:** Auto-stop after 15 seconds of silence.
5. **Partial Results:** Show real-time transcription in the text input field as user speaks.
6. **Android Permissions:** `RECORD_AUDIO` + `<queries>` for `android.speech.RecognitionService`.

---

## 7. Notification Badges

| Location | What It Shows | Data Source |
|----------|-------------|-------------|
| Bottom nav "Chat" tab | Unread conversation count (red dot + number) | `COUNT(conversations WHERE last_message sender != me AND is_read = false)` |
| Bottom nav "Notifications" bell | Unread notification count | `COUNT(notifications WHERE is_read = false)` |
| Conversation list item | Blue dot on unread conversations | `conversations.last_message_at > last_read_at` |

---

## 8. State Management (Riverpod)

| Provider | State | Intents |
|----------|-------|---------|
| `chatInboxProvider` | `AsyncValue<List<ConversationPreview>>` | `loadConversations()`, subscribes to realtime |
| `chatConversationMetaProvider(id)` | `{conversation, otherParty, loadContext}` | `loadMeta()` |
| `chatMessagesProvider(id)` | `AsyncValue<List<Message>>` | `loadMessages()`, subscribes to realtime |
| `chatSendProvider` | `{isSending}` | `sendText(convId, text)`, `sendVoice(convId, file)`, `sendLocation(convId, lat, lng)` |
| `botChatProvider` | `{messages, isProcessing, currentSlots}` | `sendMessage(text)`, `startNewConversation()` |
| `botSttProvider` | `{isListening, partialTranscript}` | `startListening()`, `stopListening()` |
| `botTtsProvider` | `{isSpeaking}` | `speak(text)`, `stop()` |

---

## 9. Purged Features (DO NOT BUILD)

1. **Admin Chat:** No direct chat between Admin and Users. Support is via the Support Ticket system only (see 09_ADMIN).
2. **Deal Negotiation Actions:** Chat is for communication only. No price change via chat card actions. Price negotiation happens off-platform or via the formal Edit Load flow.
3. **Group Chat:** No group conversations. Every conversation is 1-to-1 (one supplier, one trucker, one load).
4. **Chat History Persistence (Bot):** Bot conversation is per-session only in V1. Closing and reopening bot starts fresh.
5. **Media Messages:** No image/video sharing in chat beyond the system-generated cards. Users share documents via the verification and trip document flows only.
