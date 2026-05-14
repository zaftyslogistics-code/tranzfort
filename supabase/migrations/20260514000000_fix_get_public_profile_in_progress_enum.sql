-- Fix get_public_profile: replace invalid 'in_progress' trip_stage value
-- 'in_progress' is a support_ticket_status value, NOT a trip_stage value
-- trip_stage enum only has: assigned, pickup_pending, picked_up, in_transit,
--   delivered, proof_submitted, completed, disputed, cancelled
-- The intent was to match active (non-terminal) trips, so use NOT IN ('completed', 'cancelled')

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
    v_can_view_contact BOOLEAN;
    v_can_review BOOLEAN;
    v_can_message BOOLEAN;
    v_has_business_relationship BOOLEAN;
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

    -- Determine business relationship for capability flags
    IF p_viewer_id IS NOT NULL AND NOT v_is_self THEN
        -- Check if there's any business relationship (active trips, completed trips, active bookings)
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
            WHERE br.supplier_id = p_user_id AND br.trucker_id = p_viewer_id
               AND br.status IN ('pending', 'accepted')
            UNION
            SELECT 1 FROM public.booking_requests br
            WHERE br.supplier_id = p_viewer_id AND br.trucker_id = p_user_id
               AND br.status IN ('pending', 'accepted')
        ) INTO v_has_business_relationship;
    ELSE
        v_has_business_relationship := FALSE;
    END IF;

    -- Compute capability flags
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

COMMENT ON FUNCTION public.get_public_profile IS
'Get public profile with capability flags computed from viewer relationship.
Capability flags:
- can_view_contact: TRUE for self or users with business relationship
- can_review: TRUE only if there is a business relationship (active trip, active booking)
- can_message: TRUE for self or users with business relationship';
