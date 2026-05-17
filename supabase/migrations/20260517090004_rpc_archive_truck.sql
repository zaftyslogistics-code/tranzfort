-- Migration: Create RPC archive_truck
-- Purpose: Archive a truck from the fleet (status update)
-- Created: May 17, 2026
-- Part of: P3.5 - Fleet RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: archive_truck
-- Returns: VOID (success/failure)
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION archive_truck(p_truck_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get authenticated user ID
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Update truck status to archived
    UPDATE trucks
    SET status = 'archived',
        updated_at = NOW()
    WHERE id = p_truck_id AND owner_id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Truck not found or not owned by user';
    END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION archive_truck(UUID) TO authenticated;
