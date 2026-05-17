/// Application configuration constants and feature flags.
///
/// This file contains environment-based configuration for the TranZfort app.
/// Use `--dart-define` to override these values during build:
///
/// ```bash
/// flutter build apk --dart-define=USE_RPC_MIGRATION=true
/// ```
library;

/// Whether to use RPC-first migration for backend operations.
///
/// When enabled, the app will use Supabase RPCs instead of direct table reads
/// for data fetching operations. This is part of the P3 RPC-First Migration.
///
/// **Rollback Process:**
/// If issues occur, rebuild with `--dart-define=USE_RPC_MIGRATION=false`
/// No code changes needed, just rebuild with different flag.
///
/// **Gradual Rollout Strategy:**
/// - Start with P3.5 (Fleet) - isolated feature, low risk
/// - Then P3.8 (Notifications) - simple, low impact
/// - Then P3.6 (Chat) - critical for C-003, high impact
/// - Then P3.2 (Supplier Loads) - core business logic
/// - Then P3.3-P3.4 (Trucker) - core business logic
/// - Then P3.7 (Support) - medium priority
/// - Finally P3.1 (Auth/Profile) - critical, do last
const bool useRpcMigration = bool.fromEnvironment(
  'USE_RPC_MIGRATION',
  defaultValue: false,
);
