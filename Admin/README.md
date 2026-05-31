# TranZfort Admin

Flutter admin app. **Do not commit** `.env` with service keys.

## Configuration

| Method | Use |
|--------|-----|
| `--dart-define=SUPABASE_URL=...` | CI / local run |
| `--dart-define=SUPABASE_ANON_KEY=...` | CI / local run |
| `.env` (gitignored) | Local only — mirror keys into dart-define for CI |

Super Load workflow: [`website/legal/super-load-admin-sop.md`](../website/legal/super-load-admin-sop.md)
