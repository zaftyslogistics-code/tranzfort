create type "public"."body_type" as enum ('open', 'container', 'trailer', 'tanker', 'refrigerated');

create type "public"."payout_status" as enum ('pending', 'verified', 'rejected');

create type "public"."super_status" as enum ('none', 'requested', 'processing', 'assigned', 'in_transit', 'pod_uploaded', 'completed');

create type "public"."super_trucker_status" as enum ('none', 'pending', 'approved', 'rejected');

create type "public"."ticket_priority" as enum ('low', 'medium', 'high', 'urgent');

create type "public"."ticket_status" as enum ('open', 'in_progress', 'resolved', 'closed');

drop function if exists "public"."get_conversation_summary"(p_conversation_id uuid);


  create table "public"."feature_flags" (
    "name" text not null,
    "enabled" boolean not null default false,
    "updated_at" timestamp without time zone not null default now()
      );


alter table "public"."feature_flags" enable row level security;


  create table "public"."notification_digests" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "route_key" text not null,
    "route_label" text,
    "digest_count" integer not null default 1,
    "sample_body" text,
    "first_notification_at" timestamp with time zone not null default now(),
    "last_notification_at" timestamp with time zone not null default now(),
    "next_dispatch_at" timestamp with time zone not null default (now() + '00:30:00'::interval),
    "is_dispatched" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."notification_digests" enable row level security;


  create table "public"."user_saved_searches" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "origin_city" text,
    "destination_city" text,
    "material" text,
    "truck_type" text,
    "sort_by" text not null default 'newest'::text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."user_saved_searches" enable row level security;

CREATE UNIQUE INDEX feature_flags_pkey ON public.feature_flags USING btree (name);

CREATE INDEX idx_notification_digests_ready ON public.notification_digests USING btree (is_dispatched, next_dispatch_at);

CREATE INDEX idx_user_saved_searches_user ON public.user_saved_searches USING btree (user_id, updated_at DESC);

CREATE UNIQUE INDEX notification_digests_pkey ON public.notification_digests USING btree (id);

CREATE UNIQUE INDEX uq_open_notification_digest ON public.notification_digests USING btree (user_id, route_key) WHERE (is_dispatched = false);

CREATE UNIQUE INDEX user_saved_searches_pkey ON public.user_saved_searches USING btree (id);

alter table "public"."feature_flags" add constraint "feature_flags_pkey" PRIMARY KEY using index "feature_flags_pkey";

alter table "public"."notification_digests" add constraint "notification_digests_pkey" PRIMARY KEY using index "notification_digests_pkey";

alter table "public"."user_saved_searches" add constraint "user_saved_searches_pkey" PRIMARY KEY using index "user_saved_searches_pkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.admin_force_assign_super_load(p_parent_load_id uuid, p_trucker_id uuid, p_truck_id uuid, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_parent RECORD;
    v_truck RECORD;
    v_child_id UUID;
BEGIN
    SELECT * INTO v_parent FROM public.loads WHERE id = p_parent_load_id FOR UPDATE;
    
    IF v_parent IS NULL OR v_parent.parent_load_id IS NOT NULL OR v_parent.is_super_load = FALSE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid parent super load');
    END IF;
    
    IF v_parent.status != 'active' OR v_parent.trucks_booked >= v_parent.trucks_needed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load not active or fully booked');
    END IF;

    SELECT * INTO v_truck FROM public.trucks
    WHERE id = p_truck_id AND owner_id = p_trucker_id AND status = 'verified';

    IF v_truck IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Truck not verified');
    END IF;

    -- 1. Create Child Load already in 'booked' state
    INSERT INTO public.loads (
        supplier_id, parent_load_id,
        origin_city, origin_state, dest_city, dest_state,
        origin_lat, origin_lng, dest_lat, dest_lng, distance_km, duration_hours, route_polyline,
        material, weight_tonnes, price, price_type, advance_percentage, pickup_date,
        status, is_super_load, super_status, trucks_needed, trucks_booked,
        assigned_trucker_id, assigned_truck_id, assigned_by, booking_truck_snapshot
    ) VALUES (
        v_parent.supplier_id, v_parent.id,
        v_parent.origin_city, v_parent.origin_state, v_parent.dest_city, v_parent.dest_state,
        v_parent.origin_lat, v_parent.origin_lng, v_parent.dest_lat, v_parent.dest_lng, v_parent.distance_km, v_parent.duration_hours, v_parent.route_polyline,
        v_parent.material, v_parent.weight_tonnes, v_parent.price, v_parent.price_type, v_parent.advance_percentage, v_parent.pickup_date,
        'booked', true, 'assigned', 1, 1,
        p_trucker_id, p_truck_id, p_admin_id,
        jsonb_build_object('truck_number', v_truck.truck_number, 'body_type', v_truck.body_type::text)
    ) RETURNING id INTO v_child_id;

    -- 2. Create Trip
    INSERT INTO public.trips (load_id, trucker_id, truck_id, stage)
    VALUES (v_child_id, p_trucker_id, p_truck_id, 'at_pickup');

    -- 3. Update Parent Load
    UPDATE public.loads SET
        trucks_booked = trucks_booked + 1,
        status = CASE WHEN trucks_booked + 1 >= trucks_needed THEN 'booked'::load_status ELSE status END,
        super_status = 'assigned',
        updated_at = NOW()
    WHERE id = p_parent_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', v_child_id);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_in_app_notification(p_user_id uuid, p_title text, p_body text, p_type text, p_data jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF p_user_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  VALUES (p_user_id, p_title, p_body, p_type, COALESCE(p_data, '{}'::jsonb));
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enqueue_notification_digest()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_route_key TEXT;
  v_route_label TEXT;
