-- ============================================================================
-- FINAL SCHEMA FIXES - 21 March 2026
-- Remaining columns and enum values found during Super Load testing
-- ============================================================================

-- Add company_age_years column to profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'company_age_years'
  ) THEN
    ALTER TABLE profiles ADD COLUMN company_age_years INTEGER;
  END IF;
END $$;

-- Add super_load_pending_review to load_status enum
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'super_load_pending_review' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'load_status')
  ) THEN
    ALTER TYPE load_status ADD VALUE 'super_load_pending_review';
  END IF;
END $$;

-- Add super_load_approved to load_status enum
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'super_load_approved' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'load_status')
  ) THEN
    ALTER TYPE load_status ADD VALUE 'super_load_approved';
  END IF;
END $$;

-- Add super_load_rejected to load_status enum
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'super_load_rejected' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'load_status')
  ) THEN
    ALTER TYPE load_status ADD VALUE 'super_load_rejected';
  END IF;
END $$;

-- ============================================================================
-- END OF FINAL FIXES
-- ============================================================================
