-- Consolidated supplier trip detail RPC
-- Returns trip + trucker summary + load snapshot + truck details + dispute summary in one JSONB contract.
-- Signed URLs for proof documents are generated client-side from the returned document paths.

DROP FUNCTION IF EXISTS public.get_supplier_trip_detail(UUID, UUID);

CREATE OR REPLACE FUNCTION public.get_supplier_trip_detail(
    p_trip_id UUID,
    p_supplier_id UUID
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_trip JSONB;
    v_trucker_profile JSONB;
    v_load_snapshot JSONB;
    v_truck JSONB;
    v_dispute_summary JSONB;
BEGIN
    -- Trip row with ownership validation (supplier_id must match)
    SELECT jsonb_build_object(
        'id', t.id,
        'load_id', t.load_id,
        'trucker_id', t.trucker_id,
        'truck_id', t.truck_id,
        'stage', t.stage,
        'assigned_at', t.assigned_at,
        'started_at', t.started_at,
        'delivered_at', t.delivered_at,
        'pod_uploaded_at', t.pod_uploaded_at,
        'completed_at', t.completed_at,
        'lr_document_path', t.lr_document_path,
        'pod_document_path', t.pod_document_path
    ) INTO v_trip
    FROM public.trips t
    WHERE t.id = p_trip_id AND t.supplier_id = p_supplier_id;

    IF v_trip IS NULL THEN
        RETURN NULL;
    END IF;

    -- Trucker profile (with masked mobile)
    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'mobile', CASE WHEN p.mobile IS NOT NULL THEN
            OVERLAY(p.mobile PLACING '****' FROM 3 FOR 4)
            ELSE NULL END,
        'verification_status', p.verification_status,
        'avatar_url', COALESCE(p.avatar_url, p.profile_photo_document_path),
        'avg_rating', COALESCE(pts.avg_rating, 0),
        'review_count', COALESCE(pts.review_count, 0)
    ) INTO v_trucker_profile
    FROM public.profiles p
    LEFT JOIN public.profile_trust_scores pts ON pts.user_id = p.id
    WHERE p.id = (v_trip->>'trucker_id')::UUID;

    -- Load snapshot from loads table (for fields not in load_snapshot_summary)
    SELECT jsonb_build_object(
        'origin_label', l.origin_label,
        'destination_label', l.destination_label,
        'material', l.material,
        'route_distance_km', l.route_distance_km,
        'route_duration_minutes', l.route_duration_minutes,
        'pickup_date', l.pickup_date
    ) INTO v_load_snapshot
    FROM public.loads l
    WHERE l.id = (v_trip->>'load_id')::UUID;

    -- Truck details
    SELECT jsonb_build_object(
        'id', tr.id,
        'truck_number', tr.truck_number,
        'body_type', tr.body_type,
        'tyres', tr.tyres
    ) INTO v_truck
    FROM public.trucks tr
    WHERE tr.id = (v_trip->>'truck_id')::UUID;

    -- Dispute summary if stage is disputed
    IF (v_trip->>'stage') = 'disputed' THEN
        SELECT jsonb_build_object(
            'category', td.category,
            'status', td.status,
            'updated_at', td.updated_at
        ) INTO v_dispute_summary
        FROM public.trip_disputes td
        WHERE td.trip_id = p_trip_id
        ORDER BY td.updated_at DESC
        LIMIT 1;
    END IF;

    RETURN jsonb_build_object(
        'trip', v_trip,
        'trucker_profile', COALESCE(v_trucker_profile, '{}'::JSONB),
        'load_snapshot', COALESCE(v_load_snapshot, '{}'::JSONB),
        'truck', COALESCE(v_truck, '{}'::JSONB),
        'dispute_summary', v_dispute_summary
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supplier_trip_detail(UUID, UUID) TO authenticated;
