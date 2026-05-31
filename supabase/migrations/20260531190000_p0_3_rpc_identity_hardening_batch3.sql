-- P0-3 batch 3: public profile viewer binding + own-rating reviewer guard.

-- ─── get_public_profile ───
DROP FUNCTION IF EXISTS public.get_public_profile(UUID, UUID);

CREATE OR REPLACE FUNCTION public.get_public_profile(
    p_user_id UUID,
    p_viewer_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_profile JSONB;
    v_role TEXT;
    v_is_self BOOLEAN;
    v_trust_scores JSONB;
    v_role_specific JSONB;
    v_fleet JSONB;
    v_trips_count INT;
    v_avatar_url TEXT;
    v_can_view_contact BOOLEAN;
    v_can_review BOOLEAN;
    v_can_message BOOLEAN;
    v_has_business_relationship BOOLEAN;
BEGIN
    IF p_viewer_id IS NOT NULL
       AND v_caller IS NOT NULL
       AND p_viewer_id IS DISTINCT FROM v_caller
       AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

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

    IF p_viewer_id IS NOT NULL AND NOT v_is_self THEN
        SELECT EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.trucker_id = p_user_id AND t.supplier_id = p_viewer_id
               AND t.stage NOT IN ('completed', 'cancelled')
            UNION
            SELECT 1 FROM public.trips t
            WHERE t.trucker_id = p_viewer_id AND t.supplier_id = p_user_id
               AND t.stage NOT IN ('completed', 'cancelled')
            UNION
            SELECT 1 FROM public.booking_requests br
            JOIN public.loads l ON l.id = br.load_id
            WHERE l.supplier_id = p_user_id AND br.trucker_id = p_viewer_id
               AND br.status IN ('submitted', 'approved')
            UNION
            SELECT 1 FROM public.booking_requests br
            JOIN public.loads l ON l.id = br.load_id
            WHERE l.supplier_id = p_viewer_id AND br.trucker_id = p_user_id
               AND br.status IN ('submitted', 'approved')
        ) INTO v_has_business_relationship;
    ELSE
        v_has_business_relationship := FALSE;
    END IF;

    v_can_view_contact := v_is_self OR v_has_business_relationship;
    v_can_review := v_has_business_relationship;
    v_can_message := v_is_self OR v_has_business_relationship;

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
        'can_view_contact', v_can_view_contact,
        'can_review', v_can_review,
        'can_message', v_can_message,
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

-- ─── get_own_rating ───
CREATE OR REPLACE FUNCTION public.get_own_rating(
    p_reviewer_id UUID,
    p_load_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_result JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF p_reviewer_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT row_to_json(t)::jsonb
    INTO v_result
    FROM (
        SELECT id, score, comment, created_at
        FROM public.ratings
        WHERE reviewer_id = v_caller
          AND load_id = p_load_id
    ) t;

    RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;
