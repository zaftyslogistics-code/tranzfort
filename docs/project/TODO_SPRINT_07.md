# TODO - Sprint 7: Chat & Bot

## Scope
Realtime chat + rule-based voice bot.

## Tasks
- [x] Supplier inbox (grouped)
- [x] Trucker inbox (flat)
- [x] Chat screen message types
- [x] Realtime subscriptions
- [x] Read receipts
- [ ] Voice message record/upload/play
- [ ] Map card auto-send
- [ ] In-chat booking actions
- [x] Bot screen + rule engine + slots
- [x] STT + TTS services

## Definition of Done
- [ ] Realtime chat works
- [ ] Bot can find loads via slot-filling

## Progress Notes (26 Feb, Phase 1)
- Implemented real-time chat infrastructure:
  - `chat_repository.dart` for DB/realtime interaction
  - `chat_providers.dart` for message/inbox state management
  - Two-level Supplier inbox and flat Trucker inbox via `ChatListScreen`
  - Real-time `ChatScreen` with optimistic sending and read receipts
- Implemented bot/AI assistant flow:
  - `EntityExtractor` for determining intent, city, material, weight, price
  - `BasicBotService` with rule-based slot filling and UI navigation integration
  - STT and TTS services integrated with permissions and graceful fallbacks
  - Dedicated `/bot-chat` route and UI Screen, linked to FAB in `FindLoadsScreen`
- Missing: Voice message recording, map_card auto-send, and in-chat booking actions.
