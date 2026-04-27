-- ============================================================================
-- Phase 3 Migration 2: Migrate legacy 'negotiable' data to 'per_ton'
-- Date: 2026-04-28
-- ============================================================================
-- Aligns existing load data with the new canonical price_type value.
-- Only touches rows where price_type is still 'negotiable'.
-- ============================================================================

UPDATE loads
SET price_type = 'per_ton'
WHERE price_type = 'negotiable';

-- Verify: report how many rows were updated
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM loads WHERE price_type = 'negotiable';
  IF v_count > 0 THEN
    RAISE WARNING '% loads still have price_type = negotiable after migration', v_count;
  END IF;
END $$;
