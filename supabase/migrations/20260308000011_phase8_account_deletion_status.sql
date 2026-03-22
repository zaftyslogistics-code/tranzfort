-- ============================================================================
-- TranZfort Rebuild — Phase 8: Account deletion lifecycle field alignment
-- Purpose: add the missing profiles.account_deletion_status field defined in docs
-- ============================================================================

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS account_deletion_status account_deletion_status NOT NULL DEFAULT 'active';

CREATE INDEX IF NOT EXISTS idx_profiles_account_deletion_status
  ON profiles(account_deletion_status);