BEGIN
  v_route_key := NULLIF(COALESCE(NEW.data->>'route_key', NEW.data->>'route', ''), '');
  v_route_label := NULLIF(COALESCE(NEW.data->>'route_label', NEW.data->>'route', ''), '');

  IF v_route_key IS NULL THEN
    v_route_key := NEW.type;
  END IF;

  INSERT INTO public.notification_digests (
    user_id,
    route_key,
    route_label,
    digest_count,
    sample_body,
    first_notification_at,
    last_notification_at,
    next_dispatch_at,
    is_dispatched,
    updated_at
  )
  VALUES (
    NEW.user_id,
    v_route_key,
    v_route_label,
    1,
    NEW.body,
    NEW.created_at,
    NEW.created_at,
    NEW.created_at + INTERVAL '30 minutes',
    FALSE,
    NOW()
  )
  ON CONFLICT (user_id, route_key) WHERE is_dispatched = FALSE
  DO UPDATE
  SET
    digest_count = public.notification_digests.digest_count + 1,
    sample_body = EXCLUDED.sample_body,
    last_notification_at = EXCLUDED.last_notification_at,
    next_dispatch_at = LEAST(
      public.notification_digests.next_dispatch_at,
      EXCLUDED.next_dispatch_at
    ),
    updated_at = NOW();

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_current_user_profile()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(p)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      full_name,
      mobile,
      email,
      user_role_type,
      preferred_language,
      is_banned,
      account_deletion_status,
      trust_safety_status,
      ban_reason,
      data_deletion_requested_at,
      avatar_url,
      profile_photo_document_path
    FROM profiles
    WHERE id = v_user_id
  ) p;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_own_rating(p_reviewer_id uuid, p_load_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT id, score, comment, created_at
    FROM ratings
    WHERE reviewer_id = p_reviewer_id
      AND load_id = p_load_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_ready_notification_digests(p_now timestamp with time zone DEFAULT now())
 RETURNS TABLE(id uuid, user_id uuid, route_key text, route_label text, digest_count integer, sample_body text, first_notification_at timestamp with time zone, last_notification_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  SELECT
    d.id,
    d.user_id,
    d.route_key,
    d.route_label,
    d.digest_count,
    d.sample_body,
    d.first_notification_at,
    d.last_notification_at
  FROM public.notification_digests d
  WHERE d.is_dispatched = FALSE
    AND d.next_dispatch_at <= p_now
  ORDER BY d.next_dispatch_at ASC;
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_extension(p_supplier_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(s)::jsonb
  INTO v_result
  FROM (
    SELECT id, company_name
    FROM suppliers
    WHERE id = p_supplier_id
  ) s;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_linked_trips(p_load_id uuid, p_supplier_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
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
      ) as loads
    FROM trips t
    JOIN loads l ON l.id = t.load_id
    WHERE t.supplier_id = p_supplier_id
      AND (
        t.load_id = p_load_id
        OR l.parent_load_id = p_load_id
      )
    ORDER BY t.assigned_at DESC
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_load_detail(p_load_id uuid, p_supplier_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      parent_load_id,
      origin_label,
      origin_city,
      origin_state,
      origin_lat,
      origin_lng,
      destination_label,
      destination_city,
      destination_state,
      destination_lat,
      destination_lng,
      route_distance_km,
      route_duration_minutes,
      route_polyline,
      route_snapshot_source,
      material,
      weight_tonnes,
      required_body_type,
      required_tyres,
      trucks_needed,
      trucks_booked,
      price_amount,
      price_type,
      advance_percentage,
      pickup_date,
      status,
      is_super_load,
      super_status,
      assigned_trucker_id,
      assigned_truck_id,
      published_at,
      created_at,
      updated_at
    FROM loads
    WHERE id = p_load_id
      AND supplier_id = p_supplier_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_loads_list(p_supplier_id uuid, p_status_filter text[] DEFAULT NULL::text[], p_search_query text DEFAULT NULL::text, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_results
  FROM (
    SELECT
      id,
      origin_label,
      destination_label,
      material,
      weight_tonnes,
      trucks_needed,
      trucks_booked,
      price_amount,
      price_type,
      pickup_date,
      status,
      required_body_type,
      required_tyres,
      is_super_load,
      super_status,
      published_at
    FROM loads
    WHERE supplier_id = p_supplier_id
      AND (
        p_status_filter IS NULL
        OR p_status_filter = '{}'
        OR status::text = ANY(p_status_filter)
      )
      AND (
        p_search_query IS NULL
        OR p_search_query = ''
        OR material ILIKE '%' || p_search_query || '%'
        OR origin_city ILIKE '%' || p_search_query || '%'
        OR destination_city ILIKE '%' || p_search_query || '%'
        OR origin_label ILIKE '%' || p_search_query || '%'
        OR destination_label ILIKE '%' || p_search_query || '%'
      )
    ORDER BY pickup_date DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_trips(p_supplier_id uuid, p_stage_filter text[] DEFAULT NULL::text[], p_limit integer DEFAULT 15, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
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
      ) as loads,
      jsonb_build_object(
        'truck_number', tr.truck_number
      ) as trucks
    FROM trips t
    JOIN loads l ON l.id = t.load_id
    LEFT JOIN trucks tr ON tr.id = t.truck_id
    WHERE t.supplier_id = p_supplier_id
      AND (
        p_stage_filter IS NULL
        OR p_stage_filter = '{}'
        OR t.stage::text = ANY(p_stage_filter)
      )
    ORDER BY t.assigned_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_support_ticket_detail(p_ticket_id uuid, p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_ticket JSONB;
  v_messages JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(t)::jsonb
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
      AND owner_profile_id = p_user_id
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
    'ticket', COALESCE(v_ticket, '{}'::jsonb),
    'messages', COALESCE(v_messages, '[]'::jsonb)
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_support_ticket_messages(p_ticket_id uuid, p_user_id uuid, p_limit integer DEFAULT 50, p_before_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_before_message_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM support_tickets
    WHERE id = p_ticket_id AND owner_profile_id = p_user_id
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
    LIMIT p_limit
  ) m;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_support_tickets(p_user_id uuid, p_limit integer DEFAULT 20, p_before_updated_at timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
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
    WHERE owner_profile_id = p_user_id
      AND (
        p_before_updated_at IS NULL
        OR updated_at < p_before_updated_at
      )
    ORDER BY updated_at DESC
    LIMIT p_limit
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_trip_detail(p_trip_id uuid, p_trucker_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(t)::jsonb
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
      ) as loads,
      jsonb_build_object(
        'truck_number', tr.truck_number,
        'body_type', tr.body_type,
        'tyres', tr.tyres
      ) as trucks
    FROM trips t
    JOIN loads l ON l.id = t.load_id
    LEFT JOIN trucks tr ON tr.id = t.truck_id
    WHERE t.id = p_trip_id
      AND t.trucker_id = p_trucker_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_trucker_trips(p_trucker_id uuid, p_stage_filter text[] DEFAULT NULL::text[], p_limit integer DEFAULT 15, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
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
      ) as loads,
      jsonb_build_object(
        'truck_number', tr.truck_number
      ) as trucks
    FROM trips t
    JOIN loads l ON l.id = t.load_id
    LEFT JOIN trucks tr ON tr.id = t.truck_id
    WHERE t.trucker_id = p_trucker_id
      AND (
        p_stage_filter IS NULL
        OR p_stage_filter = '{}'
        OR t.stage::text = ANY(p_stage_filter)
      )
    ORDER BY t.assigned_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.mark_notification_digest_dispatched(p_digest_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE public.notification_digests
  SET is_dispatched = TRUE,
      updated_at = NOW()
  WHERE id = p_digest_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_document_expiry_updates()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF TG_TABLE_NAME = 'truckers' THEN
    IF NEW.dl_expiry_date IS NOT NULL
      AND NEW.dl_expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days')
      AND (OLD IS NULL OR OLD.dl_expiry_date IS DISTINCT FROM NEW.dl_expiry_date) THEN
      INSERT INTO public.notifications (user_id, title, body, type, data)
      VALUES (
        NEW.id,
        'Driving licence expiry reminder',
        format('Your driving licence will expire on %s. Please renew it to avoid trip interruptions.', NEW.dl_expiry_date),
        'doc_expiry_warning',
        jsonb_build_object('doc', 'dl', 'expiry_date', NEW.dl_expiry_date)
      );
    END IF;
  ELSIF TG_TABLE_NAME = 'trucks' THEN
    IF NEW.rc_expiry_date IS NOT NULL
      AND NEW.rc_expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days')
      AND (OLD IS NULL OR OLD.rc_expiry_date IS DISTINCT FROM NEW.rc_expiry_date) THEN
      INSERT INTO public.notifications (user_id, title, body, type, data)
      VALUES (
        NEW.owner_id,
        'RC expiry reminder',
        format('RC for truck %s will expire on %s. Please renew it in time.', COALESCE(NEW.truck_number, '-'), NEW.rc_expiry_date),
        'doc_expiry_warning',
        jsonb_build_object(
          'doc', 'rc',
          'truck_id', NEW.id,
          'truck_number', NEW.truck_number,
          'expiry_date', NEW.rc_expiry_date
        )
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_on_booking_request()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF NEW.parent_load_id IS NOT NULL AND NEW.status = 'pending_approval' THEN
    PERFORM public.create_in_app_notification(
      NEW.supplier_id,
      'New Booking Request',
      'A trucker requested booking for your load.',
      'booking_new',
      jsonb_build_object('load_id', NEW.id)
    );
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_on_booking_status_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF OLD.status = 'pending_approval' AND NEW.status = 'booked' THEN
    PERFORM public.create_in_app_notification(
      NEW.assigned_trucker_id,
      'Booking Approved!',
      'Your booking request was approved.',
      'booking_approved',
      jsonb_build_object('load_id', NEW.id)
    );
  ELSIF OLD.status = 'pending_approval' AND NEW.status = 'cancelled' THEN
    PERFORM public.create_in_app_notification(
      NEW.assigned_trucker_id,
      'Booking Rejected',
      'Your booking request was rejected.',
      'booking_rejected',
      jsonb_build_object('load_id', NEW.id)
    );
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_on_trip_stage_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_supplier_id UUID;
BEGIN
  IF OLD.stage IS DISTINCT FROM NEW.stage THEN
    SELECT supplier_id INTO v_supplier_id
    FROM public.loads
    WHERE id = NEW.load_id;

    IF NEW.stage = 'pod_uploaded' THEN
      PERFORM public.create_in_app_notification(
        v_supplier_id,
        'Proof of Delivery Uploaded',
        'POD was uploaded for your load.',
        'pod_uploaded',
        jsonb_build_object('load_id', NEW.load_id, 'trip_id', NEW.id)
      );
    ELSIF NEW.stage = 'completed' THEN
      PERFORM public.create_in_app_notification(
        NEW.trucker_id,
        'Delivery Confirmed',
        'Supplier confirmed delivery completion.',
        'delivery_confirmed',
        jsonb_build_object('load_id', NEW.load_id, 'trip_id', NEW.id)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_on_verification_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF OLD.verification_status IS DISTINCT FROM NEW.verification_status THEN
    IF NEW.verification_status = 'verified' THEN
      PERFORM public.create_in_app_notification(
        NEW.id,
        'Account Verified',
        'Your account verification is complete.',
        'verification_done',
        '{}'::jsonb
      );
    ELSIF NEW.verification_status = 'rejected' THEN
      PERFORM public.create_in_app_notification(
        NEW.id,
        'Verification Failed',
        COALESCE(NEW.verification_rejection_reason, 'Please review and re-submit your documents.'),
        'verification_failed',
        jsonb_build_object('reason', NEW.verification_rejection_reason)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.record_user_consent(p_consent_type text DEFAULT 'terms_of_service'::text, p_consent_version text DEFAULT 'v1'::text, p_source_context text DEFAULT 'onboarding_profile'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  INSERT INTO user_consents (
    profile_id,
    consent_type,
    consent_version,
    source_context
  ) VALUES (
    v_user_id,
    p_consent_type,
    p_consent_version,
    p_source_context
  )
  ON CONFLICT DO NOTHING;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.reject_booking(p_child_load_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_child RECORD;
BEGIN
    SELECT * INTO v_child
    FROM public.loads
    WHERE id = p_child_load_id
      AND parent_load_id IS NOT NULL
    FOR UPDATE;

    IF v_child IS NULL OR v_child.status <> 'pending_approval' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid child load');
    END IF;

    -- 1) Cancel Child Load
    UPDATE public.loads
    SET status = 'cancelled', updated_at = NOW()
    WHERE id = p_child_load_id;

    -- 2) Decrement Parent Load counters
    UPDATE public.loads
    SET trucks_booked = GREATEST(trucks_booked - 1, 0),
        status = 'active',
        updated_at = NOW()
    WHERE id = v_child.parent_load_id;

    RETURN jsonb_build_object('success', true);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.start_trip(p_trip_id uuid, p_lat double precision, p_lng double precision)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_trip RECORD;
BEGIN
    SELECT * INTO v_trip FROM public.trips WHERE id = p_trip_id FOR UPDATE;

    IF v_trip IS NULL OR v_trip.stage <> 'at_pickup' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid trip state');
    END IF;

    UPDATE public.trips SET
        stage = 'in_transit',
        start_time = NOW(),
        last_known_lat = p_lat,
        last_known_lng = p_lng,
        last_location_at = NOW(),
        updated_at = NOW()
    WHERE id = p_trip_id;

    UPDATE public.loads SET
        status = 'in_transit',
        super_status = CASE WHEN is_super_load THEN 'in_transit'::super_status ELSE super_status END,
        updated_at = NOW()
    WHERE id = v_trip.load_id;

    RETURN jsonb_build_object('success', true);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.conversations
    SET last_message_at = NEW.created_at,
        last_message_text = CASE
            WHEN NEW.message_type = 'text' THEN LEFT(NEW.text_content, 100)
            WHEN NEW.message_type = 'voice' THEN 'Voice message'
            WHEN NEW.message_type = 'map_card' THEN 'Route shared'
            WHEN NEW.message_type = 'location' THEN 'Location shared'
            ELSE 'New message'
        END
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_trip_lr(p_trip_id uuid, p_lr_document_path text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE trips
  SET lr_document_path = p_lr_document_path
  WHERE id = p_trip_id
    AND stage IN ('pickup_pending', 'picked_up')
  RETURNING row_to_json(t)::jsonb INTO v_result;

  RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.activate_super_load(p_load_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status != 'approved_payment_pending' THEN
    RAISE EXCEPTION 'Only approved payment-pending Super Loads can be activated';
  END IF;

  UPDATE loads
  SET is_super_load = TRUE,
      super_status = 'active',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'load',
    p_load_id,
    'Super Load activated after payment confirmation',
    jsonb_build_object(
      'super_status', 'active'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'super_load_update',
    'high',
    'Super Load Active!',
    'Your ' || v_load.material || ' load is now a Super Load',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_reply_to_review(p_review_id uuid, p_reply text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    v_reviewed_user_id uuid;
    v_current_user_id uuid;
    v_existing_reply text;
begin
    v_current_user_id := auth.uid();
    if v_current_user_id is null then
        return false;
    end if;
    
    -- Validate reply length
    if p_reply is null or length(trim(p_reply)) = 0 then
        return false;
    end if;
    if length(p_reply) > 500 then
        return false;
    end if;
    
    -- Check if user is the reviewed user and no reply exists yet
    update reviews 
    set reply = trim(p_reply),
        reply_at = now()
    where id = p_review_id 
      and reviewed_user_id = v_current_user_id
      and reply is null;
    
    return found;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_force_assign_super_load(p_parent_load_id uuid, p_trucker_id uuid, p_truck_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_parent RECORD;
  v_truck RECORD;
  v_child_load_id UUID;
  v_trip_id UUID;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_parent
  FROM loads
  WHERE id = p_parent_load_id
  FOR UPDATE;

  IF v_parent IS NULL OR v_parent.parent_load_id IS NOT NULL THEN
    RAISE EXCEPTION 'Invalid Super Load parent';
  END IF;

  IF v_parent.is_super_load IS DISTINCT FROM TRUE OR v_parent.super_status != 'active' THEN
    RAISE EXCEPTION 'Super Load is not active';
  END IF;

  IF v_parent.status != 'active' OR v_parent.trucks_booked >= v_parent.trucks_needed THEN
    RAISE EXCEPTION 'Load is not available for force assignment';
  END IF;

  SELECT * INTO v_truck
  FROM trucks
  WHERE id = p_truck_id
    AND owner_id = p_trucker_id
    AND status = 'verified';

  IF v_truck IS NULL THEN
    RAISE EXCEPTION 'Truck is not verified for the selected trucker';
  END IF;

  INSERT INTO loads (
    supplier_id,
    parent_load_id,
    origin_label,
    origin_city,
    origin_state,
    origin_lat,
    origin_lng,
    destination_label,
    destination_city,
    destination_state,
    destination_lat,
    destination_lng,
    route_distance_km,
    route_duration_minutes,
    route_polyline,
    route_snapshot_source,
    material,
    weight_tonnes,
    required_body_type,
    required_tyres,
    trucks_needed,
    price_amount,
    price_type,
    advance_percentage,
    pickup_date,
    status,
    is_super_load,
    super_status,
    assigned_trucker_id,
    assigned_truck_id,
    published_at
  ) VALUES (
    v_parent.supplier_id,
    v_parent.id,
    v_parent.origin_label,
    v_parent.origin_city,
    v_parent.origin_state,
    v_parent.origin_lat,
    v_parent.origin_lng,
    v_parent.destination_label,
    v_parent.destination_city,
    v_parent.destination_state,
    v_parent.destination_lat,
    v_parent.destination_lng,
    v_parent.route_distance_km,
    v_parent.route_duration_minutes,
    v_parent.route_polyline,
    v_parent.route_snapshot_source,
    v_parent.material,
    v_parent.weight_tonnes,
    v_parent.required_body_type,
    v_parent.required_tyres,
    1,
    v_parent.price_amount,
    v_parent.price_type,
    v_parent.advance_percentage,
    v_parent.pickup_date,
    'assigned_full',
    TRUE,
    'active',
    p_trucker_id,
    p_truck_id,
    NOW()
  ) RETURNING id INTO v_child_load_id;

  INSERT INTO trips (
    load_id,
    supplier_id,
    trucker_id,
    truck_id,
    stage,
    assigned_at
  ) VALUES (
    v_child_load_id,
    v_parent.supplier_id,
    p_trucker_id,
    p_truck_id,
    'assigned',
    NOW()
  ) RETURNING id INTO v_trip_id;

  UPDATE loads
  SET trucks_booked = trucks_booked + 1,
      status = CASE
        WHEN trucks_booked + 1 >= trucks_needed THEN 'assigned_full'::load_status
        ELSE 'assigned_partial'::load_status
      END,
      updated_at = NOW()
  WHERE id = p_parent_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'load',
    p_parent_load_id,
    'trip',
    v_trip_id,
    'Super Load force-assigned to trucker',
    jsonb_build_object(
      'trucker_id', p_trucker_id,
      'truck_id', p_truck_id,
      'child_load_id', v_child_load_id
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    p_trucker_id,
    'super_load_update',
    'high',
    'Super Load Assignment',
    'You''ve been assigned a Super Load! ' || v_parent.material || ' ' || v_parent.origin_city || '→' || v_parent.destination_city,
    v_child_load_id,
    v_trip_id,
    '/trip-detail/' || v_trip_id::text
  );

  RETURN v_trip_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.advance_trip_stage(p_trip_id uuid, p_new_stage public.trip_stage, p_gps_lat double precision DEFAULT NULL::double precision, p_gps_lng double precision DEFAULT NULL::double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
  v_destination_label TEXT;
  v_trucker_name TEXT;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.trucker_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;

  IF NOT (
    (v_trip.stage = 'assigned' AND p_new_stage = 'pickup_pending') OR
    (v_trip.stage = 'pickup_pending' AND p_new_stage = 'picked_up') OR
    (v_trip.stage = 'picked_up' AND p_new_stage = 'in_transit') OR
    (v_trip.stage = 'in_transit' AND p_new_stage = 'delivered')
  ) THEN
    RAISE EXCEPTION 'Invalid stage transition from % to %', v_trip.stage, p_new_stage;
  END IF;

  UPDATE trips SET
    stage = p_new_stage,
    started_at = CASE WHEN p_new_stage = 'in_transit' THEN NOW() ELSE started_at END,
    delivered_at = CASE WHEN p_new_stage = 'delivered' THEN NOW() ELSE delivered_at END,
    gps_pickup_lat = CASE WHEN p_new_stage = 'pickup_pending' THEN p_gps_lat ELSE gps_pickup_lat END,
    gps_pickup_lng = CASE WHEN p_new_stage = 'pickup_pending' THEN p_gps_lng ELSE gps_pickup_lng END,
    gps_loaded_lat = CASE WHEN p_new_stage = 'picked_up' THEN p_gps_lat ELSE gps_loaded_lat END,
    gps_loaded_lng = CASE WHEN p_new_stage = 'picked_up' THEN p_gps_lng ELSE gps_loaded_lng END,
    gps_delivered_lat = CASE WHEN p_new_stage = 'delivered' THEN p_gps_lat ELSE gps_delivered_lat END,
    gps_delivered_lng = CASE WHEN p_new_stage = 'delivered' THEN p_gps_lng ELSE gps_delivered_lng END
  WHERE id = p_trip_id;

  IF p_new_stage = 'in_transit' THEN
    UPDATE loads SET status = 'in_transit'
    WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
      AND status IN ('assigned_partial', 'assigned_full');
  END IF;

  IF p_new_stage IN ('in_transit', 'delivered') THEN
    SELECT COALESCE(destination_label, 'destination')
    INTO v_destination_label
    FROM loads
    WHERE id = v_trip.load_id;

    SELECT COALESCE(NULLIF(full_name, ''), 'Your trucker')
    INTO v_trucker_name
    FROM profiles
    WHERE id = v_trip.trucker_id;

    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      related_load_id,
      related_trip_id,
      action_route_hint
    ) VALUES (
      v_trip.supplier_id,
      'trip_update',
      'medium',
      CASE WHEN p_new_stage = 'in_transit' THEN 'Trip Started' ELSE 'Cargo Delivered' END,
      CASE
        WHEN p_new_stage = 'in_transit' THEN COALESCE(v_trucker_name, 'Your trucker') || ' has started the trip to ' || COALESCE(v_destination_label, 'destination')
        ELSE COALESCE(v_trucker_name, 'Your trucker') || ' has delivered at ' || COALESCE(v_destination_label, 'destination')
      END,
      v_trip.load_id,
      p_trip_id,
      '/trip-detail/' || p_trip_id::text
    );
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.approve_booking_request(p_booking_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_booking RECORD;
  v_load RECORD;
  v_child_load_id UUID;
  v_trip_id UUID;
  v_supplier_id UUID;
BEGIN
  v_supplier_id := auth.uid();

  SELECT * INTO v_booking FROM booking_requests WHERE id = p_booking_id FOR UPDATE;
  IF v_booking IS NULL THEN RAISE EXCEPTION 'Booking not found'; END IF;
  IF v_booking.status != 'submitted' THEN RAISE EXCEPTION 'Booking not in submitted state'; END IF;

  SELECT * INTO v_load FROM loads WHERE id = v_booking.load_id FOR UPDATE;
  IF v_load.supplier_id != v_supplier_id THEN RAISE EXCEPTION 'Not your load'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available'; END IF;

  UPDATE booking_requests SET status = 'approved', decided_at = NOW() WHERE id = p_booking_id;

  INSERT INTO loads (
    supplier_id, parent_load_id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage, pickup_date,
    status, assigned_trucker_id, assigned_truck_id, published_at
  ) SELECT
    supplier_id, v_load.id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    1, price_amount, price_type, advance_percentage, pickup_date,
    'assigned_full', v_booking.trucker_id, v_booking.truck_id, NOW()
  FROM loads WHERE id = v_load.id
  RETURNING id INTO v_child_load_id;

  INSERT INTO trips (load_id, supplier_id, trucker_id, truck_id, stage, assigned_at)
  VALUES (v_child_load_id, v_supplier_id, v_booking.trucker_id, v_booking.truck_id, 'assigned', NOW())
  RETURNING id INTO v_trip_id;

  UPDATE loads SET
    trucks_booked = trucks_booked + 1,
    status = CASE
      WHEN trucks_booked + 1 >= trucks_needed THEN 'assigned_full'::load_status
      ELSE 'assigned_partial'::load_status
    END
  WHERE id = v_load.id;

  IF (v_load.trucks_booked + 1 >= v_load.trucks_needed) THEN
    UPDATE booking_requests SET status = 'superseded'
    WHERE load_id = v_load.id AND status = 'submitted' AND id != p_booking_id;
  END IF;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    v_booking.trucker_id,
    'booking_update',
    'high',
    'Booking Approved!',
    'Head to pickup for ' || COALESCE(v_load.material, 'your load') || ' ' || COALESCE(v_load.origin_label, 'origin') || '→' || COALESCE(v_load.destination_label, 'destination'),
    v_child_load_id,
    v_trip_id,
    '/trip-detail/' || v_trip_id::text
  );

  RETURN v_trip_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.approve_super_load_request(p_load_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status NOT IN ('request_submitted', 'under_review') THEN
    RAISE EXCEPTION 'Super Load request is not awaiting approval';
  END IF;

  UPDATE loads
  SET is_super_load = TRUE,
      super_status = 'approved_payment_pending',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'super_load_approved',
    'load',
    p_load_id,
    'Super Load approved with payment pending',
    jsonb_build_object(
      'super_status', 'approved_payment_pending'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'super_load_update',
    'high',
    'Super Load Approved',
    'Complete off-platform payment to activate',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.approve_verification_case(p_case_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Verification case not found';
  END IF;

  IF v_case.subject_type NOT IN ('supplier_profile', 'trucker_profile') THEN
    RAISE EXCEPTION 'approve_verification_case only supports profile verification cases';
  END IF;

  IF v_case.case_status NOT IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission') THEN
    RAISE EXCEPTION 'Verification case is not awaiting review';
  END IF;

  UPDATE verification_cases
  SET case_status = 'approved',
      assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
      last_reviewed_at = NOW(),
      current_decision_summary = 'Approved',
      current_review_feedback_json = NULL,
      updated_at = NOW()
  WHERE id = p_case_id;

  IF COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN
    UPDATE profiles
    SET avatar_url = profile_photo_document_path,
        profile_photo_review_status = 'approved',
        profile_photo_rejection_reason = NULL,
        profile_photo_feedback_json = NULL,
        profile_photo_last_reviewed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  ELSE
    UPDATE profiles
    SET verification_status = 'verified',
        verification_rejection_reason = NULL,
        verification_feedback_json = NULL,
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  END IF;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary
  ) VALUES (
    p_case_id,
    'approved',
    v_admin_user_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo approved'
      ELSE 'Verification approved'
    END
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'user_verification_approved',
    'verification_case',
    p_case_id,
    'profile',
    v_case.subject_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo approved'
      ELSE 'Verification approved'
    END,
    jsonb_build_object(
      'subject_type', v_case.subject_type,
      'review_type', COALESCE(v_case.review_type, 'full_verification')
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_case.subject_id,
    'verification_update',
    'high',
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile Photo Approved'
      ELSE 'Account Verified'
    END,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Your new profile photo is now live.'
      ELSE 'You can now use all TranZfort features'
    END,
    p_case_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN '/profile'
      ELSE '/profile'
    END
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_complete_delivered_trips()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_count INTEGER := 0;
  v_trip RECORD;
BEGIN
  FOR v_trip IN
    SELECT id, trucker_id, load_id FROM trips
    WHERE stage = 'proof_submitted'
      AND pod_uploaded_at < NOW() - INTERVAL '48 hours'
  LOOP
    UPDATE trips SET stage = 'completed', completed_at = NOW() WHERE id = v_trip.id;
    UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;
    v_count := v_count + 1;

    -- Check if all sibling trips under the same parent load are now done
    PERFORM 1 FROM loads child
    JOIN trips t ON t.load_id = child.id
    WHERE child.parent_load_id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
      AND t.stage NOT IN ('completed', 'cancelled')
    LIMIT 1;

    IF NOT FOUND THEN
      UPDATE loads SET status = 'completed'
      WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id);
    END IF;
  END LOOP;

  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_complete_expired_trips()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_completed_count INT DEFAULT 0;
BEGIN
  -- Auto-complete trips where:
  -- 1. Auto-completion is enabled
  -- 2. Expected time has passed
  -- 3. Supplier has not confirmed
  -- 4. Stage is delivered or pod_uploaded
  UPDATE public.trips
  SET
    stage = 'completed',
    completed_at = COALESCE(completed_at, NOW()),
    auto_completion_enabled = false,
    updated_at = NOW()
  WHERE
    auto_completion_enabled = true
    AND auto_completion_expected_at IS NOT NULL
    AND auto_completion_expected_at <= NOW()
    AND supplier_confirmed_at IS NULL
    AND stage IN ('delivered', 'pod_uploaded');

  GET DIAGNOSTICS v_completed_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success', true,
    'completed_count', v_completed_count,
    'timestamp', NOW()
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.can_review_user(p_target_user_id uuid, p_context_type text DEFAULT NULL::text, p_context_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    v_current_user_id uuid;
    v_already_reviewed boolean;
    v_target_exists boolean;
begin
    v_current_user_id := auth.uid();
    
    -- Check if target user exists
    select exists(select 1 from profiles where id = p_target_user_id) into v_target_exists;
    
    if not v_target_exists then
        return jsonb_build_object(
            'can_review', false,
            'already_reviewed', false,
            'requires_interaction', true,
            'reason', 'Target user not found'
        );
    end if;
    
    -- Cannot review yourself
    if v_current_user_id = p_target_user_id then
        return jsonb_build_object(
            'can_review', false,
            'already_reviewed', false,
            'requires_interaction', true,
            'reason', 'Cannot review yourself'
        );
    end if;
    
    -- Check if already reviewed
    select exists(
        select 1 from reviews 
        where reviewed_user_id = p_target_user_id 
          and reviewer_id = v_current_user_id
    ) into v_already_reviewed;
    
    if v_already_reviewed then
        return jsonb_build_object(
            'can_review', false,
            'already_reviewed', true,
            'requires_interaction', true,
            'reason', 'You have already reviewed this user'
        );
    end if;
    
    -- Can review (requires interaction per current spec)
    return jsonb_build_object(
        'can_review', true,
        'already_reviewed', false,
        'requires_interaction', true,
        'reason', null
    );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.cancel_account_deletion_request()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_profile RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_profile
  FROM profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_profile.account_deletion_status = 'permanently_deleted' THEN
    RAISE EXCEPTION 'Account is already permanently deleted';
  END IF;

  IF v_profile.account_deletion_status <> 'deactivated_pending_cleanup' THEN
    RETURN jsonb_build_object(
      'status', COALESCE(v_profile.account_deletion_status::TEXT, 'active'),
      'blocked', false,
      'message', 'Account deletion is not pending cleanup'
    );
  END IF;

  UPDATE profiles
  SET account_deletion_status = 'active',
      updated_at = NOW()
  WHERE id = v_user_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    NULL,
    'user',
    NULL,
    'deletion_request_cancelled',
    'profile',
    v_user_id,
    'User cancelled account deletion request',
    jsonb_build_object(
      'account_deletion_status', 'active'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    action_route_hint
  ) VALUES (
    v_user_id,
    'account_update',
    'medium',
    'Deletion Request Cancelled',
    'Your account deletion request was cancelled and your account is active again.',
    '/profile'
  );

  RETURN jsonb_build_object(
    'status', 'active',
    'blocked', false,
    'message', 'Account deletion request cancelled and account restored to active'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cancel_load(p_load_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_load RECORD;
  v_admin_user_id UUID;
  v_actor_type TEXT;
  v_actor_role TEXT;
  v_action_type audit_action_type;
BEGIN
  SELECT * INTO v_load FROM loads WHERE id = p_load_id FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.supplier_id != auth.uid() AND NOT is_admin() THEN RAISE EXCEPTION 'Not authorized'; END IF;
  IF v_load.status NOT IN ('active', 'draft') THEN RAISE EXCEPTION 'Load cannot be cancelled in current state'; END IF;

  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NOT NULL THEN
    v_actor_type := 'admin';
    v_actor_role := get_admin_role()::text;
    v_action_type := 'admin_cancel_load';
  ELSE
    v_actor_type := 'user';
    v_actor_role := NULL;
    v_action_type := 'override_action';
  END IF;

  UPDATE loads SET status = 'cancelled' WHERE id = p_load_id;

  IF v_load.status = 'active' THEN
    UPDATE suppliers SET active_loads_count = GREATEST(active_loads_count - 1, 0)
    WHERE id = v_load.supplier_id;
  END IF;

  UPDATE booking_requests SET status = 'superseded'
  WHERE load_id = p_load_id AND status = 'submitted';

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    v_actor_type,
    v_actor_role,
    v_action_type,
    'load',
    p_load_id,
    NULL,
    NULL,
    CASE
      WHEN v_admin_user_id IS NOT NULL THEN 'Load cancelled by admin'
      ELSE 'Load cancelled by supplier'
    END,
    jsonb_build_object(
      'previous_status', v_load.status,
      'next_status', 'cancelled',
      'supplier_id', v_load.supplier_id
    ),
    'internal'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cancel_trip(p_trip_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
  v_child_load RECORD;
  v_parent_load RECORD;
  v_remaining_booked INTEGER;
  v_has_active_children BOOLEAN;
  v_has_started_children BOOLEAN;
  v_has_completed_children BOOLEAN;
  v_body TEXT;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  IF v_trip.supplier_id != auth.uid() AND NOT is_admin() THEN
    RAISE EXCEPTION 'Not your trip';
  END IF;

  IF v_trip.stage IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'Trip cannot be cancelled in current state';
  END IF;

  SELECT * INTO v_child_load FROM loads WHERE id = v_trip.load_id FOR UPDATE;
  IF v_child_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_child_load.parent_load_id IS NOT NULL THEN
    SELECT * INTO v_parent_load FROM loads WHERE id = v_child_load.parent_load_id FOR UPDATE;
  END IF;

  UPDATE trips
  SET stage = 'cancelled'
  WHERE id = p_trip_id;

  UPDATE loads
  SET status = 'cancelled'
  WHERE id = v_child_load.id;

  IF v_parent_load IS NOT NULL THEN
    v_remaining_booked := GREATEST(COALESCE(v_parent_load.trucks_booked, 0) - 1, 0);

    SELECT EXISTS (
      SELECT 1
      FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load.id
        AND t.stage NOT IN ('completed', 'cancelled')
    ) INTO v_has_active_children;

    SELECT EXISTS (
      SELECT 1
      FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load.id
        AND t.stage IN ('picked_up', 'in_transit', 'delivered', 'proof_submitted', 'disputed')
    ) INTO v_has_started_children;

    SELECT EXISTS (
      SELECT 1
      FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load.id
        AND t.stage = 'completed'
    ) INTO v_has_completed_children;

    UPDATE loads
    SET trucks_booked = v_remaining_booked,
        status = CASE
          WHEN v_has_active_children AND v_has_started_children THEN 'in_transit'::load_status
          WHEN v_has_active_children AND v_remaining_booked >= trucks_needed THEN 'assigned_full'::load_status
          WHEN v_has_active_children AND v_remaining_booked > 0 THEN 'assigned_partial'::load_status
          WHEN NOT v_has_active_children AND v_has_completed_children THEN 'completed'::load_status
          ELSE 'active'::load_status
        END
    WHERE id = v_parent_load.id;
  END IF;

  v_body := 'Trip for ' || COALESCE(v_child_load.material, 'your load') || ' ' || COALESCE(v_child_load.origin_label, 'origin') || '→' || COALESCE(v_child_load.destination_label, 'destination') || ' has been cancelled';

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES
  (
    v_trip.trucker_id,
    'trip_update',
    'high',
    'Trip Cancelled',
    v_body,
    v_child_load.id,
    v_trip.id,
    '/trip-detail/{tripId}'
  ),
  (
    v_trip.supplier_id,
    'trip_update',
    'high',
    'Trip Cancelled',
    v_body,
    v_child_load.id,
    v_trip.id,
    '/trip-detail/{tripId}'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.claim_operational_case(p_case_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'queued' THEN
    RAISE EXCEPTION 'Only queued cases can be claimed';
  END IF;

  IF v_case.claimed_by_admin_user_id IS NOT NULL THEN
    RAISE EXCEPTION 'Operational case is already claimed';
  END IF;

  UPDATE operational_cases
  SET status = 'claimed',
      claimed_by_admin_user_id = v_admin_user_id,
      claimed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_claimed',
    'Operational case claimed'
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'operational_case',
    p_case_id,
    'Operational case claimed',
    '{}'::jsonb,
    'internal'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cleanup_orphaned_attachments(p_hours_older_than integer DEFAULT 24)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_count INT;
BEGIN
  -- Delete attachments without ticket_id older than specified hours
  DELETE FROM public.ticket_attachments
  WHERE 
    ticket_id IS NULL
    AND created_at < NOW() - (p_hours_older_than || ' hours')::INTERVAL;
  
  -- Return count of deleted attachments
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.close_load_filled_outside_app(p_load_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_load RECORD;
BEGIN
  SELECT * INTO v_load FROM loads WHERE id = p_load_id FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.supplier_id != auth.uid() AND NOT is_admin() THEN RAISE EXCEPTION 'Not authorized'; END IF;
  IF v_load.status != 'active' THEN RAISE EXCEPTION 'Load cannot be closed as filled outside app in current state'; END IF;

  UPDATE loads
  SET status = 'filled_outside_app'
  WHERE id = p_load_id;

  UPDATE suppliers
  SET active_loads_count = GREATEST(active_loads_count - 1, 0)
  WHERE id = v_load.supplier_id;

  UPDATE booking_requests
  SET status = 'superseded'
  WHERE load_id = p_load_id AND status = 'submitted';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_trip_by_supplier(p_trip_id uuid, p_supplier_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
BEGIN
  -- Fetch trip and verify ownership
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id AND supplier_id = p_supplier_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Trip not found or access denied');
  END IF;

  IF NOT v_trip.supplier_confirmation_required THEN
    RETURN jsonb_build_object('error', 'Supplier confirmation not required for this trip');
  END IF;

  IF v_trip.supplier_confirmed_at IS NOT NULL THEN
    RETURN jsonb_build_object('error', 'Trip already confirmed by supplier');
  END IF;

  -- Update trip confirmation
  UPDATE public.trips
  SET
    supplier_confirmed_at = NOW(),
    auto_completion_enabled = false, -- Disable auto-completion after confirmation
    updated_at = NOW()
  WHERE id = p_trip_id;

  RETURN jsonb_build_object(
    'success', true,
    'trip_id', p_trip_id,
    'supplier_confirmed_at', NOW(),
    'auto_completion_enabled', false
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_trip_delivery(p_trip_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.supplier_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;
  IF v_trip.stage != 'proof_submitted' THEN RAISE EXCEPTION 'Trip not in proof_submitted stage'; END IF;

  UPDATE trips SET stage = 'completed', completed_at = NOW() WHERE id = p_trip_id;

  UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;

  PERFORM 1 FROM loads child
  JOIN trips t ON t.load_id = child.id
  WHERE child.parent_load_id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
    AND t.stage NOT IN ('completed', 'cancelled')
  LIMIT 1;

  IF NOT FOUND THEN
    UPDATE loads SET status = 'completed'
    WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id);
  END IF;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    v_trip.trucker_id,
    'trip_update',
    'medium',
    'Trip Completed!',
    'Rate your experience for this completed trip.',
    v_trip.load_id,
    p_trip_id,
    '/trip-detail/' || p_trip_id::text
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_load(p_origin_label text, p_origin_city text, p_origin_state text, p_origin_lat double precision, p_origin_lng double precision, p_destination_label text, p_destination_city text, p_destination_state text, p_destination_lat double precision, p_destination_lng double precision, p_route_distance_km numeric, p_route_duration_minutes integer, p_route_polyline text, p_route_snapshot_source text, p_material text, p_weight_tonnes numeric, p_required_body_type text, p_required_tyres integer[], p_trucks_needed integer, p_price_amount numeric, p_price_type public.price_type, p_advance_percentage integer, p_pickup_date date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_load_id UUID;
  v_supplier_id UUID;
  v_canonical_price_type price_type;
BEGIN
  -- Normalize legacy 'negotiable' to canonical 'per_ton' during buffer period
  v_canonical_price_type := CASE
    WHEN p_price_type = 'negotiable' THEN 'per_ton'::price_type
    ELSE p_price_type
  END;

  -- Verify caller is a supplier
  SELECT id INTO v_supplier_id FROM suppliers WHERE id = auth.uid();
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Not a supplier';
  END IF;

  INSERT INTO loads (
    supplier_id, origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage,
    pickup_date, status, published_at
  ) VALUES (
    v_supplier_id, p_origin_label, p_origin_city, p_origin_state, p_origin_lat, p_origin_lng,
    p_destination_label, p_destination_city, p_destination_state, p_destination_lat, p_destination_lng,
    p_route_distance_km, p_route_duration_minutes, p_route_polyline, p_route_snapshot_source,
    p_material, p_weight_tonnes, p_required_body_type, p_required_tyres,
    p_trucks_needed, p_price_amount, v_canonical_price_type, p_advance_percentage,
    p_pickup_date, 'active', NOW()
  ) RETURNING id INTO v_load_id;

  -- Update supplier counters
  UPDATE suppliers SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_load_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_or_get_conversation(p_supplier_id uuid, p_trucker_id uuid, p_load_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_conv_id UUID;
  v_load RECORD;
  v_route_label TEXT;
BEGIN
  SELECT id INTO v_conv_id
  FROM conversations
  WHERE supplier_id = p_supplier_id AND trucker_id = p_trucker_id AND load_id = p_load_id;

  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  INSERT INTO conversations (supplier_id, trucker_id, load_id)
  VALUES (p_supplier_id, p_trucker_id, p_load_id)
  RETURNING id INTO v_conv_id;

  SELECT
    origin_label,
    origin_state,
    destination_label,
    destination_state,
    route_distance_km,
    route_duration_minutes,
    material,
    weight_tonnes,
    price_amount
  INTO v_load
  FROM loads
  WHERE id = p_load_id;

  v_route_label := CONCAT_WS(' → ', v_load.origin_label, v_load.destination_label);

  INSERT INTO messages (
    conversation_id,
    sender_profile_id,
    message_type,
    text_body,
    attachment_path,
    structured_payload,
    is_read,
    read_at
  )
  VALUES (
    v_conv_id,
    NULL,
    'map_card',
    v_route_label,
    NULL,
    jsonb_strip_nulls(
      jsonb_build_object(
        'route_label', v_route_label,
        'material', v_load.material,
        'weight_tonnes', v_load.weight_tonnes,
        'price_amount', v_load.price_amount,
        'route_distance_km', v_load.route_distance_km,
        'route_duration_minutes', v_load.route_duration_minutes,
        'origin_state', v_load.origin_state,
        'destination_state', v_load.destination_state
      )
    ),
    TRUE,
    NOW()
  );

  UPDATE conversations SET last_message_at = NOW() WHERE id = v_conv_id;

  RETURN v_conv_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_support_ticket(p_category text, p_message_body text, p_related_load_id uuid DEFAULT NULL::uuid, p_related_trip_id uuid DEFAULT NULL::uuid, p_attachment_path text DEFAULT NULL::text, p_priority text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_category TEXT;
  v_message_body TEXT;
  v_related_load_id UUID;
  v_related_trip_id UUID;
  v_support_ticket_id UUID;
  v_priority support_ticket_priority;
  v_trip RECORD;
  v_load RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  v_category := lower(btrim(COALESCE(p_category, '')));
  IF v_category NOT IN (
    'general',
    'account',
    'load',
    'trip',
    'payment',
    'technical',
    'other',
    'loaded_quantity_mismatch',
    'unloaded_quantity_mismatch',
    'document_mismatch',
    'non_payment',
    'fake_payout_proof',
    'delay_or_no_show',
    'damage_or_shortage',
    'abusive_behavior',
    'spam_or_scam',
    'trip_dispute'
  ) THEN
    RAISE EXCEPTION 'Unsupported support category';
  END IF;

  v_message_body := btrim(COALESCE(p_message_body, ''));
  IF char_length(v_message_body) < 10 THEN
    RAISE EXCEPTION 'Support description too short';
  END IF;

  v_related_load_id := p_related_load_id;
  v_related_trip_id := p_related_trip_id;

  IF v_related_trip_id IS NOT NULL THEN
    SELECT id, load_id, supplier_id, trucker_id INTO v_trip
    FROM trips
    WHERE id = v_related_trip_id
    FOR UPDATE;

    IF v_trip IS NULL THEN
      RAISE EXCEPTION 'Trip not found';
    END IF;

    IF v_trip.supplier_id IS DISTINCT FROM v_user_id
       AND v_trip.trucker_id IS DISTINCT FROM v_user_id THEN
      RAISE EXCEPTION 'Trip does not belong to current user';
    END IF;

    IF v_related_load_id IS NOT NULL AND v_related_load_id IS DISTINCT FROM v_trip.load_id THEN
      RAISE EXCEPTION 'Related load does not match trip context';
    END IF;

    v_related_load_id := v_trip.load_id;
  END IF;

  IF v_related_load_id IS NOT NULL THEN
    SELECT id, supplier_id INTO v_load
    FROM loads
    WHERE id = v_related_load_id
    FOR UPDATE;

    IF v_load IS NULL THEN
      RAISE EXCEPTION 'Load not found';
    END IF;

    IF v_load.supplier_id IS DISTINCT FROM v_user_id
       AND NOT EXISTS (
         SELECT 1
         FROM trips
         WHERE load_id = v_related_load_id
           AND (supplier_id = v_user_id OR trucker_id = v_user_id)
       ) THEN
      RAISE EXCEPTION 'Load does not belong to current user';
    END IF;
  END IF;

  IF NULLIF(btrim(COALESCE(p_priority, '')), '') IS NOT NULL THEN
    CASE lower(btrim(p_priority))
      WHEN 'low' THEN v_priority := 'low';
      WHEN 'medium' THEN v_priority := 'medium';
      WHEN 'high' THEN v_priority := 'high';
      WHEN 'urgent' THEN v_priority := 'urgent';
      ELSE RAISE EXCEPTION 'Unsupported support priority';
    END CASE;
  ELSE
    v_priority := CASE
      WHEN v_category IN ('spam_or_scam', 'abusive_behavior', 'fake_payout_proof') THEN 'urgent'::support_ticket_priority
      WHEN v_category IN (
        'payment',
        'non_payment',
        'loaded_quantity_mismatch',
        'unloaded_quantity_mismatch',
        'document_mismatch',
        'delay_or_no_show',
        'damage_or_shortage',
        'trip_dispute'
      ) THEN 'high'::support_ticket_priority
      ELSE 'medium'::support_ticket_priority
    END;
  END IF;

  INSERT INTO support_tickets (
    owner_profile_id,
    category,
    status,
    priority,
    related_load_id,
    related_trip_id
  ) VALUES (
    v_user_id,
    v_category,
    'open',
    v_priority,
    v_related_load_id,
    v_related_trip_id
  ) RETURNING id INTO v_support_ticket_id;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_profile_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    v_support_ticket_id,
    v_user_id,
    v_message_body,
    NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
    'visible'
  );

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'support_update',
    CASE
      WHEN v_priority IN ('high', 'urgent') THEN 'high'::notification_priority
      ELSE 'medium'::notification_priority
    END,
    'New Support Ticket',
    'A user opened a new support ticket requiring review.',
    v_related_load_id,
    v_related_trip_id,
    v_support_ticket_id,
    '/admin/support'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_support_ticket_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.current_admin_user_id()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
BEGIN
  SELECT id INTO v_admin_user_id
  FROM admin_users
  WHERE auth_user_id = auth.uid()
    AND is_active = TRUE;

  RETURN v_admin_user_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.debug_admin_login(p_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_auth_user_id UUID;
    v_admin_row JSONB;
    v_is_admin_result BOOLEAN;
BEGIN
    -- Find auth user by email (from auth.users via auth.identities or auth.users lookup)
    -- Note: We can't directly query auth.users from client, but we can check if the user exists in admin_users
    -- by trying to match against auth.uid() when called from authenticated context
    
    -- Get current auth uid (will be null if not authenticated)
    v_auth_user_id := auth.uid();
    
    -- Check admin_users for this auth uid
    SELECT jsonb_build_object(
        'id', id,
        'email', email,
        'role', role,
        'is_active', is_active,
        'auth_user_id', auth_user_id
    ) INTO v_admin_row
    FROM admin_users
    WHERE auth_user_id = v_auth_user_id;
    
    -- Test is_admin() function
    v_is_admin_result := is_admin();
    
    RETURN jsonb_build_object(
        'current_auth_uid', v_auth_user_id,
        'admin_row_found', v_admin_row IS NOT NULL,
        'admin_row', v_admin_row,
        'is_admin_result', v_is_admin_result,
        'email_requested', p_email
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.diagnose_admin_login(p_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result JSONB := '{}';
    v_admin_row RECORD;
    v_count INT;
BEGIN
    -- Check 1: Does any admin user exist?
    SELECT COUNT(*) INTO v_count FROM admin_users;
    v_result := v_result || jsonb_build_object('total_admin_users', v_count);
    
    -- Check 2: Find admin by email (bypassing RLS with SECURITY DEFINER)
    SELECT * INTO v_admin_row
    FROM admin_users
    WHERE email = p_email;
    
    IF v_admin_row IS NULL THEN
        v_result := v_result || jsonb_build_object('admin_found', false);
        
        -- List all admin emails for debugging
        v_result := v_result || jsonb_build_object(
            'all_admin_emails', 
            (SELECT jsonb_agg(email) FROM admin_users)
        );
    ELSE
        v_result := v_result || jsonb_build_object(
            'admin_found', true,
            'admin_id', v_admin_row.id,
            'admin_email', v_admin_row.email,
            'admin_role', v_admin_row.role,
            'admin_is_active', v_admin_row.is_active,
            'admin_auth_user_id', v_admin_row.auth_user_id::TEXT
        );
    END IF;
    
    -- Check 3: RLS policies on admin_users
    v_result := v_result || jsonb_build_object(
        'rls_enabled', (
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'admin_users'
        )
    );
    
    -- Check 4: List all RLS policies on admin_users
    v_result := v_result || jsonb_build_object(
        'rls_policies', (
            SELECT jsonb_agg(jsonb_build_object(
                'name', polname,
                'cmd', polcmd,
                'permissive', polpermissive
            ))
            FROM pg_policy
            WHERE polrelid = 'admin_users'::regclass
        )
    );
    
    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.dispatch_push_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_push_url TEXT;
BEGIN
  IF NEW.target_profile_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_push_url := COALESCE(
    NULLIF(current_setting('app.settings.push_edge_function_url', true), ''),
    'https://jgtgdfhdtjhidywpautk.supabase.co/functions/v1/send-push-notification'
  );
  IF btrim(v_push_url) = '' THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := v_push_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'target_user_id', NEW.target_profile_id,
      'title', COALESCE(NULLIF(NEW.title_text, ''), 'New notification'),
      'body', COALESCE(NEW.body_text, ''),
      'data', jsonb_strip_nulls(
        jsonb_build_object(
          'action_route_hint', NEW.action_route_hint,
          'related_load_id', NEW.related_load_id,
          'related_trip_id', NEW.related_trip_id,
          'related_case_id', NEW.related_case_id,
          'notification_type', NEW.notification_type,
          'notification_priority', NEW.notification_priority,
          'notification_id', NEW.id
        )
      )
    )
  );

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enable_trip_auto_completion(p_trip_id uuid, p_completion_window_hours integer DEFAULT 24)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
  v_expected_at TIMESTAMPTZ;
  v_countdown_seconds INT;
BEGIN
  -- Fetch trip and verify stage
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Trip not found');
  END IF;

  IF v_trip.stage NOT IN ('delivered', 'pod_uploaded') THEN
    RETURN jsonb_build_object('error', 'Trip must be in delivered or pod_uploaded stage');
  END IF;

  IF v_trip.pod_document_path IS NULL OR v_trip.pod_document_path = '' THEN
    RETURN jsonb_build_object('error', 'POD must be uploaded before enabling auto-completion');
  END IF;

  -- Calculate expected completion time
  v_expected_at := NOW() + (p_completion_window_hours || ' hours')::INTERVAL;
  v_countdown_seconds := p_completion_window_hours * 3600;

  -- Update trip with auto-completion settings
  UPDATE public.trips
  SET
    auto_completion_enabled = true,
    auto_completion_expected_at = v_expected_at,
    auto_completion_countdown_seconds = v_countdown_seconds,
    supplier_confirmation_required = true,
    supplier_confirmation_deadline = v_expected_at,
    updated_at = NOW()
  WHERE id = p_trip_id;

  RETURN jsonb_build_object(
    'success', true,
    'trip_id', p_trip_id,
    'auto_completion_enabled', true,
    'auto_completion_expected_at', v_expected_at,
    'auto_completion_countdown_seconds', v_countdown_seconds,
    'supplier_confirmation_required', true,
    'supplier_confirmation_deadline', v_expected_at
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.ensure_role_extension(p_role public.user_role)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_role = 'supplier' THEN
    INSERT INTO suppliers (id)
    VALUES (auth.uid())
    ON CONFLICT (id) DO NOTHING;
    RETURN;
  END IF;

  IF p_role = 'trucker' THEN
    INSERT INTO truckers (id)
    VALUES (auth.uid())
    ON CONFLICT (id) DO NOTHING;
    RETURN;
  END IF;

  RAISE EXCEPTION 'Unsupported role extension request';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.escalate_operational_case(p_case_id uuid, p_target_admin_user_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_target_admin RECORD;
  v_admin_name TEXT;
  v_reason TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF get_admin_role() != 'ops_admin' THEN
    RAISE EXCEPTION 'Only ops admins can escalate cases';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'in_review' THEN
    RAISE EXCEPTION 'Operational case must be in review to escalate';
  END IF;

  IF v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id THEN
    RAISE EXCEPTION 'Only the claimed admin can escalate this case';
  END IF;

  SELECT id, full_name, role, is_active INTO v_target_admin
  FROM admin_users
  WHERE id = p_target_admin_user_id
  FOR UPDATE;

  IF v_target_admin IS NULL OR v_target_admin.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'Target admin is not active';
  END IF;

  IF v_target_admin.role != 'super_admin' THEN
    RAISE EXCEPTION 'Cases can only be escalated to a super admin';
  END IF;

  SELECT full_name INTO v_admin_name
  FROM admin_users
  WHERE id = v_admin_user_id;

  UPDATE operational_cases
  SET status = 'escalated',
      escalated_to_admin_user_id = p_target_admin_user_id,
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_escalated',
    'Case escalated to super admin',
    v_reason
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'case_escalated',
    'operational_case',
    p_case_id,
    'admin_user',
    p_target_admin_user_id,
    'Operational case escalated to super admin',
    jsonb_build_object(
      'reason', v_reason
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    p_target_admin_user_id,
    'support_update',
    'high',
    'Case Escalated',
    'Case #' || p_case_id::text || ' escalated by ' || COALESCE(NULLIF(v_admin_name, ''), 'Ops Admin'),
    p_case_id,
    '/admin/case/' || p_case_id::text
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.finalize_ticket_attachments(p_ticket_id uuid, p_session_id text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_count INT;
  v_user_id UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  -- Finalize all user's draft attachments for this session
  UPDATE public.ticket_attachments
  SET 
    ticket_id = p_ticket_id,
    upload_status = 'uploaded',
    updated_at = NOW()
  WHERE 
    uploaded_by = v_user_id
    AND ticket_id IS NULL
    AND file_path LIKE '%' || p_session_id || '%';
  
  -- Return count of finalized attachments
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_admin_for_login(p_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result JSONB;
BEGIN
    -- Direct query bypassing RLS due to SECURITY DEFINER
    SELECT jsonb_build_object(
        'id', id,
        'email', email,
        'role', role,
        'is_active', is_active,
        'auth_user_id', auth_user_id
    ) INTO v_result
    FROM admin_users
    WHERE email = p_email;
    
    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_admin_role()
 RETURNS public.admin_role
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  _role admin_role;
BEGIN
  SELECT role INTO _role FROM admin_users
  WHERE auth_user_id = auth.uid() AND is_active = TRUE;
  RETURN _role;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_all_user_feedback(p_user_id uuid, p_limit integer DEFAULT 10, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_feedback jsonb;
    v_trip_count int;
    v_review_count int;
BEGIN
    -- Debug: Count records in each source
    SELECT count(*) INTO v_trip_count
    FROM ratings r
    WHERE r.reviewee_id = p_user_id;
    
    SELECT count(*) INTO v_review_count
    FROM reviews r
    WHERE r.reviewed_user_id = p_user_id;
    
    RAISE NOTICE 'Trip ratings count: %, Reviews count: %', v_trip_count, v_review_count;
    
    -- Combine ratings (trip completions) and reviews (general feedback)
    -- Normalize column names and add context labels
    -- All columns must have matching types for UNION - cast all to text
    -- Use subquery to handle sorting without GROUP BY issues
    WITH trip_ratings AS (
        SELECT
            r.id::text as id,
            r.reviewee_id::text as reviewed_user_id,
            r.reviewer_id::text as reviewer_id,
            r.reviewer_role::text as reviewer_role,
            'trip_completed'::text as context_type,
            r.trip_id::text as context_id,
            r.score::text as rating,
            r.comment::text as comment,
            NULL::text as reply,
            NULL::text as reply_at,
            r.created_at::text as created_at,
            'Trip Completed'::text as context_label,
            l.origin_city::text as origin_city,
            l.destination_city::text as destination_city
        FROM ratings r
        LEFT JOIN loads l ON l.id = r.load_id
        WHERE r.reviewee_id = p_user_id
    ),
    general_reviews AS (
        SELECT
            r.id::text,
            r.reviewed_user_id::text,
            r.reviewer_id::text,
            r.reviewer_role::text,
            r.context_type::text,
            r.context_id::text,
            r.rating::text,
            r.comment::text,
            r.reply::text,
            r.reply_at::text,
            r.created_at::text,
            CASE
                WHEN r.context_type = 'chat' THEN 'Chat Interaction'::text
                WHEN r.context_type = 'load_closed' THEN 'Load Closed'::text
                WHEN r.context_type = 'trip_completed' THEN 'Trip Completed'::text
                ELSE r.context_type::text
            END as context_label,
            NULL::text as origin_city,
            NULL::text as destination_city
        FROM reviews r
        WHERE r.reviewed_user_id = p_user_id
    ),
    combined_feedback AS (
        SELECT * FROM trip_ratings
        UNION ALL
        SELECT * FROM general_reviews
    ),
    joined_feedback AS (
        SELECT
            cf.*,
            p.full_name as reviewer_name,
            coalesce(pts.avg_rating, 0) as reviewer_avg_rating,
            coalesce(pts.review_count, 0) as reviewer_review_count,
            coalesce(p.avatar_url, p.profile_photo_document_path) as reviewer_avatar_url
        FROM combined_feedback cf
        JOIN profiles p ON p.id::text = cf.reviewer_id
        LEFT JOIN profile_trust_scores pts ON pts.user_id::text = cf.reviewer_id
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', jf.id,
            'reviewed_user_id', jf.reviewed_user_id,
            'reviewer_id', jf.reviewer_id,
            'reviewer_name', jf.reviewer_name,
            'reviewer_role', jf.reviewer_role,
            'reviewer_avg_rating', jf.reviewer_avg_rating,
            'reviewer_review_count', jf.reviewer_review_count,
            'reviewer_avatar_url', jf.reviewer_avatar_url,
            'context_type', jf.context_type,
            'context_id', jf.context_id,
            'context_label', jf.context_label,
            'rating', jf.rating::int,
            'comment', jf.comment,
            'reply', jf.reply,
            'reply_at', jf.reply_at,
            'created_at', jf.created_at,
            'origin_city', jf.origin_city,
            'destination_city', jf.destination_city
        )
    ) INTO v_feedback
    FROM (
        SELECT * FROM joined_feedback
        ORDER BY created_at DESC
        LIMIT p_limit OFFSET p_offset
    ) jf;
    
    RAISE NOTICE 'Combined feedback count: %', jsonb_array_length(v_feedback);
    
    RETURN coalesce(v_feedback, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_backend_rpc_contract_version()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  SELECT jsonb_build_object(
    'version', '2026.04.28-v1',
    'required_rpcs', jsonb_build_array(
      'get_supplier_dashboard_stats',
      'get_trucker_dashboard_stats',
      'get_public_profile',
      'get_profile_reviews',
      'get_trip_detail_with_supplier',
      'upsert_current_user_profile',
      'create_load',
      'advance_trip_stage',
      'upload_trip_proof',
      'submit_review',
      'add_reply_to_review',
      'can_review_user',
      'get_conversation_summary',
      'send_message',
      'request_account_deletion',
      'cancel_account_deletion_request',
      'set_current_user_preferred_language'
    )
  );
$function$
;

CREATE OR REPLACE FUNCTION public.get_conversation_summary(p_conversation_id uuid)
 RETURNS TABLE(id uuid, supplier_id uuid, trucker_id uuid, load_id uuid, trip_id uuid, route_label text, load_material text, load_price_amount numeric, load_status_label text, pickup_date timestamp with time zone, supplier_name text, supplier_mobile text, supplier_company_name text, trucker_name text, trucker_mobile text, truck_display_label text, booking_request_id uuid, booking_status_label text, latest_message_type public.message_type, latest_message_text text, last_message_at timestamp with time zone, has_unread boolean, is_archived boolean, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.supplier_id,
    c.trucker_id,
    c.load_id,
    c.trip_id,
    COALESCE(
      NULLIF(CONCAT_WS(' → ', NULLIF(BTRIM(l.origin_label), ''), NULLIF(BTRIM(l.destination_label), '')), ''),
      NULLIF(BTRIM(l.origin_label), ''),
      'Load'
    ) AS route_label,
    l.material AS load_material,
    l.price_amount AS load_price_amount,
    l.status::TEXT AS load_status_label,
    l.pickup_date AS pickup_date,
    COALESCE(NULLIF(BTRIM(supplier_profile.full_name), ''), 'Supplier') AS supplier_name,
    NULLIF(BTRIM(supplier_profile.mobile), '') AS supplier_mobile,
    NULLIF(BTRIM(supplier_extension.company_name), '') AS supplier_company_name,
    COALESCE(NULLIF(BTRIM(trucker_profile.full_name), ''), 'Trucker') AS trucker_name,
    NULLIF(BTRIM(trucker_profile.mobile), '') AS trucker_mobile,
    CASE
      WHEN NULLIF(BTRIM(booking_summary.truck_number), '') IS NOT NULL
        AND NULLIF(BTRIM(CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))), '') IS NOT NULL
        THEN booking_summary.truck_number || ' • ' || CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))
      WHEN NULLIF(BTRIM(booking_summary.truck_number), '') IS NOT NULL
        THEN booking_summary.truck_number
      WHEN NULLIF(BTRIM(CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))), '') IS NOT NULL
        THEN CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))
      ELSE NULL
    END AS truck_display_label,
    booking_summary.booking_request_id,
    booking_summary.booking_status_label,
    latest_message.message_type AS latest_message_type,
    latest_message.text_body AS latest_message_text,
    COALESCE(c.last_message_at, latest_message.created_at) AS last_message_at,
    EXISTS (
      SELECT 1
      FROM messages unread_message
      WHERE unread_message.conversation_id = c.id
        AND unread_message.sender_profile_id IS DISTINCT FROM auth.uid()
        AND unread_message.is_read IS NOT TRUE
    ) AS has_unread,
    c.is_archived,
    c.created_at
  FROM conversations c
  LEFT JOIN loads l ON l.id = c.load_id
  LEFT JOIN profiles supplier_profile ON supplier_profile.id = c.supplier_id
  LEFT JOIN supplier_extensions supplier_extension ON supplier_extension.id = c.supplier_id
  LEFT JOIN profiles trucker_profile ON trucker_profile.id = c.trucker_id
  LEFT JOIN LATERAL (
    SELECT
      br.id AS booking_request_id,
      br.status::TEXT AS booking_status_label,
      t.truck_number,
      t.make AS truck_make,
      t.model AS truck_model
    FROM booking_requests br
    LEFT JOIN trucks t ON t.id = br.truck_id
    WHERE br.conversation_id = c.id
    ORDER BY br.created_at DESC
    LIMIT 1
  ) booking_summary ON true
  LEFT JOIN LATERAL (
    SELECT m.message_type, m.text_body, m.created_at
    FROM messages m
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) latest_message ON true
  WHERE c.id = p_conversation_id
    AND (c.supplier_id = auth.uid() OR c.trucker_id = auth.uid());
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_current_user_conversation_summaries()
 RETURNS TABLE(id uuid, supplier_id uuid, trucker_id uuid, load_id uuid, trip_id uuid, route_label text, load_material text, load_price_amount numeric, load_status_label text, pickup_date date, supplier_name text, supplier_mobile text, supplier_company_name text, supplier_avatar_url text, trucker_name text, trucker_mobile text, truck_display_label text, trucker_avatar_url text, booking_request_id uuid, booking_status_label text, latest_message_type public.message_type, latest_message_text text, last_message_at timestamp with time zone, has_unread boolean, is_archived boolean, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  RETURN QUERY
  WITH scoped_conversations AS (
    SELECT c.*
    FROM conversations c
    WHERE c.supplier_id = auth.uid() OR c.trucker_id = auth.uid()
  )
  SELECT
    c.id,
    c.supplier_id,
    c.trucker_id,
    c.load_id,
    c.trip_id,
    COALESCE(
      NULLIF(CONCAT_WS(' → ', NULLIF(BTRIM(l.origin_label), ''), NULLIF(BTRIM(l.destination_label), '')), ''),
      NULLIF(BTRIM(l.origin_label), ''),
      'Load'
    ) AS route_label,
    l.material AS load_material,
    l.price_amount AS load_price_amount,
    l.status::TEXT AS load_status_label,
    l.pickup_date AS pickup_date,
    COALESCE(NULLIF(BTRIM(supplier_profile.full_name), ''), 'Supplier') AS supplier_name,
    NULLIF(BTRIM(supplier_profile.mobile), '') AS supplier_mobile,
    NULLIF(BTRIM(supplier_extension.company_name), '') AS supplier_company_name,
    COALESCE(supplier_profile.avatar_url, supplier_profile.profile_photo_document_path) AS supplier_avatar_url,
    COALESCE(NULLIF(BTRIM(trucker_profile.full_name), ''), 'Trucker') AS trucker_name,
    NULLIF(BTRIM(trucker_profile.mobile), '') AS trucker_mobile,
    CASE
      WHEN NULLIF(BTRIM(booking_summary.truck_number), '') IS NOT NULL
        AND NULLIF(BTRIM(CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))), '') IS NOT NULL
        THEN booking_summary.truck_number || ' • ' || CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))
      WHEN NULLIF(BTRIM(booking_summary.truck_number), '') IS NOT NULL
        THEN booking_summary.truck_number
      WHEN NULLIF(BTRIM(CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))), '') IS NOT NULL
        THEN CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))
      ELSE NULL
    END AS truck_display_label,
    COALESCE(trucker_profile.avatar_url, trucker_profile.profile_photo_document_path) AS trucker_avatar_url,
    booking_summary.booking_request_id,
    booking_summary.booking_status_label,
    latest_message.message_type AS latest_message_type,
    latest_message.text_body AS latest_message_text,
    COALESCE(c.last_message_at, latest_message.created_at) AS last_message_at,
    EXISTS (
      SELECT 1
      FROM messages unread_message
      WHERE unread_message.conversation_id = c.id
        AND unread_message.sender_profile_id IS DISTINCT FROM auth.uid()
        AND unread_message.is_read = FALSE
      LIMIT 1
    ) AS has_unread,
    c.is_archived,
    c.created_at
  FROM scoped_conversations c
  LEFT JOIN loads l
    ON l.id = c.load_id
  LEFT JOIN profiles supplier_profile
    ON supplier_profile.id = c.supplier_id
  LEFT JOIN suppliers supplier_extension
    ON supplier_extension.id = c.supplier_id
  LEFT JOIN profiles trucker_profile
    ON trucker_profile.id = c.trucker_id
  LEFT JOIN LATERAL (
    SELECT
      br.id AS booking_request_id,
      br.status::TEXT AS booking_status_label,
      tr.truck_number,
      tm.make AS truck_make,
      tm.model AS truck_model
    FROM booking_requests br
    LEFT JOIN trucks tr
      ON tr.id = br.truck_id
    LEFT JOIN truck_models tm
      ON tm.id = tr.truck_model_id
    WHERE br.load_id = c.load_id
      AND br.trucker_id = c.trucker_id
    ORDER BY br.created_at DESC
    LIMIT 1
  ) booking_summary ON TRUE
  LEFT JOIN LATERAL (
    SELECT
      m.message_type,
      m.text_body,
      m.created_at
    FROM messages m
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) latest_message ON TRUE
  ORDER BY COALESCE(c.last_message_at, latest_message.created_at, c.created_at) DESC, c.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_current_user_unread_conversation_count()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  unread_count INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT COUNT(DISTINCT c.id)
  INTO unread_count
  FROM conversations c
  WHERE (c.supplier_id = auth.uid() OR c.trucker_id = auth.uid())
    AND EXISTS (
      SELECT 1
      FROM messages m
      WHERE m.conversation_id = c.id
        AND m.sender_profile_id IS DISTINCT FROM auth.uid()
        AND m.is_read = FALSE
      LIMIT 1
    );

  RETURN COALESCE(unread_count, 0);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_linked_trips_for_supplier(p_load_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_supplier_id UUID;
    v_result JSONB;
BEGIN
    -- Get the supplier_id from the load
    SELECT loads.supplier_id INTO v_supplier_id 
    FROM public.loads 
    WHERE loads.id = p_load_id;
    
    IF v_supplier_id IS NULL THEN
        RETURN '[]'::JSONB;
    END IF;
    
    -- Check if current user is the supplier
    IF auth.uid() <> v_supplier_id THEN
        RETURN '[]'::JSONB;
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id', trip_rows.id,
            'load_id', trip_rows.load_id,
            'trucker_id', trip_rows.trucker_id,
            'truck_id', trip_rows.truck_id,
            'stage', trip_rows.stage,
            'assigned_at', trip_rows.assigned_at,
            'delivered_at', trip_rows.delivered_at,
            'pod_uploaded_at', trip_rows.pod_uploaded_at,
            'completed_at', trip_rows.completed_at,
            'lr_document_path', trip_rows.lr_document_path,
            'pod_document_path', trip_rows.pod_document_path,
            'load_data', jsonb_build_object(
                'id', load_rows.id,
                'parent_load_id', load_rows.parent_load_id,
                'origin_label', load_rows.origin_label,
                'destination_label', load_rows.destination_label,
                'material', load_rows.material
            )
        ) ORDER BY trip_rows.assigned_at DESC
    ) INTO v_result
    FROM public.trips trip_rows
    JOIN public.loads load_rows ON load_rows.id = trip_rows.load_id
    WHERE trip_rows.supplier_id = v_supplier_id
      AND (
          load_rows.id = p_load_id 
          OR load_rows.parent_load_id = p_load_id
      );
      
    RETURN COALESCE(v_result, '[]'::JSONB);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_marketplace_feed(p_origin_city text DEFAULT NULL::text, p_destination_city text DEFAULT NULL::text, p_material text DEFAULT NULL::text, p_body_type text DEFAULT NULL::text, p_min_price numeric DEFAULT NULL::numeric, p_max_price numeric DEFAULT NULL::numeric, p_super_loads_only boolean DEFAULT false, p_required_tyres integer[] DEFAULT NULL::integer[], p_sort_by text DEFAULT 'newest'::text, p_page_size integer DEFAULT 20, p_page integer DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
        'supplier_photo_path',  p.profile_photo_document_path,
        'supplier_mobile',      p.mobile,
        'supplier_trust_score', COALESCE((
          SELECT avg_rating FROM public.profile_trust_scores WHERE user_id = p.id
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_notification_preferences(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_preferences JSONB;
BEGIN
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
  WHERE np.user_id = p_user_id;

  -- Return default preferences if not set
  IF v_preferences IS NULL THEN
    RETURN jsonb_build_object(
      'user_id', p_user_id,
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_profile_reviews(p_user_id uuid, p_limit integer DEFAULT 5, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_public_load_previews(p_supplier_id uuid, p_limit integer DEFAULT 5, p_offset integer DEFAULT 0, p_status_filter text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_results JSONB;
    v_total   BIGINT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = p_supplier_id AND p.verification_status = 'verified'
    ) THEN
        RETURN jsonb_build_object('loads', '[]'::JSONB, 'total', 0);
    END IF;

    SELECT COUNT(*) INTO v_total
    FROM public.loads l
    WHERE l.supplier_id = p_supplier_id
      AND l.parent_load_id IS NULL
      AND (
          p_status_filter IS NOT NULL
          AND p_status_filter <> ''
          AND l.status = p_status_filter::load_status
          OR p_status_filter IS NULL
          OR p_status_filter = ''
      )
      AND l.status IN ('active', 'completed', 'assigned_partial', 'assigned_full');

    SELECT jsonb_agg(row_to_json(t) ORDER BY t.created_at DESC)
    INTO v_results
    FROM (
        SELECT
            l.id,
            l.origin_city,
            l.destination_city,
            l.material,
            l.weight_tonnes,
            l.price_amount,
            l.price_type,
            l.pickup_date,
            l.status,
            l.created_at
        FROM public.loads l
        WHERE l.supplier_id = p_supplier_id
          AND l.parent_load_id IS NULL
          AND (
              p_status_filter IS NOT NULL
              AND p_status_filter <> ''
              AND l.status = p_status_filter::load_status
              OR p_status_filter IS NULL
              OR p_status_filter = ''
          )
          AND l.status IN ('active', 'completed', 'assigned_partial', 'assigned_full')
        ORDER BY l.created_at DESC
        LIMIT p_limit
        OFFSET p_offset
    ) t;

    RETURN jsonb_build_object(
        'loads', COALESCE(v_results, '[]'::JSONB),
        'total', v_total
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_public_profile(p_user_id uuid, p_viewer_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
        SELECT EXISTS (
            -- Active/completed trips where p_user_id is trucker and p_viewer_id is supplier
            SELECT 1 FROM public.trips t
            WHERE t.trucker_id = p_user_id AND t.supplier_id = p_viewer_id
               AND t.stage NOT IN ('completed', 'cancelled')
            UNION
            -- Active/completed trips where p_user_id is supplier and p_viewer_id is trucker
            SELECT 1 FROM public.trips t
            WHERE t.trucker_id = p_viewer_id AND t.supplier_id = p_user_id
               AND t.stage NOT IN ('completed', 'cancelled')
            UNION
            -- Active booking requests where p_user_id is supplier and p_viewer_id is trucker
            SELECT 1 FROM public.booking_requests br
            JOIN public.loads l ON l.id = br.load_id
            WHERE l.supplier_id = p_user_id AND br.trucker_id = p_viewer_id
               AND br.status IN ('submitted', 'approved')
            UNION
            -- Active booking requests where p_user_id is trucker and p_viewer_id is supplier
            SELECT 1 FROM public.booking_requests br
            JOIN public.loads l ON l.id = br.load_id
            WHERE l.supplier_id = p_viewer_id AND br.trucker_id = p_user_id
               AND br.status IN ('submitted', 'approved')
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_booking_requests(p_load_id uuid)
 RETURNS TABLE(id uuid, load_id uuid, trucker_id uuid, truck_id uuid, status public.booking_status, decision_reason text, created_at timestamp with time zone, decided_at timestamp with time zone, trucker_name text, trucker_verification_status public.verification_status, trucker_rating numeric, trucker_avatar_url text, truck_number text, truck_body_type text, truck_tyres integer, truck_model_label text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_supplier_id UUID;
BEGIN
  v_supplier_id := auth.uid();

  -- Security check: verify supplier owns the load
  IF NOT EXISTS (
    SELECT 1
    FROM loads
    WHERE loads.id = p_load_id
      AND loads.supplier_id = v_supplier_id
  ) THEN
    RAISE EXCEPTION 'Load not found or access denied';
  END IF;

  RETURN QUERY
  SELECT
    br.id AS id,
    br.load_id,
    br.trucker_id,
    br.truck_id,
    br.status,
    br.decision_reason,
    br.created_at,
    br.decided_at,
    COALESCE(NULLIF(p.full_name, ''), 'Trucker') AS trucker_name,
    COALESCE(p.verification_status, 'unverified'::verification_status) AS trucker_verification_status,
    COALESCE(tkr.rating, 0) AS trucker_rating,
    COALESCE(p.avatar_url, p.profile_photo_document_path) AS trucker_avatar_url,
    tr.truck_number,
    tr.body_type AS truck_body_type,
    tr.tyres AS truck_tyres,
    CASE
      WHEN tm.make IS NOT NULL AND tm.model IS NOT NULL THEN tm.make || ' ' || tm.model
      WHEN tm.make IS NOT NULL THEN tm.make
      WHEN tm.model IS NOT NULL THEN tm.model
      ELSE NULL
    END AS truck_model_label
  FROM booking_requests br
  JOIN loads l ON l.id = br.load_id
  LEFT JOIN profiles p ON p.id = br.trucker_id
  LEFT JOIN truckers tkr ON tkr.id = br.trucker_id
  LEFT JOIN trucks tr ON tr.id = br.truck_id
  LEFT JOIN truck_models tm ON tm.id = tr.truck_model_id
  WHERE br.load_id = p_load_id
    AND l.supplier_id = v_supplier_id
  ORDER BY br.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_dashboard_stats(p_supplier_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_supplier_trip_detail(p_trip_id uuid, p_supplier_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_ticket_attachments(p_ticket_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_attachments JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', ta.id,
      'ticket_id', ta.ticket_id,
      'uploaded_by', ta.uploaded_by,
      'file_name', ta.file_name,
      'file_path', ta.file_path,
      'file_size', ta.file_size,
      'mime_type', ta.mime_type,
      'file_hash', ta.file_hash,
      'upload_status', ta.upload_status,
      'upload_error_message', ta.upload_error_message,
      'retry_count', ta.retry_count,
      'max_retries', ta.max_retries,
      'scan_status', ta.scan_status,
      'scan_result', ta.scan_result,
      'scanned_at', ta.scanned_at,
      'created_at', ta.created_at,
      'updated_at', ta.updated_at,
      'uploader_name', p.full_name,
      'uploader_avatar', p.avatar_url
    )
    ORDER BY ta.created_at ASC
  ) INTO v_attachments
  FROM public.ticket_attachments ta
  JOIN public.profiles p ON p.id = ta.uploaded_by
  WHERE ta.ticket_id = p_ticket_id;

  RETURN COALESCE(v_attachments, '[]'::JSONB);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_trip_auto_completion_status(p_trip_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
  v_remaining_seconds INT;
  v_status TEXT;
BEGIN
  -- Fetch trip
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Trip not found');
  END IF;

  -- Calculate remaining time
  IF v_trip.auto_completion_enabled AND v_trip.auto_completion_expected_at IS NOT NULL THEN
    v_remaining_seconds := EXTRACT(EPOCH FROM (v_trip.auto_completion_expected_at - NOW()))::INT;
    
    IF v_remaining_seconds <= 0 THEN
      v_status := 'expired';
      v_remaining_seconds := 0;
    ELSIF v_remaining_seconds < 3600 THEN
      v_status := 'urgent'; -- Less than 1 hour
    ELSE
      v_status := 'active';
    END IF;
  ELSE
    v_remaining_seconds := 0;
    v_status := 'not_enabled';
  END IF;

  RETURN jsonb_build_object(
    'trip_id', p_trip_id,
    'auto_completion_enabled', v_trip.auto_completion_enabled,
    'auto_completion_expected_at', v_trip.auto_completion_expected_at,
    'auto_completion_countdown_seconds', v_trip.auto_completion_countdown_seconds,
    'remaining_seconds', v_remaining_seconds,
    'status', v_status,
    'supplier_confirmation_required', v_trip.supplier_confirmation_required,
    'supplier_confirmation_deadline', v_trip.supplier_confirmation_deadline,
    'supplier_confirmed_at', v_trip.supplier_confirmed_at,
    'can_confirm', v_trip.supplier_confirmation_required AND v_trip.supplier_confirmed_at IS NULL
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_trip_detail_with_supplier(p_trip_id uuid, p_trucker_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_trip_dispute_summary(p_trip_id uuid)
 RETURNS TABLE(category text, status text, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
BEGIN
  SELECT id, supplier_id, trucker_id
  INTO v_trip
  FROM trips
  WHERE id = p_trip_id;

  IF v_trip IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  IF auth.uid() IS DISTINCT FROM v_trip.supplier_id
     AND auth.uid() IS DISTINCT FROM v_trip.trucker_id THEN
    RAISE EXCEPTION 'Not allowed to view this trip dispute summary';
  END IF;

  RETURN QUERY
  SELECT
    st.category::TEXT,
    st.status::TEXT,
    st.updated_at
  FROM support_tickets st
  WHERE st.related_trip_id = p_trip_id
    AND st.category IN (
      'loaded_quantity_mismatch',
      'unloaded_quantity_mismatch',
      'document_mismatch',
      'non_payment',
      'fake_payout_proof',
      'delay_or_no_show',
      'damage_or_shortage',
      'abusive_behavior',
      'spam_or_scam',
      'other',
      'trip_dispute'
    )
  ORDER BY st.created_at DESC
  LIMIT 1;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_trucker_dashboard_stats(p_trucker_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_full_name TEXT;
  v_email TEXT;
  v_mobile TEXT;
BEGIN
  v_full_name := COALESCE(
    NULLIF(BTRIM(COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', '')), ''),
    NULLIF(BTRIM(SPLIT_PART(COALESCE(NEW.email, ''), '@', 1)), ''),
    'User'
  );
  v_email := NULLIF(BTRIM(COALESCE(NEW.email, '')), '');
  v_mobile := NULLIF(BTRIM(COALESCE(NEW.phone, '')), '');

  INSERT INTO public.profiles (id, full_name, email, mobile)
  VALUES (
    NEW.id,
    v_full_name,
    v_email,
    v_mobile
  );

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users
    WHERE auth_user_id = auth.uid()
      AND is_active = TRUE
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_super_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE auth_user_id = auth.uid()
      AND is_active = TRUE
      AND role = 'super_admin'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE notifications SET is_read = TRUE, read_at = NOW()
  WHERE target_profile_id = auth.uid() AND is_read = FALSE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE notifications SET is_read = TRUE, read_at = NOW()
  WHERE id = p_notification_id AND target_profile_id = auth.uid();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.mark_super_load_under_review(p_load_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status != 'request_submitted' THEN
    RAISE EXCEPTION 'Only submitted active Super Load requests can move under review';
  END IF;

  UPDATE loads
  SET super_status = 'under_review',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'load',
    p_load_id,
    'Super Load moved under review',
    jsonb_build_object(
      'super_status', 'under_review'
    ),
    'internal'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_verification_sla_approaching()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_case_count INTEGER := 0;
  v_notification_count INTEGER := 0;
BEGIN
  SELECT COUNT(*) INTO v_case_count
  FROM verification_cases
  WHERE case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission')
    AND submitted_at <= NOW() - INTERVAL '20 hours'
    AND submitted_at > NOW() - INTERVAL '24 hours';

  IF v_case_count = 0 THEN
    RETURN 0;
  END IF;

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'system_notice',
    'medium',
    'SLA Alert',
    v_case_count::text || ' verifications approaching 24h SLA',
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM notifications
      WHERE target_admin_user_id = admin_users.id
        AND notification_type = 'system_notice'
        AND title_text = 'SLA Alert'
        AND action_route_hint = '/admin/verification-queue'
        AND created_at::date = CURRENT_DATE
    );

  GET DIAGNOSTICS v_notification_count = ROW_COUNT;
  RETURN v_notification_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.raise_trip_dispute(p_trip_id uuid, p_category text, p_reason text, p_attachment_path text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
  v_reason TEXT;
  v_category TEXT;
  v_support_ticket_id UUID;
  v_operational_case_id UUID;
BEGIN
  v_reason := btrim(COALESCE(p_reason, ''));
  v_category := lower(btrim(COALESCE(p_category, '')));

  IF v_category NOT IN (
    'loaded_quantity_mismatch',
    'unloaded_quantity_mismatch',
    'document_mismatch',
    'non_payment',
    'fake_payout_proof',
    'delay_or_no_show',
    'damage_or_shortage',
    'abusive_behavior',
    'spam_or_scam',
    'other'
  ) THEN
    RAISE EXCEPTION 'Unsupported dispute category';
  END IF;

  IF char_length(v_reason) < 10 THEN
    RAISE EXCEPTION 'Dispute reason too short';
  END IF;

  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.supplier_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;
  IF v_trip.stage != 'proof_submitted' THEN RAISE EXCEPTION 'Trip not in proof_submitted stage'; END IF;

  INSERT INTO support_tickets (
    owner_profile_id,
    category,
    status,
    priority,
    related_load_id,
    related_trip_id
  ) VALUES (
    auth.uid(),
    v_category,
    'open',
    'high',
    v_trip.load_id,
    p_trip_id
  ) RETURNING id INTO v_support_ticket_id;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_profile_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    v_support_ticket_id,
    auth.uid(),
    v_reason,
    NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
    'visible'
  );

  INSERT INTO operational_cases (
    case_type,
    primary_object_type,
    primary_object_id,
    queue_classification,
    status
  ) VALUES (
    'trip_dispute',
    'trip',
    p_trip_id,
    NULL,
    'queued'
  ) RETURNING id INTO v_operational_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    v_operational_case_id,
    'case_created',
    'Supplier raised POD dispute: ' || replace(v_category, '_', ' '),
    v_reason
  );

  UPDATE trips
  SET stage = 'disputed'
  WHERE id = p_trip_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_trip.trucker_id,
    'dispute_update',
    'high',
    'Supplier raised a trip dispute',
    'A proof-of-delivery dispute was raised for your trip. Open trip detail for the latest review status.',
    v_trip.load_id,
    p_trip_id,
    v_operational_case_id,
    '/trip-detail/' || p_trip_id::text
  );

  RETURN v_support_ticket_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.raise_trip_dispute(p_trip_id uuid, p_reason text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN raise_trip_dispute(
    p_trip_id := p_trip_id,
    p_category := 'document_mismatch',
    p_reason := p_reason,
    p_attachment_path := NULL
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.reject_booking_request(p_booking_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_booking RECORD;
  v_load RECORD;
BEGIN
  SELECT * INTO v_booking FROM booking_requests WHERE id = p_booking_id FOR UPDATE;
  IF v_booking IS NULL OR v_booking.status != 'submitted' THEN
    RAISE EXCEPTION 'Booking not found or not in submitted state';
  END IF;

  SELECT * INTO v_load FROM loads WHERE id = v_booking.load_id;
  IF v_load.supplier_id != auth.uid() THEN RAISE EXCEPTION 'Not your load'; END IF;

  UPDATE booking_requests SET
    status = 'rejected', decision_reason = p_reason, decided_at = NOW()
  WHERE id = p_booking_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.reject_super_load_request(p_load_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
  v_reason TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status NOT IN ('request_submitted', 'under_review', 'approved_payment_pending') THEN
    RAISE EXCEPTION 'Super Load request is not awaiting review';
  END IF;

  UPDATE loads
  SET is_super_load = FALSE,
      super_status = 'rejected',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'super_load_rejected',
    'load',
    p_load_id,
    'Super Load rejected',
    jsonb_build_object(
      'reason', v_reason
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'super_load_update',
    'high',
    'Super Load Rejected',
    'Your Super Load request was not approved',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.reject_verification_case(p_case_id uuid, p_reason text, p_feedback_json jsonb DEFAULT NULL::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_reason TEXT;
  v_feedback_json JSONB;
  v_feedback_summary TEXT;
  v_feedback_next_step TEXT;
  v_default_next_step TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason := btrim(COALESCE(p_reason, ''));
  IF char_length(v_reason) < 5 THEN
    RAISE EXCEPTION 'Rejection reason is too short';
  END IF;

  v_feedback_json := COALESCE(p_feedback_json, '{}'::jsonb);
  IF jsonb_typeof(v_feedback_json) <> 'object' THEN
    RAISE EXCEPTION 'Verification feedback payload must be a JSON object';
  END IF;
  IF v_feedback_json ? 'documents' AND jsonb_typeof(v_feedback_json -> 'documents') <> 'object' THEN
    RAISE EXCEPTION 'Verification feedback documents payload must be a JSON object';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Verification case not found';
  END IF;

  IF v_case.subject_type NOT IN ('supplier_profile', 'trucker_profile') THEN
    RAISE EXCEPTION 'reject_verification_case only supports profile verification cases';
  END IF;

  IF v_case.case_status NOT IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission') THEN
    RAISE EXCEPTION 'Verification case is not awaiting review';
  END IF;

  v_default_next_step := CASE
    WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update'
      THEN 'Replace the profile photo and resubmit it for review.'
    ELSE 'Replace the affected verification items and resubmit for review.'
  END;

  v_feedback_summary := NULLIF(btrim(COALESCE(v_feedback_json ->> 'summary', '')), '');
  v_feedback_next_step := NULLIF(btrim(COALESCE(v_feedback_json ->> 'next_step', '')), '');
  v_feedback_json := v_feedback_json || jsonb_build_object(
    'summary', COALESCE(v_feedback_summary, v_reason),
    'next_step', COALESCE(v_feedback_next_step, v_default_next_step)
  );

  UPDATE verification_cases
  SET case_status = 'rejected',
      assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
      last_reviewed_at = NOW(),
      current_decision_summary = v_reason,
      current_review_feedback_json = v_feedback_json,
      updated_at = NOW()
  WHERE id = p_case_id;

  IF COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN
    UPDATE profiles
    SET profile_photo_review_status = 'rejected',
        profile_photo_rejection_reason = v_reason,
        profile_photo_feedback_json = v_feedback_json,
        profile_photo_last_reviewed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  ELSE
    UPDATE profiles
    SET verification_status = 'rejected',
        verification_rejection_reason = v_reason,
        verification_feedback_json = v_feedback_json,
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  END IF;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    'rejected',
    v_admin_user_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo rejected'
      ELSE 'Verification rejected'
    END,
    v_reason
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'user_verification_rejected',
    'verification_case',
    p_case_id,
    'profile',
    v_case.subject_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo rejected'
      ELSE 'Verification rejected'
    END,
    jsonb_build_object(
      'subject_type', v_case.subject_type,
      'review_type', COALESCE(v_case.review_type, 'full_verification'),
      'reason', v_reason,
      'feedback', v_feedback_json
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_case.subject_id,
    'verification_update',
    'high',
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile Photo Update'
      ELSE 'Verification Update'
    END,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Please review your profile photo feedback and resubmit the photo update.'
      ELSE 'Please review your verification feedback and resubmit the affected items.'
    END,
    p_case_id,
    '/profile'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.release_operational_case(p_case_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'claimed' THEN
    RAISE EXCEPTION 'Only claimed cases can be released';
  END IF;

  IF v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id
     AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only the claimed admin or a super admin can release this case';
  END IF;

  UPDATE operational_cases
  SET status = 'queued',
      claimed_by_admin_user_id = NULL,
      claimed_at = NULL,
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_released',
    'Operational case released back to queue'
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'operational_case',
    p_case_id,
    'Operational case released',
    '{}'::jsonb,
    'internal'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.reply_to_support_ticket(p_support_ticket_id uuid, p_message_body text, p_visibility_class text DEFAULT 'visible'::text, p_attachment_path text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_user_id UUID;
  v_ticket RECORD;
  v_message_id UUID;
  v_message_body TEXT;
  v_visibility_class TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  v_user_id := auth.uid();

  IF v_admin_user_id IS NULL AND v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  v_message_body := btrim(COALESCE(p_message_body, ''));
  IF char_length(v_message_body) < 2 THEN
    RAISE EXCEPTION 'Reply is too short';
  END IF;

  v_visibility_class := lower(btrim(COALESCE(p_visibility_class, 'visible')));
  IF v_admin_user_id IS NOT NULL AND v_visibility_class NOT IN ('visible', 'internal') THEN
    RAISE EXCEPTION 'Unsupported visibility class';
  END IF;
  IF v_admin_user_id IS NULL AND v_visibility_class != 'visible' THEN
    RAISE EXCEPTION 'Users can only send visible replies';
  END IF;

  SELECT * INTO v_ticket
  FROM support_tickets
  WHERE id = p_support_ticket_id
  FOR UPDATE;

  IF v_ticket IS NULL THEN
    RAISE EXCEPTION 'Support ticket not found';
  END IF;

  IF v_admin_user_id IS NOT NULL THEN
    INSERT INTO support_ticket_messages (
      support_ticket_id,
      sender_admin_user_id,
      message_body,
      attachment_path,
      visibility_class
    ) VALUES (
      p_support_ticket_id,
      v_admin_user_id,
      v_message_body,
      NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
      v_visibility_class
    ) RETURNING id INTO v_message_id;

    UPDATE support_tickets
    SET status = CASE
          WHEN status IN ('open', 'waiting_for_user') THEN 'in_progress'::support_ticket_status
          ELSE status
        END,
        updated_at = NOW()
    WHERE id = p_support_ticket_id;

    INSERT INTO audit_logs (
      actor_admin_user_id,
      actor_type,
      actor_role,
      action_type,
      target_object_type,
      target_object_id,
      secondary_object_type,
      secondary_object_id,
      summary_text,
      payload_json,
      visibility_class
    ) VALUES (
      v_admin_user_id,
      'admin',
      get_admin_role()::text,
      'override_action',
      'support_ticket',
      p_support_ticket_id,
      'support_ticket_message',
      v_message_id,
      'Admin replied to support ticket',
      jsonb_build_object(
        'visibility_class', v_visibility_class,
        'has_attachment', NULLIF(btrim(COALESCE(p_attachment_path, '')), '') IS NOT NULL
      ),
      'internal'
    );

    IF v_visibility_class = 'visible' THEN
      INSERT INTO notifications (
        target_profile_id,
        notification_type,
        notification_priority,
        title_text,
        body_text,
        related_load_id,
        related_trip_id,
        related_case_id,
        action_route_hint
      ) VALUES (
        v_ticket.owner_profile_id,
        'support_update',
        'medium',
        'Support Reply',
        'Your ticket has a new response',
        v_ticket.related_load_id,
        v_ticket.related_trip_id,
        p_support_ticket_id,
        '/support'
      );
    END IF;

    RETURN v_message_id;
  END IF;

  IF v_ticket.owner_profile_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Support ticket does not belong to current user';
  END IF;

  IF v_ticket.status IN ('resolved', 'closed') THEN
    RAISE EXCEPTION 'Support ticket is already closed';
  END IF;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_profile_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    p_support_ticket_id,
    v_user_id,
    v_message_body,
    NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
    'visible'
  ) RETURNING id INTO v_message_id;

  UPDATE support_tickets
  SET status = CASE
        WHEN status = 'waiting_for_user' THEN 'in_progress'::support_ticket_status
        ELSE status
      END,
      updated_at = NOW()
  WHERE id = p_support_ticket_id;

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'support_update',
    CASE
      WHEN v_ticket.priority IN ('high', 'urgent') THEN 'high'::notification_priority
      ELSE 'medium'::notification_priority
    END,
    'User Reply',
    'A support ticket has a new user reply.',
    v_ticket.related_load_id,
    v_ticket.related_trip_id,
    p_support_ticket_id,
    '/admin/support'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_message_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.request_account_deletion()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_profile RECORD;
  v_blocker TEXT;
  v_has_active_trips BOOLEAN;
  v_has_unresolved_disputes BOOLEAN;
  v_has_compliance_records BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_profile
  FROM profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_profile.account_deletion_status = 'permanently_deleted' THEN
    RAISE EXCEPTION 'Account is already permanently deleted';
  END IF;

  IF v_profile.account_deletion_status = 'deactivated_pending_cleanup' THEN
    RETURN jsonb_build_object(
      'status', 'deactivated_pending_cleanup',
      'blocked', false,
      'message', 'Account is already pending cleanup'
    );
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM trips
    WHERE (supplier_id = v_user_id OR trucker_id = v_user_id)
      AND stage NOT IN ('completed', 'cancelled')
  ) INTO v_has_active_trips;

  SELECT EXISTS (
    SELECT 1
    FROM support_tickets
    WHERE owner_profile_id = v_user_id
      AND status NOT IN ('resolved', 'closed')
  ) INTO v_has_unresolved_disputes;

  SELECT EXISTS (
    SELECT 1
    FROM verification_cases
    WHERE subject_id = v_user_id
      AND case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated')
  ) INTO v_has_compliance_records;

  IF v_has_active_trips THEN
    v_blocker := 'active trips';
  ELSIF v_has_unresolved_disputes THEN
    v_blocker := 'unresolved disputes';
  ELSIF v_has_compliance_records THEN
    v_blocker := 'compliance records';
  ELSE
    v_blocker := NULL;
  END IF;

  IF v_blocker IS NOT NULL THEN
    UPDATE profiles
    SET account_deletion_status = 'blocked_by_dependency',
        updated_at = NOW()
    WHERE id = v_user_id;

    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      action_route_hint
    ) VALUES (
      v_user_id,
      'account_update',
      'high',
      'Deletion Blocked',
      'Active ' || v_blocker || ' prevents account deletion',
      '/profile'
    );

    RETURN jsonb_build_object(
      'status', 'blocked_by_dependency',
      'blocked', true,
      'blocker', v_blocker,
      'message', 'Account deletion is blocked by ' || v_blocker
    );
  END IF;

  UPDATE profiles
  SET account_deletion_status = 'deactivated_pending_cleanup',
      data_deletion_requested_at = COALESCE(data_deletion_requested_at, NOW()),
      updated_at = NOW()
  WHERE id = v_user_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    NULL,
    'user',
    NULL,
    'deletion_request_processed',
    'profile',
    v_user_id,
    'User requested account deletion',
    jsonb_build_object(
      'account_deletion_status', 'deactivated_pending_cleanup'
    ),
    'internal'
  );

  RETURN jsonb_build_object(
    'status', 'deactivated_pending_cleanup',
    'blocked', false,
    'message', 'Account deletion requested and account deactivated pending cleanup'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.request_super_load(p_load_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_load RECORD;
  v_supplier_name TEXT;
BEGIN
  SELECT l.*, p.full_name INTO v_load
  FROM loads l
  JOIN profiles p ON p.id = l.supplier_id
  WHERE l.id = p_load_id
    AND l.supplier_id = auth.uid()
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.parent_load_id IS NOT NULL THEN
    RAISE EXCEPTION 'Only parent loads can request Super Load';
  END IF;

  IF v_load.status != 'active' THEN
    RAISE EXCEPTION 'Only active loads can request Super Load';
  END IF;

  IF v_load.super_status NOT IN ('none', 'rejected') THEN
    RAISE EXCEPTION 'Super Load request is already in progress or active';
  END IF;

  UPDATE loads
  SET is_super_load = TRUE,
      super_status = 'request_submitted',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'super_load_update',
    'medium',
    'New Super Load Request',
    p.full_name || ': ' || v_load.material || ' ' || v_load.origin_city || '→' || v_load.destination_city,
    p_load_id,
    '/admin/super-ops'
  FROM admin_users
  JOIN profiles p ON p.id = v_load.supplier_id
  WHERE admin_users.is_active = TRUE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.resolve_operational_case(p_case_id uuid, p_resolution_summary text, p_resolution_status public.operational_case_status DEFAULT 'resolved'::public.operational_case_status)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_trip RECORD;
  v_resolution_summary TEXT;
  v_event_type TEXT;
  v_event_summary TEXT;
  v_notification_title TEXT;
  v_notification_body TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_resolution_summary := btrim(COALESCE(p_resolution_summary, ''));
  IF char_length(v_resolution_summary) < 5 THEN
    RAISE EXCEPTION 'Resolution summary is too short';
  END IF;

  IF p_resolution_status NOT IN ('resolved', 'rejected') THEN
    RAISE EXCEPTION 'Resolution status must be resolved or rejected';
  END IF;

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'in_review' THEN
    RAISE EXCEPTION 'Operational case must be in review to resolve';
  END IF;

  IF v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id
     AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only the claimed admin or a super admin can resolve this case';
  END IF;

  UPDATE operational_cases
  SET status = p_resolution_status,
      resolution_summary = v_resolution_summary,
      resolved_at = NOW(),
      waiting_reason = NULL,
      updated_at = NOW()
  WHERE id = p_case_id;

  v_event_type := CASE
    WHEN p_resolution_status = 'resolved' THEN 'case_resolved'
    ELSE 'case_rejected'
  END;

  v_event_summary := CASE
    WHEN p_resolution_status = 'resolved' THEN 'Operational case resolved'
    ELSE 'Operational case rejected'
  END;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    v_event_type,
    v_event_summary,
    v_resolution_summary
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    CASE
      WHEN p_resolution_status = 'resolved' THEN 'case_resolved'::audit_action_type
      ELSE 'override_action'::audit_action_type
    END,
    'operational_case',
    p_case_id,
    v_event_summary,
    jsonb_build_object(
      'resolution_status', p_resolution_status,
      'resolution_summary', v_resolution_summary
    ),
    'internal'
  );

  IF v_case.case_type = 'trip_dispute' AND v_case.primary_object_type = 'trip' THEN
    SELECT * INTO v_trip
    FROM trips
    WHERE id = v_case.primary_object_id;

    IF v_trip IS NOT NULL THEN
      UPDATE support_tickets
      SET status = 'resolved',
          resolution_summary = v_resolution_summary,
          resolved_at = NOW(),
          updated_at = NOW()
      WHERE related_trip_id = v_case.primary_object_id
        AND category = 'trip_dispute'
        AND resolved_at IS NULL;

      v_notification_title := CASE
        WHEN p_resolution_status = 'resolved' THEN 'Dispute Resolved'
        ELSE 'Report reviewed and closed'
      END;

      v_notification_body := CASE
        WHEN p_resolution_status = 'resolved' THEN 'Your dispute has been resolved'
        ELSE 'Your dispute report has been reviewed and closed'
      END;

      INSERT INTO notifications (
        target_profile_id,
        notification_type,
        notification_priority,
        title_text,
        body_text,
        related_load_id,
        related_trip_id,
        related_case_id,
        action_route_hint
      ) VALUES
      (
        v_trip.supplier_id,
        'dispute_update',
        'medium',
        v_notification_title,
        v_notification_body,
        v_trip.load_id,
        v_trip.id,
        p_case_id,
        '/trip-detail/' || v_trip.id::text
      ),
      (
        v_trip.trucker_id,
        'dispute_update',
        'medium',
        v_notification_title,
        v_notification_body,
        v_trip.load_id,
        v_trip.id,
        p_case_id,
        '/trip-detail/' || v_trip.id::text
      );
    END IF;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.resubmit_verification_case()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN submit_verification_for_review();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.run_rpc_contract_smoke_tests()
 RETURNS TABLE(test_name text, passed boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result JSONB;
    v_profile_id UUID;
    v_trip_id UUID;
BEGIN
    -- Pick a real profile to use as a test target (any verified trucker or supplier)
    SELECT id INTO v_profile_id FROM public.profiles WHERE user_role_type IN ('supplier','trucker') LIMIT 1;
    SELECT id INTO v_trip_id FROM public.trips LIMIT 1;

    -- ─── Test: version endpoint exists ───
    test_name := 'version_endpoint_exists';
    BEGIN
        SELECT public.get_backend_rpc_contract_version() INTO v_result;
        passed := (v_result ? 'version');
        message := CASE WHEN passed THEN 'ok' ELSE 'missing version key' END;
        RETURN NEXT;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_supplier_dashboard_stats shape ───
    test_name := 'get_supplier_dashboard_stats_shape';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_supplier_dashboard_stats(v_profile_id) INTO v_result;
            passed := (v_result ? 'active_loads') AND (v_result ? 'pending_bookings')
                      AND (v_result ? 'in_transit_trips') AND (v_result ? 'completed_trips');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_trucker_dashboard_stats shape ───
    test_name := 'get_trucker_dashboard_stats_shape';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_trucker_dashboard_stats(v_profile_id) INTO v_result;
            passed := (v_result ? 'active_bids') AND (v_result ? 'upcoming_trips')
                      AND (v_result ? 'in_transit_trips') AND (v_result ? 'completed_trips')
                      AND (v_result ? 'total_trucks') AND (v_result ? 'approved_trucks');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_public_profile shape ───
    test_name := 'get_public_profile_shape';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_public_profile(v_profile_id, v_profile_id) INTO v_result;
            passed := (v_result ? 'id') AND (v_result ? 'full_name')
                      AND (v_result ? 'role') AND (v_result ? 'trust_scores')
                      AND (v_result ? 'is_self');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_profile_reviews returns array ───
    test_name := 'get_profile_reviews_array';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_profile_reviews(v_profile_id, 5, 0) INTO v_result;
            passed := jsonb_typeof(v_result) = 'array';
            message := CASE WHEN passed THEN 'ok' ELSE 'expected jsonb array, got ' || jsonb_typeof(v_result) END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_trip_detail_with_supplier shape ───
    test_name := 'get_trip_detail_with_supplier_shape';
    BEGIN
        IF v_trip_id IS NULL OR v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test trip/profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_trip_detail_with_supplier(v_trip_id, v_profile_id) INTO v_result;
            passed := (v_result ? 'trip') AND (v_result ? 'supplier_profile')
                      AND (v_result ? 'supplier_extension');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_message(p_conversation_id uuid, p_message_type public.message_type, p_message_id uuid DEFAULT NULL::uuid, p_text_body text DEFAULT NULL::text, p_attachment_path text DEFAULT NULL::text, p_structured_payload jsonb DEFAULT NULL::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_msg_id UUID;
  v_conv RECORD;
  v_target_profile_id UUID;
  v_sender_name TEXT;
  v_preview TEXT;
BEGIN
  SELECT * INTO v_conv FROM conversations WHERE id = p_conversation_id;
  IF v_conv IS NULL THEN RAISE EXCEPTION 'Conversation not found'; END IF;

  IF auth.uid() NOT IN (v_conv.supplier_id, v_conv.trucker_id) THEN
    RAISE EXCEPTION 'Not a participant in this conversation';
  END IF;

  INSERT INTO messages (
    id,
    conversation_id,
    sender_profile_id,
    message_type,
    text_body,
    attachment_path,
    structured_payload
  )
  VALUES (
    COALESCE(p_message_id, gen_random_uuid()),
    p_conversation_id,
    auth.uid(),
    p_message_type,
    p_text_body,
    p_attachment_path,
    p_structured_payload
  )
  RETURNING id INTO v_msg_id;

  UPDATE conversations SET last_message_at = NOW() WHERE id = p_conversation_id;

  v_target_profile_id := CASE
    WHEN auth.uid() = v_conv.supplier_id THEN v_conv.trucker_id
    ELSE v_conv.supplier_id
  END;

  SELECT COALESCE(NULLIF(full_name, ''), 'New message')
  INTO v_sender_name
  FROM profiles
  WHERE id = auth.uid();

  v_preview := btrim(COALESCE(p_text_body, ''));
  IF v_preview = '' THEN
    v_preview := 'Sent you an attachment';
  END IF;
  v_preview := left(v_preview, 120);

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_target_profile_id,
    'message_received',
    'medium',
    'New Message',
    v_sender_name || ': ' || v_preview,
    v_conv.load_id,
    '/chat/' || p_conversation_id::text
  );

  RETURN v_msg_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_current_user_preferred_language(p_preferred_language text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID := auth.uid();
  v_language TEXT := LOWER(BTRIM(COALESCE(p_preferred_language, '')));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_language NOT IN ('en', 'hi') THEN
    RAISE EXCEPTION 'Unsupported language. Supported values: en, hi.'
      USING ERRCODE = '22023';
  END IF;

  -- Ensure the profile row exists and respects the existing onboarding upsert logic.
  PERFORM public.upsert_current_user_profile();

  UPDATE public.profiles
  SET preferred_language = v_language,
      updated_at = NOW()
  WHERE id = v_user_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_push_token(p_token text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE profiles
  SET push_token = p_token
  WHERE id = auth.uid();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_booking_request(p_load_id uuid, p_truck_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_booking_id UUID;
  v_trucker_id UUID;
  v_load RECORD;
  v_truck RECORD;
  v_trucker_name TEXT;
BEGIN
  v_trucker_id := auth.uid();

  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_trucker_id AND verification_status = 'verified') THEN
    RAISE EXCEPTION 'Trucker not verified';
  END IF;

  SELECT * INTO v_load FROM loads WHERE id = p_load_id AND parent_load_id IS NULL FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available for booking'; END IF;
  IF v_load.trucks_booked >= v_load.trucks_needed THEN RAISE EXCEPTION 'Load fully booked'; END IF;

  SELECT * INTO v_truck FROM trucks WHERE id = p_truck_id AND owner_id = v_trucker_id;
  IF v_truck IS NULL THEN RAISE EXCEPTION 'Truck not found'; END IF;
  IF v_truck.status != 'verified' THEN RAISE EXCEPTION 'Truck not verified'; END IF;

  IF EXISTS (SELECT 1 FROM booking_requests WHERE load_id = p_load_id AND trucker_id = v_trucker_id AND status = 'submitted') THEN
    RAISE EXCEPTION 'Already booked this load';
  END IF;

  INSERT INTO booking_requests (load_id, trucker_id, truck_id, status)
  VALUES (p_load_id, v_trucker_id, p_truck_id, 'submitted')
  RETURNING id INTO v_booking_id;

  SELECT COALESCE(NULLIF(full_name, ''), 'A trucker')
  INTO v_trucker_name
  FROM profiles
  WHERE id = v_trucker_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'booking_update',
    'medium',
    'New Booking Request',
    COALESCE(v_trucker_name, 'A trucker') || ' wants to book your ' || COALESCE(v_load.material, 'active') || ' load',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );

  RETURN v_booking_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_booking_request(p_load_id uuid, p_truck_id uuid, p_booking_gps_lat double precision DEFAULT NULL::double precision, p_booking_gps_lng double precision DEFAULT NULL::double precision)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_booking_id UUID;
  v_trucker_id UUID;
  v_load RECORD;
  v_truck RECORD;
  v_trucker_name TEXT;
BEGIN
  v_trucker_id := auth.uid();

  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_trucker_id AND verification_status = 'verified') THEN
    RAISE EXCEPTION 'Trucker not verified';
  END IF;

  SELECT * INTO v_load FROM loads WHERE id = p_load_id AND parent_load_id IS NULL FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available for booking'; END IF;
  IF v_load.trucks_booked >= v_load.trucks_needed THEN RAISE EXCEPTION 'Load fully booked'; END IF;

  SELECT * INTO v_truck FROM trucks WHERE id = p_truck_id AND owner_id = v_trucker_id;
  IF v_truck IS NULL THEN RAISE EXCEPTION 'Truck not found'; END IF;
  IF v_truck.status != 'verified' THEN RAISE EXCEPTION 'Truck not verified'; END IF;

  IF EXISTS (SELECT 1 FROM booking_requests WHERE load_id = p_load_id AND trucker_id = v_trucker_id AND status = 'submitted') THEN
    RAISE EXCEPTION 'Already booked this load';
  END IF;

  IF (p_booking_gps_lat IS NULL) <> (p_booking_gps_lng IS NULL) THEN
    RAISE EXCEPTION 'Booking GPS latitude/longitude must be provided together';
  END IF;

  INSERT INTO booking_requests (
    load_id,
    trucker_id,
    truck_id,
    status,
    booking_gps_lat,
    booking_gps_lng
  )
  VALUES (
    p_load_id,
    v_trucker_id,
    p_truck_id,
    'submitted',
    p_booking_gps_lat,
    p_booking_gps_lng
  )
  RETURNING id INTO v_booking_id;

  SELECT COALESCE(NULLIF(full_name, ''), 'A trucker')
  INTO v_trucker_name
  FROM profiles
  WHERE id = v_trucker_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'booking_update',
    'medium',
    'New Booking Request',
    COALESCE(v_trucker_name, 'A trucker') || ' wants to book your ' || COALESCE(v_load.material, 'active') || ' load',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );

  RETURN v_booking_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_profile_photo_for_review()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_profile RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_subject_type TEXT;
BEGIN
  SELECT * INTO v_profile
  FROM profiles
  WHERE id = auth.uid()
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF COALESCE(BTRIM(v_profile.profile_photo_document_path), '') = '' THEN
    RAISE EXCEPTION 'Upload a profile photo before submitting for review';
  END IF;

  IF v_profile.user_role_type = 'supplier' THEN
    v_subject_type := 'supplier_profile';
  ELSIF v_profile.user_role_type = 'trucker' THEN
    v_subject_type := 'trucker_profile';
  ELSE
    RAISE EXCEPTION 'User role is not configured for profile photo review';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = v_subject_type
    AND subject_id = auth.uid()
    AND review_type = 'profile_photo_update'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'approved') THEN
    RAISE EXCEPTION 'Profile photo review is already active';
  END IF;

  IF v_case IS NOT NULL AND v_case.case_status = 'rejected' THEN
    UPDATE verification_cases
    SET case_status = 'submitted',
        assigned_admin_user_id = NULL,
        last_reviewed_at = NULL,
        current_decision_summary = NULL,
        current_review_feedback_json = NULL,
        escalated_to_admin_user_id = NULL,
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.id;

    v_case_id := v_case.id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    ) VALUES (
      v_case_id,
      'resubmitted',
      'Profile photo review resubmitted'
    );
  ELSE
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      review_type,
      case_status
    ) VALUES (
      v_subject_type,
      auth.uid(),
      'profile_photo_update',
      'submitted'
    ) RETURNING id INTO v_case_id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    ) VALUES (
      v_case_id,
      'submitted',
      'Profile photo review submitted'
    );
  END IF;

  UPDATE profiles
  SET profile_photo_review_status = 'submitted',
      profile_photo_rejection_reason = NULL,
      profile_photo_feedback_json = NULL,
      profile_photo_submitted_at = NOW(),
      profile_photo_last_reviewed_at = NULL,
      updated_at = NOW()
  WHERE id = auth.uid();

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    NULL,
    'user',
    NULL,
    'override_action',
    'profile',
    auth.uid(),
    'verification_case',
    v_case_id,
    'User submitted profile photo for review',
    jsonb_build_object(
      'subject_type', v_subject_type,
      'review_type', 'profile_photo_update'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'verification_update',
    'medium',
    'Profile Photo Update',
    v_profile.full_name || ' submitted a profile photo update',
    v_case_id,
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_case_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_rating(p_load_id uuid, p_score integer, p_comment text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_rating_id UUID;
  v_trip RECORD;
  v_reviewer_role user_role;
  v_reviewee_id UUID;
BEGIN
  -- Find completed trip for this load where caller is a participant
  SELECT t.* INTO v_trip FROM trips t
  WHERE t.load_id = p_load_id AND t.stage = 'completed'
    AND (t.trucker_id = auth.uid() OR t.supplier_id = auth.uid())
  LIMIT 1;

  IF v_trip IS NULL THEN RAISE EXCEPTION 'No completed trip found for rating'; END IF;

  -- Determine roles
  IF v_trip.trucker_id = auth.uid() THEN
    v_reviewer_role := 'trucker';
    v_reviewee_id := v_trip.supplier_id;
  ELSE
    v_reviewer_role := 'supplier';
    v_reviewee_id := v_trip.trucker_id;
  END IF;

  INSERT INTO ratings (load_id, trip_id, reviewer_id, reviewee_id, reviewer_role, score, comment)
  VALUES (p_load_id, v_trip.id, auth.uid(), v_reviewee_id, v_reviewer_role, p_score, p_comment)
  RETURNING id INTO v_rating_id;

  RETURN v_rating_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_review(p_reviewed_user_id uuid, p_context_type text, p_context_id uuid, p_rating integer, p_comment text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_reviewer_id uuid;
    v_reviewer_role text;
    v_review_id uuid;
    v_existing_review_id uuid;
BEGIN
    -- Get current user info
    v_reviewer_id := auth.uid();
    if v_reviewer_id is null then
        return jsonb_build_object('success', false, 'error', 'Authentication required');
    end if;
    
    -- Cannot review yourself
    if v_reviewer_id = p_reviewed_user_id then
        return jsonb_build_object('success', false, 'error', 'Cannot review yourself');
    end if;
    
    -- Validate rating 1-5
    if p_rating is null or p_rating < 1 or p_rating > 5 then
        return jsonb_build_object('success', false, 'error', 'Rating must be between 1 and 5');
    end if;
    
    -- Validate context_type
    if p_context_type not in ('chat', 'load_closed', 'trip_completed') then
        return jsonb_build_object('success', false, 'error', 'Invalid context type');
    end if;
    
    -- Get reviewer role from profiles (FIXED: use user_role_type instead of role)
    select user_role_type into v_reviewer_role from profiles where id = v_reviewer_id;
    if v_reviewer_role is null then
        return jsonb_build_object('success', false, 'error', 'Reviewer profile not found');
    end if;
    
    -- Check if review already exists (one review per reviewer per reviewed user)
    select id into v_existing_review_id from reviews 
    where reviewed_user_id = p_reviewed_user_id and reviewer_id = v_reviewer_id;
    
    if v_existing_review_id is not null then
        return jsonb_build_object('success', false, 'error', 'You have already reviewed this user');
    end if;
    
    -- Insert the review
    insert into reviews (
        reviewed_user_id,
        reviewer_id,
        reviewer_role,
        context_type,
        context_id,
        rating,
        comment
    ) values (
        p_reviewed_user_id,
        v_reviewer_id,
        v_reviewer_role,
        p_context_type,
        p_context_id,
        p_rating,
        p_comment
    )
    returning id into v_review_id;
    
    return jsonb_build_object('success', true, 'review_id', v_review_id);
    
exception when unique_violation then
    return jsonb_build_object('success', false, 'error', 'You have already reviewed this user');
when others then
    return jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_verification_for_review()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_profile RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_subject_type TEXT;
BEGIN
  SELECT * INTO v_profile
  FROM profiles
  WHERE id = auth.uid()
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_profile.user_role_type = 'supplier' THEN
    v_subject_type := 'supplier_profile';
  ELSIF v_profile.user_role_type = 'trucker' THEN
    v_subject_type := 'trucker_profile';
  ELSE
    RAISE EXCEPTION 'User role is not configured for verification';
  END IF;

  IF v_profile.verification_status = 'verified' THEN
    RAISE EXCEPTION 'Profile is already verified';
  END IF;

  IF v_profile.verification_status = 'pending' THEN
    RAISE EXCEPTION 'Verification is already under review';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = v_subject_type
    AND subject_id = auth.uid()
    AND review_type = 'full_verification'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'approved') THEN
    RAISE EXCEPTION 'Verification case is already active';
  END IF;

  IF v_case IS NOT NULL AND v_case.case_status = 'rejected' THEN
    UPDATE verification_cases
    SET case_status = 'submitted',
        assigned_admin_user_id = NULL,
        last_reviewed_at = NULL,
        current_decision_summary = NULL,
        current_review_feedback_json = NULL,
        escalated_to_admin_user_id = NULL,
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.id;

    v_case_id := v_case.id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    ) VALUES (
      v_case_id,
      'resubmitted',
      'Verification resubmitted'
    );
  ELSE
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      review_type,
      case_status
    ) VALUES (
      v_subject_type,
      auth.uid(),
      'full_verification',
      'submitted'
    ) RETURNING id INTO v_case_id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    ) VALUES (
      v_case_id,
      'submitted',
      'Verification submitted'
    );
  END IF;

  UPDATE profiles
  SET verification_status = 'pending',
      verification_rejection_reason = NULL,
      updated_at = NOW()
  WHERE id = auth.uid();

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    NULL,
    'user',
    NULL,
    'override_action',
    'profile',
    auth.uid(),
    'verification_case',
    v_case_id,
    'User submitted verification for review',
    jsonb_build_object(
      'subject_type', v_subject_type,
      'review_type', 'full_verification'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'verification_update',
    'medium',
    'New Verification',
    v_profile.full_name || ' submitted verification',
    v_case_id,
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_case_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_verification_packet(p_aadhaar_number text DEFAULT NULL::text, p_pan_number text DEFAULT NULL::text, p_aadhaar_front_document_path text DEFAULT NULL::text, p_aadhaar_back_document_path text DEFAULT NULL::text, p_pan_document_path text DEFAULT NULL::text, p_profile_photo_document_path text DEFAULT NULL::text, p_company_name text DEFAULT NULL::text, p_business_licence_number text DEFAULT NULL::text, p_gst_number text DEFAULT NULL::text, p_business_licence_document_path text DEFAULT NULL::text, p_gst_certificate_document_path text DEFAULT NULL::text, p_verification_location_city text DEFAULT NULL::text, p_verification_location_state text DEFAULT NULL::text, p_verification_location_lat numeric DEFAULT NULL::numeric, p_verification_location_lng numeric DEFAULT NULL::numeric, p_truck_number text DEFAULT NULL::text, p_truck_body_type text DEFAULT NULL::text, p_truck_tyres integer DEFAULT NULL::integer, p_truck_capacity_tonnes numeric DEFAULT NULL::numeric, p_truck_rc_document_path text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_profile RECORD;
  v_supplier RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_truck_id UUID;
  v_subject_type TEXT;
  v_ready_truck_exists BOOLEAN := FALSE;
BEGIN
  SELECT * INTO v_profile FROM profiles WHERE id = auth.uid() FOR UPDATE;
  IF v_profile IS NULL THEN RAISE EXCEPTION 'Profile not found'; END IF;

  IF v_profile.user_role_type = 'supplier' THEN v_subject_type := 'supplier_profile';
  ELSIF v_profile.user_role_type = 'trucker' THEN v_subject_type := 'trucker_profile';
  ELSE RAISE EXCEPTION 'User role is not configured for verification'; END IF;

  IF v_profile.verification_status = 'verified' THEN RAISE EXCEPTION 'Profile is already verified'; END IF;
  IF v_profile.verification_status = 'pending' THEN RAISE EXCEPTION 'Verification is already under review'; END IF;

  -- Update identity + docs on profiles
  UPDATE profiles SET
    aadhaar_number = COALESCE(p_aadhaar_number, aadhaar_number),
    aadhaar_last4 = CASE WHEN p_aadhaar_number IS NOT NULL AND LENGTH(p_aadhaar_number) >= 4 THEN RIGHT(p_aadhaar_number, 4) ELSE aadhaar_last4 END,
    pan_number = COALESCE(p_pan_number, pan_number),
    aadhaar_front_document_path = COALESCE(p_aadhaar_front_document_path, aadhaar_front_document_path),
    aadhaar_back_document_path = COALESCE(p_aadhaar_back_document_path, aadhaar_back_document_path),
    pan_document_path = COALESCE(p_pan_document_path, pan_document_path),
    profile_photo_document_path = COALESCE(p_profile_photo_document_path, profile_photo_document_path),
    updated_at = NOW()
  WHERE id = auth.uid();

  -- Supplier extension update
  IF v_profile.user_role_type = 'supplier' THEN
    UPDATE suppliers SET
      company_name = COALESCE(p_company_name, company_name),
      business_licence_number = COALESCE(p_business_licence_number, business_licence_number),
      gst_number = COALESCE(p_gst_number, gst_number),
      business_licence_document_path = COALESCE(p_business_licence_document_path, business_licence_document_path),
      gst_certificate_document_path = COALESCE(p_gst_certificate_document_path, gst_certificate_document_path),
      verification_location_city = COALESCE(p_verification_location_city, verification_location_city),
      verification_location_state = COALESCE(p_verification_location_state, verification_location_state),
      verification_location_lat = COALESCE(p_verification_location_lat, verification_location_lat),
      verification_location_lng = COALESCE(p_verification_location_lng, verification_location_lng),
      updated_at = NOW()
    WHERE id = auth.uid();

    SELECT * INTO v_supplier FROM suppliers WHERE id = auth.uid();
    IF COALESCE(BTRIM(v_supplier.business_licence_number), '') = '' THEN RAISE EXCEPTION 'Business licence number is required'; END IF;
    IF COALESCE(BTRIM(v_supplier.business_licence_document_path), '') = '' THEN RAISE EXCEPTION 'Business licence document is required'; END IF;
    IF COALESCE(BTRIM(v_supplier.verification_location_city), '') = '' OR v_supplier.verification_location_lat IS NULL OR v_supplier.verification_location_lng IS NULL THEN
      RAISE EXCEPTION 'Supplier verification location is required';
    END IF;
  END IF;

  -- Trucker: create truck if draft provided
  IF v_profile.user_role_type = 'trucker' AND COALESCE(BTRIM(p_truck_number), '') != '' AND COALESCE(BTRIM(p_truck_body_type), '') != ''
     AND COALESCE(p_truck_tyres, 0) > 0 AND COALESCE(p_truck_capacity_tonnes, 0) > 0 THEN
    INSERT INTO trucks (owner_id, truck_number, body_type, tyres, capacity_tonnes, rc_document_path, status)
    VALUES (auth.uid(), p_truck_number, p_truck_body_type, p_truck_tyres, p_truck_capacity_tonnes, p_truck_rc_document_path, 'pending')
    RETURNING id INTO v_truck_id;
  END IF;

  -- Validate required docs from (now-updated) profile
  SELECT * INTO v_profile FROM profiles WHERE id = auth.uid();
  IF COALESCE(BTRIM(v_profile.aadhaar_number), '') = '' THEN RAISE EXCEPTION 'Aadhaar number is required'; END IF;
  IF COALESCE(BTRIM(v_profile.pan_number), '') = '' THEN RAISE EXCEPTION 'PAN number is required'; END IF;
  IF COALESCE(BTRIM(v_profile.aadhaar_front_document_path), '') = '' THEN RAISE EXCEPTION 'Aadhaar front document is required'; END IF;
  IF COALESCE(BTRIM(v_profile.aadhaar_back_document_path), '') = '' THEN RAISE EXCEPTION 'Aadhaar back document is required'; END IF;
  IF COALESCE(BTRIM(v_profile.pan_document_path), '') = '' THEN RAISE EXCEPTION 'PAN document is required'; END IF;

  -- Trucker: verify at least one complete truck exists
  IF v_profile.user_role_type = 'trucker' THEN
    SELECT EXISTS (SELECT 1 FROM trucks WHERE owner_id = auth.uid() AND status != 'archived'
      AND COALESCE(BTRIM(truck_number), '') != '' AND COALESCE(BTRIM(body_type), '') != ''
      AND COALESCE(tyres, 0) > 0 AND COALESCE(capacity_tonnes, 0) > 0 AND COALESCE(BTRIM(rc_document_path), '') != '')
    INTO v_ready_truck_exists;
    IF NOT v_ready_truck_exists THEN RAISE EXCEPTION 'At least one complete truck with RC document is required'; END IF;
  END IF;

  -- Case management (same logic as submit_verification_for_review)
  SELECT * INTO v_case FROM verification_cases WHERE subject_type = v_subject_type AND subject_id = auth.uid()
  ORDER BY created_at DESC LIMIT 1 FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted','queued','in_review','waiting_for_resubmission','approved') THEN
    RAISE EXCEPTION 'Verification case is already active';
  END IF;

  IF v_case IS NOT NULL AND v_case.case_status = 'rejected' THEN
    UPDATE verification_cases SET case_status = 'submitted', assigned_admin_user_id = NULL,
      last_reviewed_at = NULL, current_decision_summary = NULL, current_review_feedback_json = NULL,
      escalated_to_admin_user_id = NULL, submitted_at = NOW(), updated_at = NOW() WHERE id = v_case.id;
    v_case_id := v_case.id;
    INSERT INTO verification_case_events (verification_case_id, event_type, event_summary)
    VALUES (v_case_id, 'resubmitted', 'Verification resubmitted');
  ELSE
    INSERT INTO verification_cases (subject_type, subject_id, case_status)
    VALUES (v_subject_type, auth.uid(), 'submitted') RETURNING id INTO v_case_id;
    INSERT INTO verification_case_events (verification_case_id, event_type, event_summary)
    VALUES (v_case_id, 'submitted', 'Verification submitted');
  END IF;

  UPDATE profiles SET verification_status = 'pending', verification_rejection_reason = NULL,
    verification_feedback_json = NULL, updated_at = NOW() WHERE id = auth.uid();

  RETURN v_case_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_supplier_location_to_profile()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  -- When supplier verification location is updated, sync to profiles
  if new.verification_location_city is not null then
    update profiles
    set 
      city = new.verification_location_city,
      state = new.verification_location_state
    where id = new.id;
  end if;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_truck_verification_case_from_truck()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_case verification_cases%ROWTYPE;
  v_event_type verification_event_type;
  v_event_summary TEXT;
  v_notification_title TEXT;
  v_notification_body TEXT;
  v_owner_name TEXT;
BEGIN
  IF NEW.status NOT IN ('pending', 'edited_pending_reapproval') OR
     COALESCE(BTRIM(NEW.truck_number), '') = '' OR
     COALESCE(BTRIM(NEW.body_type), '') = '' OR
     COALESCE(NEW.tyres, 0) <= 0 OR
     COALESCE(NEW.capacity_tonnes, 0) <= 0 OR
     COALESCE(BTRIM(NEW.rc_document_path), '') = '' THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = 'truck'
    AND subject_id = NEW.id
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated') THEN
    RETURN NEW;
  END IF;

  IF v_case IS NULL THEN
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      case_status
    ) VALUES (
      'truck',
      NEW.id,
      'submitted'
    ) RETURNING * INTO v_case;

    v_event_type := 'submitted';
    v_event_summary := 'Truck verification submitted';
    v_notification_title := 'New Truck Verification';
  ELSE
    UPDATE verification_cases
    SET case_status = 'submitted',
        assigned_admin_user_id = NULL,
        last_reviewed_at = NULL,
        current_decision_summary = NULL,
        current_review_feedback_json = NULL,
        escalated_to_admin_user_id = NULL,
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.id
    RETURNING * INTO v_case;

    v_event_type := 'resubmitted';
    v_event_summary := 'Truck verification resubmitted';
    v_notification_title := 'Truck Verification Resubmitted';
  END IF;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    event_summary
  ) VALUES (
    v_case.id,
    v_event_type,
    v_event_summary
  );

  SELECT full_name INTO v_owner_name
  FROM profiles
  WHERE id = NEW.owner_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    NULL,
    'user',
    NULL,
    'override_action',
    'truck',
    NEW.id,
    'verification_case',
    v_case.id,
    CASE
      WHEN v_event_type = 'submitted' THEN 'User submitted truck for verification'
      ELSE 'User resubmitted truck for verification'
    END,
    jsonb_build_object(
      'truck_number', NEW.truck_number,
      'status', NEW.status
    ),
    'internal'
  );

  v_notification_body := COALESCE(NULLIF(BTRIM(v_owner_name), ''), 'A trucker') ||
    CASE
      WHEN v_event_type = 'submitted' THEN ' submitted truck '
      ELSE ' resubmitted truck '
    END || COALESCE(NULLIF(BTRIM(NEW.truck_number), ''), 'for verification');

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'verification_update',
    'medium',
    v_notification_title,
    v_notification_body,
    v_case.id,
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.transition_operational_case(p_case_id uuid, p_next_status public.operational_case_status, p_event_summary text DEFAULT NULL::text, p_internal_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_ticket RECORD;
  v_summary TEXT;
  v_note TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_summary := NULLIF(btrim(COALESCE(p_event_summary, '')), '');
  v_note := NULLIF(btrim(COALESCE(p_internal_note, '')), '');

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF NOT (
    (v_case.status = 'claimed' AND p_next_status = 'in_review') OR
    (v_case.status = 'in_review' AND p_next_status IN ('waiting_for_user', 'waiting_for_external')) OR
    (v_case.status = 'waiting_for_user' AND p_next_status = 'in_review') OR
    (v_case.status = 'waiting_for_external' AND p_next_status = 'in_review') OR
    (v_case.status = 'escalated' AND p_next_status = 'in_review') OR
    (v_case.status = 'resolved' AND p_next_status = 'closed') OR
    (v_case.status = 'rejected' AND p_next_status = 'closed')
  ) THEN
    RAISE EXCEPTION 'Unsupported operational case transition';
  END IF;

  IF v_case.status IN ('claimed', 'in_review')
     AND v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id
     AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only the claimed admin or a super admin can transition this case';
  END IF;

  IF v_case.status = 'escalated' AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only a super admin can take over an escalated case';
  END IF;

  UPDATE operational_cases
  SET status = p_next_status,
      claimed_by_admin_user_id = CASE
        WHEN v_case.status = 'escalated' AND p_next_status = 'in_review' THEN v_admin_user_id
        ELSE claimed_by_admin_user_id
      END,
      claimed_at = CASE
        WHEN v_case.status = 'escalated' AND p_next_status = 'in_review' THEN NOW()
        ELSE claimed_at
      END,
      waiting_reason = CASE
        WHEN p_next_status = 'waiting_for_user' THEN COALESCE(v_note, v_summary)
        WHEN p_next_status = 'waiting_for_external' THEN COALESCE(v_note, v_summary)
        ELSE NULL
      END,
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_transition',
    COALESCE(v_summary, 'Operational case moved to ' || p_next_status::text),
    v_note
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'operational_case',
    p_case_id,
    COALESCE(v_summary, 'Operational case moved to ' || p_next_status::text),
    jsonb_build_object(
      'from_status', v_case.status,
      'to_status', p_next_status,
      'internal_note', v_note
    ),
    'internal'
  );

  IF p_next_status = 'waiting_for_user'
     AND v_case.case_type = 'trip_dispute'
     AND v_case.primary_object_type = 'trip' THEN
    SELECT * INTO v_ticket
    FROM support_tickets
    WHERE related_trip_id = v_case.primary_object_id
      AND category = 'trip_dispute'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_ticket IS NOT NULL THEN
      UPDATE support_tickets
      SET status = 'waiting_for_user',
          updated_at = NOW()
      WHERE id = v_ticket.id;

      INSERT INTO notifications (
        target_profile_id,
        notification_type,
        notification_priority,
        title_text,
        body_text,
        related_load_id,
        related_trip_id,
        related_case_id,
        action_route_hint
      ) VALUES (
        v_ticket.owner_profile_id,
        'dispute_update',
        'high',
        'Evidence Needed',
        'Please provide additional proof for your dispute',
        v_ticket.related_load_id,
        v_ticket.related_trip_id,
        v_ticket.id,
        '/support-ticket/' || v_ticket.id::text
      );
    END IF;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_notification_preferences(p_user_id uuid, p_load_booking_enabled boolean DEFAULT NULL::boolean, p_load_status_updates_enabled boolean DEFAULT NULL::boolean, p_trip_updates_enabled boolean DEFAULT NULL::boolean, p_chat_messages_enabled boolean DEFAULT NULL::boolean, p_review_notifications_enabled boolean DEFAULT NULL::boolean, p_support_responses_enabled boolean DEFAULT NULL::boolean, p_system_notifications_enabled boolean DEFAULT NULL::boolean, p_push_enabled boolean DEFAULT NULL::boolean, p_in_app_enabled boolean DEFAULT NULL::boolean, p_email_enabled boolean DEFAULT NULL::boolean, p_quiet_hours_enabled boolean DEFAULT NULL::boolean, p_quiet_hours_start time without time zone DEFAULT NULL::time without time zone, p_quiet_hours_end time without time zone DEFAULT NULL::time without time zone, p_quiet_hours_timezone text DEFAULT NULL::text, p_auto_dismiss_enabled boolean DEFAULT NULL::boolean, p_auto_dismiss_after_hours integer DEFAULT NULL::integer, p_delivery_tracking_enabled boolean DEFAULT NULL::boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_preferences JSONB;
BEGIN
  -- Upsert preferences
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
    p_user_id,
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
    updated_at = NOW()
  RETURNING jsonb_build_object(
    'user_id', user_id,
    'load_booking_enabled', load_booking_enabled,
    'load_status_updates_enabled', load_status_updates_enabled,
    'trip_updates_enabled', trip_updates_enabled,
    'chat_messages_enabled', chat_messages_enabled,
    'review_notifications_enabled', review_notifications_enabled,
    'support_responses_enabled', support_responses_enabled,
    'system_notifications_enabled', system_notifications_enabled,
    'push_enabled', push_enabled,
    'in_app_enabled', in_app_enabled,
    'email_enabled', email_enabled,
    'quiet_hours_enabled', quiet_hours_enabled,
    'quiet_hours_start', quiet_hours_start,
    'quiet_hours_end', quiet_hours_end,
    'quiet_hours_timezone', quiet_hours_timezone,
    'auto_dismiss_enabled', auto_dismiss_enabled,
    'auto_dismiss_after_hours', auto_dismiss_after_hours,
    'delivery_tracking_enabled', delivery_tracking_enabled,
    'created_at', created_at,
    'updated_at', updated_at
  ) INTO v_preferences;

  RETURN v_preferences;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_notification_preferences_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_profile_trust_score()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare
    v_avg_rating numeric(2,1);
    v_review_count int;
    v_reviewed_role text;
begin
    -- Calculate aggregates for the reviewed user
    select 
        avg(rating)::numeric(2,1),
        count(*)
    into v_avg_rating, v_review_count
    from reviews
    where reviewed_user_id = new.reviewed_user_id;
    
    -- Update profile_trust_scores
    insert into profile_trust_scores (user_id, avg_rating, review_count)
    values (new.reviewed_user_id, coalesce(v_avg_rating, 0), coalesce(v_review_count, 0))
    on conflict (user_id) do update set
        avg_rating = excluded.avg_rating,
        review_count = excluded.review_count,
        updated_at = now();
    
    -- ALSO update truckers.rating for backward compatibility
    -- Check if reviewed user is a trucker
    select role into v_reviewed_role from profiles where id = new.reviewed_user_id;
    if v_reviewed_role = 'trucker' then
        update truckers 
        set rating = coalesce(v_avg_rating, 0)
        where id = new.reviewed_user_id;
    end if;
    
    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.update_profile_trust_scores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Insert or update profile_trust_scores for the reviewed user
  INSERT INTO profile_trust_scores (user_id, avg_rating, review_count, updated_at)
  VALUES (
    NEW.reviewee_id,
    (SELECT COALESCE(AVG(r.score), 0) FROM ratings r WHERE r.reviewee_id = NEW.reviewee_id),
    (SELECT COUNT(*) FROM ratings r WHERE r.reviewee_id = NEW.reviewee_id),
    NOW()
  )
  ON CONFLICT (user_id) 
  DO UPDATE SET
    avg_rating = EXCLUDED.avg_rating,
    review_count = EXCLUDED.review_count,
    updated_at = NOW();
  
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_ticket_attachments_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_truck_verification_state(p_truck_id uuid, p_next_status public.truck_status, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_truck RECORD;
  v_case RECORD;
  v_reason TEXT;
  v_event_type verification_event_type;
  v_notification_title TEXT;
  v_notification_body TEXT;
  v_priority notification_priority;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF p_next_status NOT IN ('verified', 'rejected') THEN
    RAISE EXCEPTION 'Truck verification updates only support verified or rejected';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');
  IF p_next_status = 'rejected' AND v_reason IS NULL THEN
    RAISE EXCEPTION 'Rejection reason is required';
  END IF;

  SELECT * INTO v_truck
  FROM trucks
  WHERE id = p_truck_id
  FOR UPDATE;

  IF v_truck IS NULL THEN
    RAISE EXCEPTION 'Truck not found';
  END IF;

  IF v_truck.status NOT IN ('pending', 'edited_pending_reapproval', 'rejected') THEN
    RAISE EXCEPTION 'Truck is not awaiting verification review';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = 'truck'
    AND subject_id = p_truck_id
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NULL THEN
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      case_status,
      assigned_admin_user_id,
      submitted_at,
      last_reviewed_at,
      current_decision_summary,
      current_review_feedback_json
    ) VALUES (
      'truck',
      p_truck_id,
      CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END,
      v_admin_user_id,
      NOW(),
      NOW(),
      CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
      CASE WHEN p_next_status = 'rejected'
        THEN jsonb_build_object(
          'summary', v_reason,
          'next_step', 'Update the rejected truck details or documents and resubmit for review.'
        )
        ELSE NULL
      END
    ) RETURNING * INTO v_case;
  ELSE
    UPDATE verification_cases
    SET case_status = CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END,
        assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
        last_reviewed_at = NOW(),
        current_decision_summary = CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
        current_review_feedback_json = CASE WHEN p_next_status = 'rejected'
          THEN jsonb_build_object(
            'summary', v_reason,
            'next_step', 'Update the rejected truck details or documents and resubmit for review.'
          )
          ELSE NULL
        END,
        updated_at = NOW()
    WHERE id = v_case.id
    RETURNING * INTO v_case;
  END IF;

  UPDATE trucks
  SET status = p_next_status,
      rejection_reason = CASE WHEN p_next_status = 'rejected' THEN v_reason ELSE NULL END,
      verification_feedback_json = CASE WHEN p_next_status = 'rejected'
        THEN jsonb_build_object(
          'summary', v_reason,
          'next_step', 'Update the rejected truck details or documents and resubmit for review.'
        )
        ELSE NULL
      END,
      verified_at = CASE WHEN p_next_status = 'verified' THEN NOW() ELSE NULL END,
      verified_by_admin_user_id = CASE WHEN p_next_status = 'verified' THEN v_admin_user_id ELSE NULL END,
      updated_at = NOW()
  WHERE id = p_truck_id;

  v_event_type := CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END;
  v_notification_title := CASE WHEN p_next_status = 'verified' THEN 'Truck Approved' ELSE 'Truck Verification Update' END;
  v_notification_body := CASE
    WHEN p_next_status = 'verified' THEN 'Your truck is verified and ready for booking workflows.'
    ELSE 'Please review the truck verification feedback and resubmit the affected details.'
  END;
  v_priority := CASE WHEN p_next_status = 'verified' THEN 'medium' ELSE 'high' END;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary,
    internal_note
  ) VALUES (
    v_case.id,
    v_event_type,
    v_admin_user_id,
    CASE WHEN p_next_status = 'verified' THEN 'Truck verification approved' ELSE 'Truck verification rejected' END,
    v_reason
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    CASE WHEN p_next_status = 'verified' THEN 'truck_verification_approved' ELSE 'truck_verification_rejected' END,
    'verification_case',
    v_case.id,
    'truck',
    p_truck_id,
    CASE WHEN p_next_status = 'verified' THEN 'Truck verification approved' ELSE 'Truck verification rejected' END,
    jsonb_build_object(
      'next_status', p_next_status,
      'reason', v_reason
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_truck.owner_id,
    'verification_update',
    v_priority,
    v_notification_title,
    v_notification_body,
    v_case.id,
    '/trucker-verification'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_truck_verification_state(p_truck_id uuid, p_next_status public.truck_status, p_reason text DEFAULT NULL::text, p_feedback_json jsonb DEFAULT NULL::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_truck RECORD;
  v_case RECORD;
  v_reason TEXT;
  v_event_type verification_event_type;
  v_notification_title TEXT;
  v_notification_body TEXT;
  v_priority notification_priority;
  v_feedback JSONB;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF p_next_status NOT IN ('verified', 'rejected') THEN
    RAISE EXCEPTION 'Truck verification updates only support verified or rejected';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');
  IF p_next_status = 'rejected' AND v_reason IS NULL THEN
    RAISE EXCEPTION 'Rejection reason is required';
  END IF;

  IF p_next_status = 'rejected' THEN
    v_feedback := COALESCE(
      p_feedback_json,
      jsonb_build_object(
        'summary', v_reason,
        'next_step', 'Update the rejected truck details or documents and resubmit for review.'
      )
    );
    v_feedback := jsonb_set(
      v_feedback,
      '{summary}',
      to_jsonb(COALESCE(NULLIF(btrim(COALESCE(v_feedback->>'summary', '')), ''), v_reason))
    );
    IF COALESCE(NULLIF(btrim(COALESCE(v_feedback->>'next_step', '')), ''), '') = '' THEN
      v_feedback := jsonb_set(
        v_feedback,
        '{next_step}',
        to_jsonb('Update the rejected truck details or documents and resubmit for review.'::TEXT)
      );
    END IF;
  ELSE
    v_feedback := NULL;
  END IF;

  SELECT * INTO v_truck
  FROM trucks
  WHERE id = p_truck_id
  FOR UPDATE;

  IF v_truck IS NULL THEN
    RAISE EXCEPTION 'Truck not found';
  END IF;

  IF v_truck.status NOT IN ('pending', 'edited_pending_reapproval', 'rejected') THEN
    RAISE EXCEPTION 'Truck is not awaiting verification review';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = 'truck'
    AND subject_id = p_truck_id
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NULL THEN
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      case_status,
      assigned_admin_user_id,
      submitted_at,
      last_reviewed_at,
      current_decision_summary,
      current_review_feedback_json
    ) VALUES (
      'truck',
      p_truck_id,
      CASE WHEN p_next_status = 'verified' THEN 'approved'::verification_case_status ELSE 'rejected'::verification_case_status END,
      v_admin_user_id,
      NOW(),
      NOW(),
      CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
      v_feedback
    ) RETURNING * INTO v_case;
  ELSE
    UPDATE verification_cases
    SET case_status = CASE WHEN p_next_status = 'verified' THEN 'approved'::verification_case_status ELSE 'rejected'::verification_case_status END,
        assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
        last_reviewed_at = NOW(),
        current_decision_summary = CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
        current_review_feedback_json = v_feedback,
        updated_at = NOW()
    WHERE id = v_case.id
    RETURNING * INTO v_case;
  END IF;

  UPDATE trucks
  SET status = p_next_status,
      rejection_reason = CASE WHEN p_next_status = 'rejected' THEN v_reason ELSE NULL END,
      verification_feedback_json = v_feedback,
      verified_at = CASE WHEN p_next_status = 'verified' THEN NOW() ELSE NULL END,
      verified_by_admin_user_id = CASE WHEN p_next_status = 'verified' THEN v_admin_user_id ELSE NULL END,
      updated_at = NOW()
  WHERE id = p_truck_id;

  v_event_type := CASE WHEN p_next_status = 'verified' THEN 'approved'::verification_event_type ELSE 'rejected'::verification_event_type END;
  v_notification_title := CASE WHEN p_next_status = 'verified' THEN 'Truck Approved' ELSE 'Truck Verification Update' END;
  v_notification_body := CASE
    WHEN p_next_status = 'verified' THEN 'Your truck is verified and ready for booking workflows.'
    ELSE 'Please review the truck verification feedback and resubmit the affected details.'
  END;
  v_priority := CASE WHEN p_next_status = 'verified' THEN 'medium'::notification_priority ELSE 'high'::notification_priority END;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary,
    internal_note
  ) VALUES (
    v_case.id,
    v_event_type,
    v_admin_user_id,
    CASE WHEN p_next_status = 'verified' THEN 'Truck verification approved' ELSE 'Truck verification rejected' END,
    v_reason
  );

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    CASE WHEN p_next_status = 'verified' THEN 'truck_verification_approved'::audit_action_type ELSE 'truck_verification_rejected'::audit_action_type END,
    'verification_case',
    v_case.id,
    'truck',
    p_truck_id,
    CASE WHEN p_next_status = 'verified' THEN 'Truck verification approved' ELSE 'Truck verification rejected' END,
    jsonb_build_object(
      'next_status', p_next_status,
      'reason', v_reason,
      'feedback', v_feedback
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_truck.owner_id,
    'verification_update',
    v_priority,
    v_notification_title,
    v_notification_body,
    v_case.id,
    '/trucker-verification'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_trucker_rating()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE truckers
  SET rating = (
    SELECT COALESCE(AVG(r.score), 0)
    FROM ratings r
    WHERE r.reviewee_id = NEW.reviewee_id
  )
  WHERE id = NEW.reviewee_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_trust_safety_status(p_profile_id uuid, p_next_status public.trust_safety_status, p_reason_summary text, p_internal_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_user_id UUID;
  v_profile RECORD;
  v_reason_summary TEXT;
  v_internal_note TEXT;
  v_action_label TEXT;
  v_audit_action audit_action_type;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason_summary := btrim(COALESCE(p_reason_summary, ''));
  IF char_length(v_reason_summary) < 3 THEN
    RAISE EXCEPTION 'Reason summary is too short';
  END IF;

  v_internal_note := NULLIF(btrim(COALESCE(p_internal_note, '')), '');

  SELECT * INTO v_profile
  FROM profiles
  WHERE id = p_profile_id
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF p_next_status = 'normal' THEN
    v_action_label := 'restored';
    v_audit_action := 'user_unbanned';
  ELSIF p_next_status = 'restricted' THEN
    v_action_label := 'restricted';
    v_audit_action := 'user_restricted';
  ELSIF p_next_status = 'suspended' THEN
    v_action_label := 'suspended';
    v_audit_action := 'user_suspended';
  ELSIF p_next_status = 'banned' THEN
    v_action_label := 'banned';
    v_audit_action := 'user_banned';
  ELSE
    v_action_label := 'warned';
    v_audit_action := 'override_action';
  END IF;

  UPDATE profiles
  SET trust_safety_status = p_next_status,
      is_banned = CASE WHEN p_next_status IN ('suspended', 'banned') THEN TRUE ELSE FALSE END,
      ban_reason = CASE
        WHEN p_next_status IN ('restricted', 'suspended', 'banned') THEN v_reason_summary
        ELSE NULL
      END,
      updated_at = NOW()
  WHERE id = p_profile_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    v_audit_action,
    'profile',
    p_profile_id,
    'Trust-safety status updated to ' || p_next_status::text,
    jsonb_build_object(
      'previous_status', v_profile.trust_safety_status,
      'next_status', p_next_status,
      'reason_summary', v_reason_summary,
      'internal_note', v_internal_note
    ),
    'internal'
  );

  IF p_next_status IN ('restricted', 'suspended', 'banned') THEN
    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      action_route_hint
    ) VALUES (
      p_profile_id,
      'account_update',
      'high',
      'Account Restriction',
      'Your account has been ' || v_action_label || ': ' || v_reason_summary,
      '/profile'
    );
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.upload_trip_proof(p_trip_id uuid, p_pod_path text, p_lr_path text DEFAULT NULL::text, p_gps_lat double precision DEFAULT NULL::double precision, p_gps_lng double precision DEFAULT NULL::double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_trip RECORD;
  v_material TEXT;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.trucker_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;
  IF v_trip.stage != 'delivered' THEN RAISE EXCEPTION 'Trip must be in delivered stage to upload proof'; END IF;

  UPDATE trips SET
    stage = 'proof_submitted',
    pod_document_path = p_pod_path,
    lr_document_path = COALESCE(p_lr_path, lr_document_path),
    pod_uploaded_at = NOW(),
    gps_pod_lat = p_gps_lat,
    gps_pod_lng = p_gps_lng
  WHERE id = p_trip_id;

  SELECT COALESCE(material, 'this trip')
  INTO v_material
  FROM loads
  WHERE id = v_trip.load_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    v_trip.supplier_id,
    'proof_update',
    'high',
    'POD Uploaded',
    'Review proof of delivery for ' || COALESCE(v_material, 'this trip'),
    v_trip.load_id,
    p_trip_id,
    '/trip-detail/' || p_trip_id::text
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.upsert_current_user_profile(p_user_role_type public.user_role DEFAULT NULL::public.user_role, p_full_name text DEFAULT NULL::text, p_mobile text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_state text DEFAULT NULL::text, p_location_lat double precision DEFAULT NULL::double precision, p_location_lng double precision DEFAULT NULL::double precision, p_location_source text DEFAULT NULL::text, p_record_terms boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID := auth.uid();
  v_existing_profile profiles%ROWTYPE;
  v_email TEXT;
  v_full_name TEXT;
  v_mobile TEXT;
  v_city TEXT;
  v_state TEXT;
  v_location_source TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_existing_profile
  FROM public.profiles
  WHERE id = v_user_id;

  v_email := COALESCE(
    NULLIF(BTRIM(COALESCE(v_existing_profile.email, '')), ''),
    NULLIF(BTRIM(COALESCE(auth.jwt() ->> 'email', '')), '')
  );

  v_full_name := COALESCE(
    NULLIF(BTRIM(COALESCE(p_full_name, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.full_name, '')), ''),
    NULLIF(BTRIM(SPLIT_PART(COALESCE(v_email, ''), '@', 1)), ''),
    'User'
  );

  v_mobile := COALESCE(
    NULLIF(BTRIM(COALESCE(p_mobile, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.mobile, '')), '')
  );

  v_city := COALESCE(
    NULLIF(BTRIM(COALESCE(p_city, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.city, '')), '')
  );

  v_state := COALESCE(
    NULLIF(BTRIM(COALESCE(p_state, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.state, '')), '')
  );

  v_location_source := COALESCE(
    NULLIF(BTRIM(COALESCE(p_location_source, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.location_source, '')), '')
  );

  IF v_mobile IS NOT NULL AND v_mobile <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE mobile = v_mobile AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This mobile number is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  IF v_email IS NOT NULL AND v_email <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE email = v_email AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This email address is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  INSERT INTO public.profiles (
    id,
    full_name,
    mobile,
    email,
    user_role_type,
    city,
    state,
    location_lat,
    location_lng,
    location_source
  )
  VALUES (
    v_user_id,
    v_full_name,
    v_mobile,
    v_email,
    p_user_role_type,
    v_city,
    v_state,
    COALESCE(p_location_lat, v_existing_profile.location_lat),
    COALESCE(p_location_lng, v_existing_profile.location_lng),
    v_location_source
  )
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      mobile = COALESCE(EXCLUDED.mobile, public.profiles.mobile),
      email = COALESCE(EXCLUDED.email, public.profiles.email),
      user_role_type = COALESCE(EXCLUDED.user_role_type, public.profiles.user_role_type),
      city = COALESCE(EXCLUDED.city, public.profiles.city),
      state = COALESCE(EXCLUDED.state, public.profiles.state),
      location_lat = COALESCE(EXCLUDED.location_lat, public.profiles.location_lat),
      location_lng = COALESCE(EXCLUDED.location_lng, public.profiles.location_lng),
      location_source = COALESCE(EXCLUDED.location_source, public.profiles.location_source),
      updated_at = NOW();

  IF COALESCE(p_user_role_type, v_existing_profile.user_role_type) = 'supplier' THEN
    INSERT INTO public.suppliers (id)
    VALUES (v_user_id)
    ON CONFLICT (id) DO NOTHING;
  ELSIF COALESCE(p_user_role_type, v_existing_profile.user_role_type) = 'trucker' THEN
    INSERT INTO public.truckers (id)
    VALUES (v_user_id)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- Atomic terms acceptance: record only when explicitly requested
  IF p_record_terms THEN
    INSERT INTO public.user_consents (profile_id, consent_type, consent_version, source_context)
    VALUES (v_user_id, 'terms_of_service', 'v1', 'onboarding_profile')
    ON CONFLICT (profile_id, consent_type) DO NOTHING;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.verify_admin_access(p_auth_user_id uuid)
 RETURNS TABLE(role text, is_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    au.role::TEXT,
    au.is_active
  FROM admin_users au
  WHERE au.auth_user_id = p_auth_user_id
  LIMIT 1;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.verify_admin_after_auth(p_auth_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'found', true,
    'role', role,
    'is_active', is_active,
    'email', email
  ) INTO v_result
  FROM admin_users
  WHERE auth_user_id = p_auth_user_id
    AND is_active = true;
  
  IF v_result IS NULL THEN
    RETURN jsonb_build_object('found', false);
  END IF;
  
  RETURN v_result;
END;
$function$
;

grant delete on table "public"."feature_flags" to "anon";

grant insert on table "public"."feature_flags" to "anon";

grant references on table "public"."feature_flags" to "anon";

grant select on table "public"."feature_flags" to "anon";

grant trigger on table "public"."feature_flags" to "anon";

grant truncate on table "public"."feature_flags" to "anon";

grant update on table "public"."feature_flags" to "anon";

grant delete on table "public"."feature_flags" to "authenticated";

grant insert on table "public"."feature_flags" to "authenticated";

grant references on table "public"."feature_flags" to "authenticated";

grant select on table "public"."feature_flags" to "authenticated";

grant trigger on table "public"."feature_flags" to "authenticated";

grant truncate on table "public"."feature_flags" to "authenticated";

grant update on table "public"."feature_flags" to "authenticated";

grant delete on table "public"."feature_flags" to "service_role";

grant insert on table "public"."feature_flags" to "service_role";

grant references on table "public"."feature_flags" to "service_role";

grant select on table "public"."feature_flags" to "service_role";

grant trigger on table "public"."feature_flags" to "service_role";

grant truncate on table "public"."feature_flags" to "service_role";

grant update on table "public"."feature_flags" to "service_role";

grant delete on table "public"."notification_digests" to "anon";

grant insert on table "public"."notification_digests" to "anon";

grant references on table "public"."notification_digests" to "anon";

grant select on table "public"."notification_digests" to "anon";

grant trigger on table "public"."notification_digests" to "anon";

grant truncate on table "public"."notification_digests" to "anon";

grant update on table "public"."notification_digests" to "anon";

grant delete on table "public"."notification_digests" to "authenticated";

grant insert on table "public"."notification_digests" to "authenticated";

grant references on table "public"."notification_digests" to "authenticated";

grant select on table "public"."notification_digests" to "authenticated";

grant trigger on table "public"."notification_digests" to "authenticated";

grant truncate on table "public"."notification_digests" to "authenticated";

grant update on table "public"."notification_digests" to "authenticated";

grant delete on table "public"."notification_digests" to "service_role";

grant insert on table "public"."notification_digests" to "service_role";

grant references on table "public"."notification_digests" to "service_role";

grant select on table "public"."notification_digests" to "service_role";

grant trigger on table "public"."notification_digests" to "service_role";

grant truncate on table "public"."notification_digests" to "service_role";

grant update on table "public"."notification_digests" to "service_role";

grant delete on table "public"."user_saved_searches" to "anon";

grant insert on table "public"."user_saved_searches" to "anon";

grant references on table "public"."user_saved_searches" to "anon";

grant select on table "public"."user_saved_searches" to "anon";

grant trigger on table "public"."user_saved_searches" to "anon";

grant truncate on table "public"."user_saved_searches" to "anon";

grant update on table "public"."user_saved_searches" to "anon";

grant delete on table "public"."user_saved_searches" to "authenticated";

grant insert on table "public"."user_saved_searches" to "authenticated";

grant references on table "public"."user_saved_searches" to "authenticated";

grant select on table "public"."user_saved_searches" to "authenticated";

grant trigger on table "public"."user_saved_searches" to "authenticated";

grant truncate on table "public"."user_saved_searches" to "authenticated";

grant update on table "public"."user_saved_searches" to "authenticated";

grant delete on table "public"."user_saved_searches" to "service_role";

grant insert on table "public"."user_saved_searches" to "service_role";

grant references on table "public"."user_saved_searches" to "service_role";

grant select on table "public"."user_saved_searches" to "service_role";

grant trigger on table "public"."user_saved_searches" to "service_role";

grant truncate on table "public"."user_saved_searches" to "service_role";

grant update on table "public"."user_saved_searches" to "service_role";


  create policy "Anyone can view feature flags"
  on "public"."feature_flags"
  as permissive
  for select
  to public
using (true);



  create policy "Users can view their own notification digests"
  on "public"."notification_digests"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can delete their own saved searches"
  on "public"."user_saved_searches"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "Users can insert their own saved searches"
  on "public"."user_saved_searches"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can view their own saved searches"
  on "public"."user_saved_searches"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));


drop policy "comm_media_read_v2" on "storage"."objects";

drop policy "comm_media_upload_v2" on "storage"."objects";

drop policy "support_attach_read_v2" on "storage"."objects";

drop policy "support_attach_upload_v2" on "storage"."objects";

drop policy "trip_proof_read_v2" on "storage"."objects";

drop policy "trip_proof_upload_v2" on "storage"."objects";


  create policy "Anyone can view profile photos"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'profile-photos'::text));



  create policy "Authenticated users can upload load documents"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'load-documents'::text));



  create policy "Authenticated users can upload truck photos"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'truck-photos'::text));



  create policy "Authenticated users can upload voice messages"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'voice-messages'::text));



  create policy "Authenticated users can view load documents"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'load-documents'::text));



  create policy "Authenticated users can view truck photos"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'truck-photos'::text));



  create policy "Authenticated users can view voice messages"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'voice-messages'::text));



  create policy "Users can upload their own profile photos"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'profile-photos'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "Users can upload their own truck photos"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'truck-photos'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "Users can upload their own verification docs"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'verification-docs'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "Users can view their own verification docs"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'verification-docs'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "comm_media_read"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'communication-media'::text) AND (auth.uid() IS NOT NULL)));



  create policy "comm_media_upload"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'communication-media'::text) AND (auth.uid() IS NOT NULL)));



  create policy "support_attach_admin"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'support-attachments'::text) AND public.is_admin()));



  create policy "support_attach_read"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'support-attachments'::text) AND (auth.uid() IS NOT NULL)));



  create policy "support_attach_upload"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'support-attachments'::text) AND (auth.uid() IS NOT NULL)));



  create policy "trip_proof_read"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'trip-proof-documents'::text) AND (auth.uid() IS NOT NULL)));



  create policy "trip_proof_upload"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'trip-proof-documents'::text) AND (auth.uid() IS NOT NULL)));



