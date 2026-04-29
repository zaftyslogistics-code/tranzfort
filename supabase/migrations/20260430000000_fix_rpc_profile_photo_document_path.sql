-- Fix: Remove references to non-existent profiles.profile_photo_document_path column
-- This column does not exist in the profiles table schema (20260308000002_phase2_identity_tables.sql)
-- Referencing it causes SQL errors in all affected RPCs.

-- ─── get_marketplace_feed ───
DROP FUNCTION IF EXISTS public.get_marketplace_feed(
  TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, INT[],
  TEXT, INT, INT
);

CREATE OR REPLACE FUNCTION public.get_marketplace_feed(
  p_origin_city         TEXT DEFAULT NULL,
  p_destination_city    TEXT DEFAULT NULL,
  p_material            TEXT DEFAULT NULL,
  p_body_type           TEXT DEFAULT NULL,
  p_min_price           NUMERIC DEFAULT NULL,
  p_max_price           NUMERIC DEFAULT NULL,
  p_super_loads_only    BOOLEAN DEFAULT FALSE,
  p_required_tyres      INT[] DEFAULT NULL,
  p_sort_by             TEXT DEFAULT 'newest',
  p_page_size           INT DEFAULT 20,
  p_page                INT DEFAULT 1
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset   INT := (p_page - 1) * p_page_size;
  v_total    BIGINT;
  v_results  JSONB;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM public.loads l
  JOIN public.profiles p ON p.id = l.supplier_id
  WHERE l.status = 'active'
    AND p.verification_status = 'verified'
    AND (p_origin_city IS NULL OR l.origin_city ILIKE '%' || p_origin_city || '%')
    AND (p_destination_city IS NULL OR l.destination_city ILIKE '%' || p_destination_city || '%')
    AND (p_material IS NULL OR l.material ILIKE '%' || p_material || '%')
    AND (p_body_type IS NULL OR l.required_body_type = p_body_type)
    AND (p_min_price IS NULL OR l.price_amount >= p_min_price)
    AND (p_max_price IS NULL OR l.price_amount <= p_max_price)
    AND (p_super_loads_only = FALSE OR l.is_super_load = TRUE)
    AND (p_required_tyres IS NULL OR p_required_tyres = '{}'
         OR l.required_tyres && p_required_tyres);

  SELECT jsonb_agg(row_to_json(t) ORDER BY t.sort_key DESC)
  INTO v_results
  FROM (
    SELECT
      l.id,
      l.supplier_id,
      l.origin_label,
      l.origin_city,
      l.origin_state,
      l.origin_lat,
      l.origin_lng,
      l.destination_label,
      l.destination_city,
      l.destination_state,
      l.destination_lat,
      l.destination_lng,
      l.route_distance_km,
      l.route_duration_minutes,
      l.route_snapshot_source,
      l.material,
      l.weight_tonnes,
      l.required_body_type,
      l.required_tyres,
      l.trucks_needed,
      l.trucks_booked,
      l.price_amount,
      l.price_type,
      l.advance_percentage,
      l.pickup_date,
      l.status,
      l.is_super_load,
      l.super_status,
      l.created_at,
      l.parent_load_id,
      jsonb_build_object(
        'supplier_name',        p.full_name,
        'supplier_avatar_url',  p.avatar_url,
        'supplier_mobile',      p.mobile,
        'supplier_trust_score', COALESCE((
          SELECT trust_score FROM public.profile_trust_scores WHERE profile_id = p.id
        ), 0)
      ) AS supplier_summary,
      CASE p_sort_by
        WHEN 'newest'      THEN extract(epoch from l.created_at)::BIGINT
        WHEN 'price_asc'   THEN -l.price_amount
        WHEN 'price_desc'  THEN l.price_amount
        WHEN 'pickup_date' THEN extract(epoch from l.pickup_date)::BIGINT
        ELSE extract(epoch from l.created_at)::BIGINT
      END AS sort_key
    FROM public.loads l
    JOIN public.profiles p ON p.id = l.supplier_id
    WHERE l.status = 'active'
      AND p.verification_status = 'verified'
      AND (p_origin_city IS NULL OR l.origin_city ILIKE '%' || p_origin_city || '%')
      AND (p_destination_city IS NULL OR l.destination_city ILIKE '%' || p_destination_city || '%')
      AND (p_material IS NULL OR l.material ILIKE '%' || p_material || '%')
      AND (p_body_type IS NULL OR l.required_body_type = p_body_type)
      AND (p_min_price IS NULL OR l.price_amount >= p_min_price)
      AND (p_max_price IS NULL OR l.price_amount <= p_max_price)
      AND (p_super_loads_only = FALSE OR l.is_super_load = TRUE)
      AND (p_required_tyres IS NULL OR p_required_tyres = '{}'
           OR l.required_tyres && p_required_tyres)
    ORDER BY sort_key DESC
    LIMIT p_page_size
    OFFSET v_offset
  ) t;

  RETURN jsonb_build_object(
    'loads',   COALESCE(v_results, '[]'::JSONB),
    'total',   v_total,
    'page',    p_page,
    'page_size', p_page_size,
    'has_more', (v_total > v_offset + p_page_size)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_marketplace_feed(
  TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, INT[],
  TEXT, INT, INT
) TO authenticated;


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

    SELECT p.avatar_url INTO v_avatar_url
    FROM public.profiles p WHERE p.id = p_user_id;

    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'avatar_url', v_avatar_url,
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
            'reviewer_avatar_url', sub.avatar_url,
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
               p.created_at AS reviewer_created_at,
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


-- ─── get_supplier_trip_detail ───
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

    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'mobile', CASE WHEN p.mobile IS NOT NULL THEN
            OVERLAY(p.mobile PLACING '****' FROM 3 FOR 4)
            ELSE NULL END,
        'verification_status', p.verification_status,
        'avatar_url', p.avatar_url,
        'avg_rating', COALESCE(pts.avg_rating, 0),
        'review_count', COALESCE(pts.review_count, 0)
    ) INTO v_trucker_profile
    FROM public.profiles p
    LEFT JOIN public.profile_trust_scores pts ON pts.user_id = p.id
    WHERE p.id = (v_trip->>'trucker_id')::UUID;

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

    SELECT jsonb_build_object(
        'id', tr.id,
        'truck_number', tr.truck_number,
        'body_type', tr.body_type,
        'tyres', tr.tyres
    ) INTO v_truck
    FROM public.trucks tr
    WHERE tr.id = (v_trip->>'truck_id')::UUID;

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
