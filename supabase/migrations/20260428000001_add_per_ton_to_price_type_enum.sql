-- ============================================================================
-- Phase 3 Migration 1: Add per_ton to price_type enum
-- Date: 2026-04-28
-- ============================================================================
-- SAFETY: Keep 'negotiable' in enum as a 1-week buffer so old Flutter builds
-- that still send 'negotiable' do not break while the new build rolls out.
-- After confirmed safe, run a follow-up migration to drop 'negotiable'.
-- ============================================================================

ALTER TYPE price_type ADD VALUE IF NOT EXISTS 'per_ton';

-- Verify
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'price_type'::regtype
      AND enumlabel = 'per_ton'
  ) THEN
    RAISE EXCEPTION 'Failed to add per_ton to price_type enum';
  END IF;
END $$;
