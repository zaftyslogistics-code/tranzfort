-- P0-3 batch 2: trucker trips, trip detail, support tickets, supplier linked trips.

-- ─── get_trucker_trips ───
CREATE OR REPLACE FUNCTION public.get_trucker_trips(
    p_trucker_id UUID,
    p_stage_filter TEXT[] DEFAULT NULL,
    p_limit INT DEFAULT 15,
    p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_results JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_trucker_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT jsonb_agg(row_to_json(t))
    INTO v_results
    FROM (
        SELECT
            t.id,
            t.load_id,
            t.truck_id,
            t.stage,
            t.assigned_at,
            t.delivered_at,
            t.pod_uploaded_at,
            t.completed_at,
            t.lr_document_path,
            t.pod_document_path,
            t.load_snapshot_summary,
            jsonb_build_object(
                'origin_label', l.origin_label,
                'origin_lat', l.origin_lat,
                'origin_lng', l.origin_lng,
                'destination_label', l.destination_label,
                'destination_lat', l.destination_lat,
                'destination_lng', l.destination_lng,
                'material', l.material
            ) AS loads,
            jsonb_build_object(
                'truck_number', tr.truck_number
            ) AS trucks
        FROM trips t
        JOIN loads l ON l.id = t.load_id
        LEFT JOIN trucks tr ON tr.id = t.truck_id
        WHERE t.trucker_id = v_caller
          AND (
              p_stage_filter IS NULL
              OR p_stage_filter = '{}'
              OR t.stage::TEXT = ANY (p_stage_filter)
          )
        ORDER BY t.assigned_at DESC
        LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 15), 100))
        OFFSET GREATEST(COALESCE(p_offset, 0), 0)
    ) t;

    RETURN COALESCE(v_results, '[]'::JSONB);
END;
$$;

