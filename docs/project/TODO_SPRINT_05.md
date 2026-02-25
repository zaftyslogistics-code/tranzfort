# TODO - Sprint 5: Marketplace

## Scope
Suppliers post loads; truckers find loads.

## Tasks
- [x] Post Load wizard (4 steps)
- [x] Google Places autocomplete (supplier) + offline fallback
- [x] Find Loads (filters + pagination)
- [x] `RichLoadCard`
- [x] My Loads (supplier)
- [x] Load Detail (both views)
- [x] TripCostingService integrated

## Definition of Done
- [ ] Supplier can post load → visible to truckers (manual verification pending)
- [ ] Filters + infinite scroll work (manual verification pending)
- [ ] Card matches data hierarchy (manual UI verification pending)

## Manual Test Notes (26 Feb)
- [x] First real-device Google auth attempt created a new user in Supabase `auth.users`.
- [ ] Post-login app navigation remains on auth screen after brief refresh (follow-up fix required).
