# TODO - Sprint 6: Booking Engine & Trips

## Scope
Booking handshake + trip lifecycle.

## Tasks
- [ ] Deploy booking RPCs
- [x] Booking UI (truck selection)
- [ ] Supplier approve/reject
- [x] My Trips + Trip Detail screens
- [ ] Stage transitions
- [x] GPS bounded triggers
- [x] LR/POD upload
- [x] Rating flow
- [ ] pg_cron auto complete

## Definition of Done
- [ ] Full trip lifecycle works end-to-end
- [ ] GPS failure never blocks actions

## Progress Notes (26 Feb)
- Implemented trucker booking UX in `FindLoadsScreen`: no-truck dialog, single-truck confirm dialog, multi-truck bottom-sheet selection.
- Added `/my-trips` and `/trip-detail/:tripId` routes with initial stage-aware UI.
- Added `TripActionNotifier.startTrip()` calling `start_trip` RPC.
- Added bounded GPS capture service (`LocationService`) with graceful fallback (trip action continues when location capture fails).
- Validation:
  - `flutter analyze` -> PASS
  - `python ..\\scripts\\check_layer_boundaries.py` -> PASS

## Progress Notes (26 Feb, Phase 2)
- Added trip stage actions in Trip Detail UI:
  - Start Trip (with confirmation)
  - Mark Delivered (with confirmation)
  - Upload POD Photo (camera + compression + upload)
- Added repository + provider wiring for:
  - `markDelivered(...)`
  - `uploadPod(...)`
- Added bounded GPS capture integration on Start Trip / Mark Delivered / POD upload, with graceful non-blocking fallback.
- Note: Trigger #1 (booking GPS) and supplier-side confirmation/auto-complete flow are still pending, so Sprint 6 is not yet complete.

## Progress Notes (26 Feb, Phase 3)
- Added booking-time GPS trigger (#1) wiring in marketplace booking action (`bookLoadWithTruck`) with non-blocking fallback.
- Added profile last-known location repository update for booking trigger persistence.
- Added storage migration for `load-documents` bucket + authenticated upload/read policies.
- GPS triggers now covered in app flow:
  - #1 Booking
  - #2 Start Trip
  - #3 Mark Delivered
  - #4 POD Upload

## Progress Notes (26 Feb, Phase 4)
- Added LR upload action in `at_pickup` stage (optional flow) with camera + compression + upload to `load-documents/{load_id}/lr.jpg`.
- Added POD upload action in `delivered` stage with camera + compression + upload to `load-documents/{load_id}/pod.jpg`.
- Added repository persistence wiring to write LR/POD URLs in both `trips` and `loads` records.
- Stage transitions implemented on trucker side through `pod_uploaded`.

## Progress Notes (26 Feb, Phase 5)
- Implemented supplier-side `confirmDelivery` action (transitions `pod_uploaded` trip to `completed`).
- Implemented post-trip rating flow:
  - Read existing rating via `getRatingForLoad` RPC/query.
  - Submit new rating to `ratings` table constraints.
  - Star selector UI + optional comment integrated into `TripDetailScreen`.
- Sprint 6 core feature implementation complete (pending pg_cron automation setup, which sits at DB level for later ops/prod config).
