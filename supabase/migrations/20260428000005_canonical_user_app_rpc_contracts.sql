-- Canonical user-app RPC contracts — single source of truth for all Flutter-facing RPCs.
-- This migration supersedes all prior fix-only migrations for these functions.
--
-- Recreated RPCs (final signatures):
--   get_supplier_dashboard_stats(p_supplier_id UUID) → JSONB
--   get_trucker_dashboard_stats(p_trucker_id UUID) → JSONB
--   get_public_profile(p_user_id UUID, p_viewer_id UUID DEFAULT NULL) → JSONB
--   get_profile_reviews(p_user_id UUID, p_limit INT DEFAULT 5, p_offset INT DEFAULT 0) → JSONB
--   get_trip_detail_with_supplier(p_trip_id UUID, p_trucker_id UUID) → JSONB
--
-- NOTE: Keep this migration as the LAST one touching these functions.

-- ─── get_supplier_dashboard_stats ───
DROP FUNCTION IF EXISTS public.get_supplier_dashboard_stats(UUID);

CREATE OR REPLACE FUNCTION public.get_supplier_dashboard_stats(p_supplier_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_active_loads BIGINT;
    v_pending_bookings BIGINT;
    v_in_transit_trips BIGINT;
    v_completed_trips BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_active_loads FROM public.loads
    WHERE supplier_id = p_supplier_id
      AND status IN ('active', 'assigned_partial', 'assigned_full', 'in_transit');

    SELECT COUNT(*) INTO v_pending_bookings FROM public.booking_requests br
    JOIN public.loads l ON l.id = br.load_id
    WHERE l.supplier_id = p_supplier_id AND br.status = 'submitted';

    SELECT COUNT(*) INTO v_in_transit_trips FROM public.trips
    WHERE supplier_id = p_supplier_id AND stage = 'in_transit';

    SELECT COUNT(*) INTO v_completed_trips FROM public.trips
    WHERE supplier_id = p_supplier_id AND stage = 'completed';

    RETURN jsonb_build_object(
        'active_loads', v_active_loads,
        'pending_bookings', v_pending_bookings,
        'in_transit_trips', v_in_transit_trips,
        'completed_trips', v_completed_trips
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supplier_dashboard_stats(UUID) TO authenticated;


-- ─── get_trucker_dashboard_stats ───
DROP FUNCTION IF EXISTS public.get_trucker_dashboard_stats(UUID);

CREATE OR REPLACE FUNCTION public.get_trucker_dashboard_stats(p_trucker_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_active_bids BIGINT;
    v_upcoming_trips BIGINT;
    v_in_transit_trips BIGINT;
    v_completed_trips BIGINT;
    v_total_trucks BIGINT;
    v_approved_trucks BIGINT;
    v_pending_trucks BIGINT;
    v_rejected_trucks BIGINT;
    v_pending_approval_trucks BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_active_bids FROM public.booking_requests
    WHERE trucker_id = p_trucker_id AND status = 'submitted';

    SELECT COUNT(*) INTO v_upcoming_trips FROM public.trips
    WHERE trucker_id = p_trucker_id AND stage IN ('assigned', 'pickup_pending', 'picked_up');

    SELECT COUNT(*) INTO v_in_transit_trips FROM public.trips
    WHERE trucker_id = p_trucker_id AND stage = 'in_transit';

    SELECT COUNT(*) INTO v_completed_trips FROM public.trips
    WHERE trucker_id = p_trucker_id AND stage = 'completed';

    SELECT COUNT(*) INTO v_total_trucks FROM public.trucks
    WHERE owner_id = p_trucker_id;

    SELECT COUNT(*) INTO v_approved_trucks FROM public.trucks
    WHERE owner_id = p_trucker_id AND status = 'verified';

    SELECT COUNT(*) INTO v_pending_trucks FROM public.trucks
    WHERE owner_id = p_trucker_id AND status = 'pending';

    SELECT COUNT(*) INTO v_rejected_trucks FROM public.trucks
    WHERE owner_id = p_trucker_id AND status = 'rejected';

    SELECT COUNT(*) INTO v_pending_approval_trucks FROM public.trucks
    WHERE owner_id = p_trucker_id AND status = 'edited_pending_reapproval';

    RETURN jsonb_build_object(
        'active_bids', v_active_bids,
        'upcoming_trips', v_upcoming_trips,
        'in_transit_trips', v_in_transit_trips,
        'completed_trips', v_completed_trips,
        'total_trucks', v_total_trucks,
        'approved_trucks', v_approved_trucks,
        'pending_trucks', v_pending_trucks,
        'rejected_trucks', v_rejected_trucks,
        'pending_approval_trucks', v_pending_approval_trucks
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_trucker_dashboard_stats(UUID) TO authenticated;


-- ─── get_public_profile ───
DROP FUNCTION IF EXISTS public.get_public_profile(UUID, UUID);

CREATE OR REPLACE FUNCTION public.get_public_profile(
    p_user_id UUID,
    p_viewer_id UUID DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_profile JSONB;
    v_role TEXT;
    v_is_self BOOLEAN;
    v_trust_scores JSONB;
    v_role_specific JSONB;
    v_fleet JSONB;
    v_trips_count INT;
    v_avatar_url TEXT;
BEGIN
    v_is_self := (p_viewer_id = p_user_id);

    SELECT user_role_type INTO v_role FROM public.profiles WHERE id = p_user_id;
    IF v_role IS NULL THEN RETURN NULL; END IF;

    SELECT jsonb_build_object(
        'avg_rating', COALESCE(pts.avg_rating, 0),
        'review_count', COALESCE(pts.review_count, 0)
    ) INTO v_trust_scores
    FROM public.profile_trust_scores pts
    WHERE pts.user_id = p_user_id;

    IF v_trust_scores IS NULL THEN
        v_trust_scores := jsonb_build_object('avg_rating', 0, 'review_count', 0);
    END IF;

    SELECT COUNT(*) INTO v_trips_count
    FROM public.trips tr
    WHERE tr.trucker_id = p_user_id AND tr.stage = 'completed';

    IF v_role = 'trucker' THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', t.id,
                'truck_number', t.truck_number,
                'body_type', t.body_type,
                'tyres', t.tyres,
                'capacity_tonnes', t.capacity_tonnes,
                'status', t.status
            )
        ) INTO v_fleet
        FROM public.trucks t
        WHERE t.owner_id = p_user_id AND t.status = 'verified';

        v_role_specific := jsonb_build_object(
            'truck_count', COALESCE(jsonb_array_length(COALESCE(v_fleet, '[]'::jsonb)), 0),
            'fleet', COALESCE(v_fleet, '[]'::jsonb),
            'completed_trips_count', v_trips_count
        );
    ELSIF v_role = 'supplier' THEN
        SELECT jsonb_build_object(
            'total_loads_posted', COALESCE(s.total_loads_posted, 0),
            'active_loads_count', COALESCE(s.active_loads_count, 0),
            'is_super_load_eligible', FALSE
        ) INTO v_role_specific
        FROM public.suppliers s
        WHERE s.id = p_user_id;
    END IF;

    SELECT COALESCE(p.avatar_url, p.profile_photo_document_path) INTO v_avatar_url
    FROM public.profiles p WHERE p.id = p_user_id;

    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'avatar_url', v_avatar_url,
        'profile_photo_document_path', p.profile_photo_document_path,
        'company_name', s.company_name,
        'role', p.user_role_type,
        'verification_status', p.verification_status,
        'location', NULLIF(CONCAT_WS(', ', NULLIF(TRIM(p.city), ''), NULLIF(TRIM(p.state), '')), ''),
        'member_since', p.created_at,
        'is_self', v_is_self,
        'trust_scores', v_trust_scores,
        'role_specific', v_role_specific
    ) INTO v_profile
    FROM public.profiles p
    LEFT JOIN public.suppliers s ON s.id = p.id
    WHERE p.id = p_user_id;

    RETURN v_profile;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_profile(UUID, UUID) TO authenticated;


-- ─── get_profile_reviews ───
DROP FUNCTION IF EXISTS public.get_profile_reviews(UUID, INT, INT);

CREATE OR REPLACE FUNCTION public.get_profile_reviews(
    p_user_id UUID,
    p_limit INT DEFAULT 5,
    p_offset INT DEFAULT 0
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_reviews JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', sub.id,
            'reviewed_user_id', sub.reviewed_user_id,
            'reviewer_id', sub.reviewer_id,
            'reviewer_name', sub.full_name,
            'reviewer_role', sub.reviewer_role,
            'reviewer_avg_rating', COALESCE(sub.avg_rating, 0),
            'reviewer_review_count', COALESCE(sub.review_count, 0),
            'reviewer_location', NULLIF(CONCAT_WS(', ', NULLIF(TRIM(sub.city), ''), NULLIF(TRIM(sub.state), '')), ''),
            'reviewer_avatar_url', COALESCE(sub.avatar_url, sub.profile_photo_document_path),
            'reviewer_member_since', sub.reviewer_created_at,
            'context_type', sub.context_type,
            'context_id', sub.context_id,
            'rating', sub.rating,
            'comment', sub.comment,
            'reply', sub.reply,
            'reply_at', sub.reply_at,
            'created_at', sub.created_at
        )
    ) INTO v_reviews
    FROM (
        SELECT r.*, p.full_name, p.city, p.state, p.avatar_url,
               p.profile_photo_document_path, p.created_at AS reviewer_created_at,
               pts.avg_rating, pts.review_count
        FROM public.reviews r
        JOIN public.profiles p ON p.id = r.reviewer_id
        LEFT JOIN public.profile_trust_scores pts ON pts.user_id = r.reviewer_id
        WHERE r.reviewed_user_id = p_user_id
        ORDER BY r.created_at DESC
        LIMIT p_limit OFFSET p_offset
    ) sub;

    RETURN COALESCE(v_reviews, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile_reviews(UUID, INT, INT) TO authenticated;


-- ─── get_trip_detail_with_supplier ───
DROP FUNCTION IF EXISTS public.get_trip_detail_with_supplier(UUID, UUID);

CREATE OR REPLACE FUNCTION public.get_trip_detail_with_supplier(
    p_trip_id UUID,
    p_trucker_id UUID
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'trip', jsonb_build_object(
            'id', t.id,
            'load_id', t.load_id,
            'supplier_id', t.supplier_id,
            'truck_id', t.truck_id,
            'stage', t.stage,
            'assigned_at', t.assigned_at,
            'started_at', t.started_at,
            'delivered_at', t.delivered_at,
            'pod_uploaded_at', t.pod_uploaded_at,
            'completed_at', t.completed_at,
            'lr_document_path', t.lr_document_path,
            'pod_document_path', t.pod_document_path,
            'load_snapshot_summary', t.load_snapshot_summary
        ),
        'supplier_profile', jsonb_build_object(
            'id', p.id,
            'full_name', p.full_name,
            'mobile', CASE WHEN p.mobile IS NOT NULL THEN
                OVERLAY(p.mobile PLACING '****' FROM 3 FOR 4)
                ELSE NULL END,
            'city', p.city,
            'state', p.state,
            'verification_status', p.verification_status,
            'avg_rating', COALESCE(pts.avg_rating, 0),
            'review_count', COALESCE(pts.review_count, 0)
        ),
        'supplier_extension', jsonb_build_object(
            'id', s.id,
            'company_name', s.company_name
        )
    ) INTO v_result
    FROM public.trips t
    JOIN public.loads l ON l.id = t.load_id
    JOIN public.profiles p ON p.id = t.supplier_id
    LEFT JOIN public.suppliers s ON s.id = t.supplier_id
    LEFT JOIN public.profile_trust_scores pts ON pts.user_id = t.supplier_id
    LEFT JOIN public.trucks tr ON tr.id = t.truck_id
    WHERE t.id = p_trip_id AND t.trucker_id = p_trucker_id;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_trip_detail_with_supplier(UUID, UUID) TO authenticated;
