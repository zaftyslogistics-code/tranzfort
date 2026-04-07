# TranZfort (User App)

Flutter client for supplier/trucker flows.

## Google Maps key setup (optional, keyless-first)

The app is designed to work **without** Google keys. When no key is provided,
Google-backed features gracefully fall back to local/OSRM/limited modes.

### Optional APIs to enable in Google Cloud

- Places API (New)
- Routes API
- Geocoding API
- Distance Matrix API (or Routes matrix equivalent)
- Weather API (only if weather chips are needed)

### Pass key via dart-define

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
```

Supported feature flags:

- `--dart-define=ENABLE_GOOGLE_PLACES=true|false`
- `--dart-define=ENABLE_GOOGLE_ROUTES=true|false`
- `--dart-define=ENABLE_GOOGLE_GEOCODING=true|false`
- `--dart-define=ENABLE_OSRM_FALLBACK=true|false`

If `GOOGLE_MAPS_API_KEY` is not set, map-related features continue using
fallback chains where available.
