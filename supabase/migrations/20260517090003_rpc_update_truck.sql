-- Migration: Create RPC update_truck
-- Purpose: Update a truck in the fleet (replaces direct table update)
-- Created: May 17, 2026
-- Part of: P3.5 - Fleet RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: update_truck
-- Returns: VOID (success/failure)
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_truck(
    p_truck_id UUID,
    p_truck_number TEXT,
    p_body_type TEXT,
    p_tyres INTEGER,
    p_capacity_tonnes NUMERIC,
    p_rc_document_path TEXT
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_existing_truck RECORD;
    v_critical_fields_changed BOOLEAN;
    v_next_status TEXT;
BEGIN
    -- Get authenticated user ID
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Fetch existing truck
    SELECT * INTO v_existing_truck
    FROM trucks
    WHERE id = p_truck_id AND owner_id = v_user_id
    FOR UPDATE;

    IF v_existing_truck IS NULL THEN
        RAISE EXCEPTION 'Truck not found or not owned by user';
    END IF;

    -- Determine if critical fields changed
    v_critical_fields_changed := (
        v_existing_truck.truck_number != UPPER(TRIM(p_truck_number)) OR
        v_existing_truck.body_type != TRIM(p_body_type) OR
        v_existing_truck.tyres != p_tyres OR
        v_existing_truck.capacity_tonnes != p_capacity_tonnes OR
        COALESCE(v_existing_truck.rc_document_path, '') != TRIM(p_rc_document_path)
    );

    -- Determine next status
    IF v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN
        v_next_status := 'edited_pending_reapproval';
        -- Clear verification fields when status changes to edited_pending_reapproval
        UPDATE trucks SET
            truck_number = UPPER(TRIM(p_truck_number)),
            body_type = TRIM(p_body_type),
            tyres = p_tyres,
            capacity_tonnes = p_capacity_tonnes,
            rc_document_path = TRIM(p_rc_document_path),
            status = v_next_status,
            rejection_reason = NULL,
            verification_feedback_json = NULL,
            verified_at = NULL,
            verified_by_admin_user_id = NULL,
            updated_at = NOW()
        WHERE id = p_truck_id;
    ELSE
        -- Keep existing status, just update fields
        UPDATE trucks SET
            truck_number = UPPER(TRIM(p_truck_number)),
            body_type = TRIM(p_body_type),
            tyres = p_tyres,
            capacity_tonnes = p_capacity_tonnes,
            rc_document_path = TRIM(p_rc_document_path),
            updated_at = NOW()
        WHERE id = p_truck_id;
    END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_truck(UUID, TEXT, TEXT, INTEGER, NUMERIC, TEXT) TO authenticated;
