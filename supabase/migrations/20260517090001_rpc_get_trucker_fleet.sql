-- Migration: Create RPC get_trucker_fleet
-- Purpose: Fetch trucker's fleet with pagination (replaces direct table read)
-- Created: May 17, 2026
-- Part of: P3.5 - Fleet RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: get_trucker_fleet
-- Returns: List of trucks belonging to the authenticated trucker
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION get_trucker_fleet(
    p_user_id UUID,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_trucks JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', t.id,
            'truck_model_id', t.truck_model_id,
            'truck_number', t.truck_number,
            'body_type', t.body_type,
            'tyres', t.tyres,
            'capacity_tonnes', t.capacity_tonnes,
            'rc_document_path', t.rc_document_path,
            'status', t.status,
            'rejection_reason', t.rejection_reason,
            'verification_feedback_json', t.verification_feedback_json,
            'verified_at', t.verified_at,
            'created_at', t.created_at,
            'updated_at', t.updated_at,
            'truck_models', jsonb_build_object(
                'make', tm.make,
                'model', tm.model
            )
        )
    ) INTO v_trucks
    FROM trucks t
    LEFT JOIN truck_models tm ON tm.id = t.truck_model_id
    WHERE t.owner_id = p_user_id
      AND t.status != 'archived'  -- Exclude archived trucks by default
    ORDER BY t.created_at DESC
    LIMIT p_limit OFFSET p_offset;

    RETURN COALESCE(v_trucks, '[]'::jsonb);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_trucker_fleet(UUID, INT, INT) TO authenticated;
