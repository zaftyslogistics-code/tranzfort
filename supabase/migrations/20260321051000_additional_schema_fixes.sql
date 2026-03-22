-- ============================================================================
-- ADDITIONAL SCHEMA FIXES - 21 March 2026
-- More enum values and columns found during Super Load testing
-- ============================================================================

-- Add missing enum values to load_status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'delivered' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'load_status')
  ) THEN
    ALTER TYPE load_status ADD VALUE 'delivered';
  END IF;
END $$;

-- Add missing enum values to booking_status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'expired' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'booking_status')
  ) THEN
    ALTER TYPE booking_status ADD VALUE 'expired';
  END IF;
END $$;

-- Add super_load_eligible column to profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'super_load_eligible'
  ) THEN
    ALTER TABLE profiles ADD COLUMN super_load_eligible BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Add is_super_load and super_status columns to loads if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'loads' AND column_name = 'is_super_load'
  ) THEN
    ALTER TABLE loads ADD COLUMN is_super_load BOOLEAN DEFAULT false;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'loads' AND column_name = 'super_status'
  ) THEN
    ALTER TABLE loads ADD COLUMN super_status TEXT DEFAULT 'not_super';
  END IF;
END $$;

-- ============================================================================
-- END OF ADDITIONAL FIXES
-- ============================================================================