-- ─── get_trip_detail ───
CREATE OR REPLACE FUNCTION public.get_trip_detail(
    p_trip_id UUID,
    p_trucker_id UUID
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
    IF p_trucker_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT row_to_json(t)::JSONB
    INTO v_result
    FROM (
        SELECT
            t.id,
            t.load_id,
            t.supplier_id,
            t.truck_id,
            t.stage,
            t.assigned_at,
            t.started_at,
            t.delivered_at,
            t.pod_uploaded_at,
            t.completed_at,
            t.lr_document_path,
            t.pod_document_path,
            t.load_snapshot_summary,
            jsonb_build_object(
                'origin_label', l.origin_label,
                'origin_city', l.origin_city,
                'origin_state', l.origin_state,
                'origin_lat', l.origin_lat,
                'origin_lng', l.origin_lng,
                'destination_label', l.destination_label,
                'destination_city', l.destination_city,
                'destination_state', l.destination_state,
                'destination_lat', l.destination_lat,
                'destination_lng', l.destination_lng,
                'route_distance_km', l.route_distance_km,
                'route_duration_minutes', l.route_duration_minutes,
                'route_snapshot_source', l.route_snapshot_source,
                'material', l.material,
                'pickup_date', l.pickup_date
            ) AS loads,
            jsonb_build_object(
                'truck_number', tr.truck_number,
                'body_type', tr.body_type,
                'tyres', tr.tyres
            ) AS trucks
        FROM trips t
        JOIN loads l ON l.id = t.load_id
        LEFT JOIN trucks tr ON tr.id = t.truck_id
        WHERE t.id = p_trip_id
          AND t.trucker_id = v_caller
    ) t;

    RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$;

-- ─── get_trip_detail_with_supplier ───
CREATE OR REPLACE FUNCTION public.get_trip_detail_with_supplier(
    p_trip_id UUID,
    p_trucker_id UUID
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
    IF p_trucker_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

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
            'mobile', CASE
                WHEN p.mobile IS NOT NULL THEN OVERLAY(p.mobile PLACING '****' FROM 3 FOR 4)
                ELSE NULL
            END,
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
    WHERE t.id = p_trip_id
      AND t.trucker_id = v_caller;

    RETURN v_result;
END;
$$;

-- ─── get_trucker_dashboard_stats ───
CREATE OR REPLACE FUNCTION public.get_trucker_dashboard_stats(p_trucker_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
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
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_trucker_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT COUNT(*) INTO v_active_bids FROM public.booking_requests
    WHERE trucker_id = v_caller AND status = 'submitted';

    SELECT COUNT(*) INTO v_upcoming_trips FROM public.trips
    WHERE trucker_id = v_caller AND stage IN ('assigned', 'pickup_pending', 'picked_up');

    SELECT COUNT(*) INTO v_in_transit_trips FROM public.trips
    WHERE trucker_id = v_caller AND stage = 'in_transit';

    SELECT COUNT(*) INTO v_completed_trips FROM public.trips
    WHERE trucker_id = v_caller AND stage = 'completed';

    SELECT COUNT(*) INTO v_total_trucks FROM public.trucks
    WHERE owner_id = v_caller;

    SELECT COUNT(*) INTO v_approved_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'verified';

    SELECT COUNT(*) INTO v_pending_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'pending';

    SELECT COUNT(*) INTO v_rejected_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'rejected';

    SELECT COUNT(*) INTO v_pending_approval_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'edited_pending_reapproval';

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

-- ─── get_supplier_linked_trips ───
CREATE OR REPLACE FUNCTION public.get_supplier_linked_trips(
    p_load_id UUID,
    p_supplier_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_results JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_supplier_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT jsonb_agg(row_to_json(t))
    INTO v_results
    FROM (
        SELECT
            t.id,
            t.load_id,
            t.trucker_id,
            t.truck_id,
            t.stage,
            t.assigned_at,
            t.delivered_at,
            t.pod_uploaded_at,
            t.completed_at,
            t.lr_document_path,
            t.pod_document_path,
            jsonb_build_object(
                'id', l.id,
                'parent_load_id', l.parent_load_id,
                'origin_label', l.origin_label,
                'destination_label', l.destination_label,
                'material', l.material
            ) AS loads
        FROM trips t
        JOIN loads l ON l.id = t.load_id
        WHERE t.supplier_id = v_caller
          AND (
              t.load_id = p_load_id
              OR l.parent_load_id = p_load_id
          )
        ORDER BY t.assigned_at DESC
    ) t;

    RETURN COALESCE(v_results, '[]'::JSONB);
END;
$$;

-- ─── get_support_tickets ───
CREATE OR REPLACE FUNCTION public.get_support_tickets(
    p_user_id UUID,
    p_limit INT DEFAULT 20,
    p_before_updated_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_results JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT jsonb_agg(row_to_json(t))
    INTO v_results
    FROM (
        SELECT
            id,
            category,
            status,
            priority,
            related_load_id,
            related_trip_id,
            resolution_summary,
            created_at,
            updated_at,
            resolved_at
        FROM support_tickets
        WHERE owner_profile_id = v_caller
          AND (
              p_before_updated_at IS NULL
              OR updated_at < p_before_updated_at
          )
        ORDER BY updated_at DESC
        LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 20), 100))
    ) t;

    RETURN COALESCE(v_results, '[]'::JSONB);
END;
$$;

-- ─── get_support_ticket_detail ───
CREATE OR REPLACE FUNCTION public.get_support_ticket_detail(
    p_ticket_id UUID,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_ticket JSONB;
    v_messages JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT row_to_json(t)::JSONB
    INTO v_ticket
    FROM (
        SELECT
            id,
            category,
            status,
            priority,
            related_load_id,
            related_trip_id,
            resolution_summary,
            created_at,
            updated_at,
            resolved_at
        FROM support_tickets
        WHERE id = p_ticket_id
          AND owner_profile_id = v_caller
    ) t;

    IF v_ticket IS NULL THEN
        RAISE EXCEPTION 'Ticket not found or access denied';
    END IF;

    SELECT jsonb_agg(row_to_json(m))
    INTO v_messages
    FROM (
        SELECT
            id,
            support_ticket_id,
            sender_profile_id,
            sender_admin_user_id,
            message_body,
            attachment_path,
            visibility_class,
            created_at
        FROM support_ticket_messages
        WHERE support_ticket_id = p_ticket_id
        ORDER BY created_at ASC
        LIMIT 50
    ) m;

    RETURN jsonb_build_object(
        'ticket', COALESCE(v_ticket, '{}'::JSONB),
        'messages', COALESCE(v_messages, '[]'::JSONB)
    );
END;
$$;

-- ─── get_support_ticket_messages ───
CREATE OR REPLACE FUNCTION public.get_support_ticket_messages(
    p_ticket_id UUID,
    p_user_id UUID,
    p_limit INT DEFAULT 50,
    p_before_created_at TIMESTAMPTZ DEFAULT NULL,
    p_before_message_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_results JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM support_tickets
        WHERE id = p_ticket_id
          AND owner_profile_id = v_caller
    ) THEN
        RAISE EXCEPTION 'Ticket not found or access denied';
    END IF;

    SELECT jsonb_agg(row_to_json(m))
    INTO v_results
    FROM (
        SELECT
            id,
            support_ticket_id,
            sender_profile_id,
            sender_admin_user_id,
            message_body,
            attachment_path,
            visibility_class,
            created_at
        FROM support_ticket_messages
        WHERE support_ticket_id = p_ticket_id
          AND (
              p_before_created_at IS NULL
              OR (
                  created_at < p_before_created_at
                  OR (
                      created_at = p_before_created_at
                      AND (p_before_message_id IS NULL OR id < p_before_message_id)
                  )
              )
          )
        ORDER BY created_at DESC, id DESC
        LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 50), 100))
    ) m;

    RETURN COALESCE(v_results, '[]'::JSONB);
END;
$$;
