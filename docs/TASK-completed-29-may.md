# Completed work — 29–30 May 2026

## §H RPC-first alignment (security plan)

### Trips parity (device-verified)
- Fixed `get_trucker_trips` SQL (trucks join, stage cast, `auth.uid()`).
- Added `get_supplier_trips`; Dart backends RPC-only for list/detail slices.
- Auth-gated trip providers; `parseRpcJsonbRowList` + unit tests.

### Trucker load detail
- `get_trucker_load_detail`, fleet + latest booking RPCs.
- Supplier profile via `get_public_profile` / `get_supplier_extension`.

### Verification & profile
- Read RPCs: `get_verification_profile`, `get_supplier_verification_extension`, `get_trucker_truck_verification_counts`.
- Write RPCs: `patch_verification_profile_fields`, `patch_verification_supplier_fields`.
- Workspace profile RPCs for supplier/trucker settings screens.

### Marketplace
- `get_supplier_contact_mobile` replaces direct `profiles` read for call supplier.

### Hygiene
- `parseRpcJsonbRowList` on supplier loads, fleet, chat summaries/messages.
- Non-list RPC responses rethrow (no silent `[]`).
- `safeMap` on trip detail / dashboard / dispute paths.
- [DATA-ACCESS-ALIGNMENT.md](./DATA-ACCESS-ALIGNMENT.md) documents chat/notifications hybrid model.

### Anti-pattern (explicitly rejected)
Do **not** bypass broken RPCs with `.from('trips').select(...)` — fix SQL/RPC instead.

## §G (30 May)
- Hindi default UI + TTS from auth.
- Messages/chat flicker fix (debounced providers + shimmer).

## Migrations pushed (remote)
`20260529100000`–`20260530130000` (trips, load detail, verification, workspace profiles, contact mobile).
