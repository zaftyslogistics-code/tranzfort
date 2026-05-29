-- Migration: Create RPC add_truck
-- Purpose: Add a new truck to the fleet (replaces direct table insert)
-- Created: May 17, 2026
-- Part of: P3.5 - Fleet RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: add_truck
-- Returns: UUID of the created truck
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION add_truck(
    p_truck_number TEXT,
    p_body_type TEXT,
    p_tyres INTEGER,
    p_capacity_tonnes NUMERIC,
    p_rc_document_path TEXT
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_truck_id UUID;
    v_user_id UUID;
BEGIN
    -- Get authenticated user ID
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Validate inputs
    IF p_truck_number IS NULL OR p_truck_number = '' THEN
        RAISE EXCEPTION 'Truck number is required';
    END IF;
    
    IF p_body_type IS NULL OR p_body_type = '' THEN
        RAISE EXCEPTION 'Body type is required';
    END IF;
    
    IF p_tyres IS NULL OR p_tyres <= 0 THEN
        RAISE EXCEPTION 'Tyres must be a positive integer';
    END IF;
    
    IF p_capacity_tonnes IS NULL OR p_capacity_tonnes <= 0 THEN
        RAISE EXCEPTION 'Capacity must be a positive number';
    END IF;

    -- Insert truck with pending status
    INSERT INTO trucks (
        owner_id,
        truck_number,
        body_type,
        tyres,
        capacity_tonnes,
        rc_document_path,
        status
    ) VALUES (
        v_user_id,
        UPPER(TRIM(p_truck_number)),
        TRIM(p_body_type),
        p_tyres,
        p_capacity_tonnes,
        TRIM(p_rc_document_path),
        'pending'
    ) RETURNING id INTO v_truck_id;

    RETURN v_truck_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT) TO authenticated;
