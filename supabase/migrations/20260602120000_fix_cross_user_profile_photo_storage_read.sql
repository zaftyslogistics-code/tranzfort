-- Fix: truckers/suppliers could not see each other's avatars after P0-8.
--
-- P0-8 removed ver_docs_profile_photos_public_read and only allowed owners to read
-- legacy profile_photo/* objects in verification-documents. Client signed URLs use the
-- viewer's JWT, so createSignedUrl failed for cross-user legacy photos.
--
-- New uploads use profile-photos (authenticated read). Legacy files remain under
-- verification-documents — restore authenticated read for profile_photo paths only.

DROP POLICY IF EXISTS "ver_docs_authenticated_read_profile_photo_paths" ON storage.objects;

CREATE POLICY "ver_docs_authenticated_read_profile_photo_paths"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'verification-documents'
  AND name LIKE '%/profile_photo/%'
);

-- get_public_profile: expose storage path + resolved avatar source for client signing.
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

    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'avatar_url', public.resolve_profile_avatar_source(
            p.avatar_url,
            p.profile_photo_document_path
        ),
        'profile_photo_document_path', p.profile_photo_document_path,
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
