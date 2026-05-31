-- P0-3: Bind caller identity on supplier trip + notification preference RPCs (IDOR fix).

-- ─── get_supplier_trip_detail ───
CREATE OR REPLACE FUNCTION public.get_supplier_trip_detail(
    p_trip_id UUID,
    p_supplier_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_trip JSONB;
    v_trucker_profile JSONB;
    v_load_snapshot JSONB;
    v_truck JSONB;
    v_dispute_summary JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF p_supplier_id IS DISTINCT FROM v_caller THEN
        RAISE EXCEPTION 'forbidden';
    END IF;

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
    WHERE t.id = p_trip_id
      AND t.supplier_id = v_caller;

    IF v_trip IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'mobile', CASE
            WHEN p.mobile IS NOT NULL THEN OVERLAY(p.mobile PLACING '****' FROM 3 FOR 4)
            ELSE NULL
        END,
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

-- ─── get_supplier_trips ───
CREATE OR REPLACE FUNCTION public.get_supplier_trips(
    p_supplier_id UUID,
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
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF p_supplier_id IS DISTINCT FROM v_caller THEN
        RAISE EXCEPTION 'forbidden';
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
        WHERE t.supplier_id = v_caller
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

-- ─── get_notification_preferences ───
CREATE OR REPLACE FUNCTION public.get_notification_preferences(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_preferences JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller THEN
        RAISE EXCEPTION 'forbidden';
    END IF;

    SELECT jsonb_build_object(
        'user_id', np.user_id,
        'load_booking_enabled', np.load_booking_enabled,
        'load_status_updates_enabled', np.load_status_updates_enabled,
        'trip_updates_enabled', np.trip_updates_enabled,
        'chat_messages_enabled', np.chat_messages_enabled,
        'review_notifications_enabled', np.review_notifications_enabled,
        'support_responses_enabled', np.support_responses_enabled,
        'system_notifications_enabled', np.system_notifications_enabled,
        'push_enabled', np.push_enabled,
        'in_app_enabled', np.in_app_enabled,
        'email_enabled', np.email_enabled,
        'quiet_hours_enabled', np.quiet_hours_enabled,
        'quiet_hours_start', np.quiet_hours_start,
        'quiet_hours_end', np.quiet_hours_end,
        'quiet_hours_timezone', np.quiet_hours_timezone,
        'auto_dismiss_enabled', np.auto_dismiss_enabled,
        'auto_dismiss_after_hours', np.auto_dismiss_after_hours,
        'delivery_tracking_enabled', np.delivery_tracking_enabled,
        'created_at', np.created_at,
        'updated_at', np.updated_at
    ) INTO v_preferences
    FROM public.notification_preferences np
    WHERE np.user_id = v_caller;

    IF v_preferences IS NULL THEN
        RETURN jsonb_build_object(
            'user_id', v_caller,
            'load_booking_enabled', true,
            'load_status_updates_enabled', true,
            'trip_updates_enabled', true,
            'chat_messages_enabled', true,
            'review_notifications_enabled', true,
            'support_responses_enabled', true,
            'system_notifications_enabled', true,
            'push_enabled', true,
            'in_app_enabled', true,
            'email_enabled', false,
            'quiet_hours_enabled', false,
            'quiet_hours_start', '22:00',
            'quiet_hours_end', '08:00',
            'quiet_hours_timezone', 'Asia/Kolkata',
            'auto_dismiss_enabled', true,
            'auto_dismiss_after_hours', 24,
            'delivery_tracking_enabled', true,
            'created_at', NOW(),
            'updated_at', NOW()
        );
    END IF;

    RETURN v_preferences;
END;
$$;

-- ─── update_notification_preferences ───
CREATE OR REPLACE FUNCTION public.update_notification_preferences(
    p_user_id UUID,
    p_load_booking_enabled BOOLEAN DEFAULT NULL,
    p_load_status_updates_enabled BOOLEAN DEFAULT NULL,
    p_trip_updates_enabled BOOLEAN DEFAULT NULL,
    p_chat_messages_enabled BOOLEAN DEFAULT NULL,
    p_review_notifications_enabled BOOLEAN DEFAULT NULL,
    p_support_responses_enabled BOOLEAN DEFAULT NULL,
    p_system_notifications_enabled BOOLEAN DEFAULT NULL,
    p_push_enabled BOOLEAN DEFAULT NULL,
    p_in_app_enabled BOOLEAN DEFAULT NULL,
    p_email_enabled BOOLEAN DEFAULT NULL,
    p_quiet_hours_enabled BOOLEAN DEFAULT NULL,
    p_quiet_hours_start TIME DEFAULT NULL,
    p_quiet_hours_end TIME DEFAULT NULL,
    p_quiet_hours_timezone TEXT DEFAULT NULL,
    p_auto_dismiss_enabled BOOLEAN DEFAULT NULL,
    p_auto_dismiss_after_hours INT DEFAULT NULL,
    p_delivery_tracking_enabled BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_preferences JSONB;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller THEN
        RAISE EXCEPTION 'forbidden';
    END IF;

    INSERT INTO public.notification_preferences (
        user_id,
        load_booking_enabled,
        load_status_updates_enabled,
        trip_updates_enabled,
        chat_messages_enabled,
        review_notifications_enabled,
        support_responses_enabled,
        system_notifications_enabled,
        push_enabled,
        in_app_enabled,
        email_enabled,
        quiet_hours_enabled,
        quiet_hours_start,
        quiet_hours_end,
        quiet_hours_timezone,
        auto_dismiss_enabled,
        auto_dismiss_after_hours,
        delivery_tracking_enabled
    ) VALUES (
        v_caller,
        COALESCE(p_load_booking_enabled, true),
        COALESCE(p_load_status_updates_enabled, true),
        COALESCE(p_trip_updates_enabled, true),
        COALESCE(p_chat_messages_enabled, true),
        COALESCE(p_review_notifications_enabled, true),
        COALESCE(p_support_responses_enabled, true),
        COALESCE(p_system_notifications_enabled, true),
        COALESCE(p_push_enabled, true),
        COALESCE(p_in_app_enabled, true),
        COALESCE(p_email_enabled, false),
        COALESCE(p_quiet_hours_enabled, false),
        COALESCE(p_quiet_hours_start, '22:00'),
        COALESCE(p_quiet_hours_end, '08:00'),
        COALESCE(p_quiet_hours_timezone, 'Asia/Kolkata'),
        COALESCE(p_auto_dismiss_enabled, true),
        COALESCE(p_auto_dismiss_after_hours, 24),
        COALESCE(p_delivery_tracking_enabled, true)
    )
    ON CONFLICT (user_id) DO UPDATE SET
        load_booking_enabled = COALESCE(EXCLUDED.load_booking_enabled, notification_preferences.load_booking_enabled),
        load_status_updates_enabled = COALESCE(EXCLUDED.load_status_updates_enabled, notification_preferences.load_status_updates_enabled),
        trip_updates_enabled = COALESCE(EXCLUDED.trip_updates_enabled, notification_preferences.trip_updates_enabled),
        chat_messages_enabled = COALESCE(EXCLUDED.chat_messages_enabled, notification_preferences.chat_messages_enabled),
        review_notifications_enabled = COALESCE(EXCLUDED.review_notifications_enabled, notification_preferences.review_notifications_enabled),
        support_responses_enabled = COALESCE(EXCLUDED.support_responses_enabled, notification_preferences.support_responses_enabled),
        system_notifications_enabled = COALESCE(EXCLUDED.system_notifications_enabled, notification_preferences.system_notifications_enabled),
        push_enabled = COALESCE(EXCLUDED.push_enabled, notification_preferences.push_enabled),
        in_app_enabled = COALESCE(EXCLUDED.in_app_enabled, notification_preferences.in_app_enabled),
        email_enabled = COALESCE(EXCLUDED.email_enabled, notification_preferences.email_enabled),
        quiet_hours_enabled = COALESCE(EXCLUDED.quiet_hours_enabled, notification_preferences.quiet_hours_enabled),
        quiet_hours_start = COALESCE(EXCLUDED.quiet_hours_start, notification_preferences.quiet_hours_start),
        quiet_hours_end = COALESCE(EXCLUDED.quiet_hours_end, notification_preferences.quiet_hours_end),
        quiet_hours_timezone = COALESCE(EXCLUDED.quiet_hours_timezone, notification_preferences.quiet_hours_timezone),
        auto_dismiss_enabled = COALESCE(EXCLUDED.auto_dismiss_enabled, notification_preferences.auto_dismiss_enabled),
        auto_dismiss_after_hours = COALESCE(EXCLUDED.auto_dismiss_after_hours, notification_preferences.auto_dismiss_after_hours),
        delivery_tracking_enabled = COALESCE(EXCLUDED.delivery_tracking_enabled, notification_preferences.delivery_tracking_enabled),
        updated_at = NOW();

    RETURN public.get_notification_preferences(v_caller);
END;
$$;
