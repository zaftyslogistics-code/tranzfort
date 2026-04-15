-- Migration: Fix ratings table reviewer_role column
-- Created: April 15, 2026
-- Issue: "column 'role' does not exist" error when submitting ratings
-- Root cause: Database schema may have 'role' column instead of 'reviewer_role'

-- Check if ratings table has 'role' column and rename it to 'reviewer_role'
DO $$
BEGIN
    -- Check if 'role' column exists and 'reviewer_role' does not
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ratings' 
        AND column_name = 'role'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ratings' 
        AND column_name = 'reviewer_role'
    ) THEN
        -- Rename 'role' to 'reviewer_role'
        ALTER TABLE ratings RENAME COLUMN role TO reviewer_role;
        RAISE NOTICE 'Renamed column role to reviewer_role in ratings table';
    END IF;
    
    -- If 'reviewer_role' doesn't exist at all, add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ratings' 
        AND column_name = 'reviewer_role'
    ) THEN
        ALTER TABLE ratings ADD COLUMN reviewer_role user_role NOT NULL DEFAULT 'trucker';
        RAISE NOTICE 'Added reviewer_role column to ratings table';
    END IF;
END $$;

-- Update the submit_rating RPC to ensure it uses reviewer_role
CREATE OR REPLACE FUNCTION submit_rating(
  p_load_id UUID, p_score INTEGER, p_comment TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_rating_id UUID;
  v_trip RECORD;
  v_reviewer_role user_role;
  v_reviewee_id UUID;
BEGIN
  -- Find completed trip for this load where caller is a participant
  SELECT t.* INTO v_trip FROM trips t
  WHERE t.load_id = p_load_id AND t.stage = 'completed'
    AND (t.trucker_id = auth.uid() OR t.supplier_id = auth.uid())
  LIMIT 1;

  IF v_trip IS NULL THEN RAISE EXCEPTION 'No completed trip found for rating'; END IF;

  -- Determine roles
  IF v_trip.trucker_id = auth.uid() THEN
    v_reviewer_role := 'trucker';
    v_reviewee_id := v_trip.supplier_id;
  ELSE
    v_reviewer_role := 'supplier';
    v_reviewee_id := v_trip.trucker_id;
  END IF;

  INSERT INTO ratings (load_id, trip_id, reviewer_id, reviewee_id, reviewer_role, score, comment)
  VALUES (p_load_id, v_trip.id, auth.uid(), v_reviewee_id, v_reviewer_role, p_score, p_comment)
  RETURNING id INTO v_rating_id;

  RETURN v_rating_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
