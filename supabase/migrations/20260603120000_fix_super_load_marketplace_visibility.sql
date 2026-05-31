-- Super Load: do not expose marketplace badge until admin approves.
-- Root cause: request_super_load set is_super_load = TRUE on submit.

CREATE OR REPLACE FUNCTION public.load_is_public_super_load(
  p_is_super_load BOOLEAN,
  p_super_status public.super_load_status
)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(p_is_super_load, FALSE) = TRUE
    AND p_super_status IN ('approved_payment_pending', 'active');
$$;

COMMENT ON FUNCTION public.load_is_public_super_load(BOOLEAN, public.super_load_status) IS
  'True when truckers should see Super Load badge / filter on marketplace.';

-- Repair rows affected by the old request_super_load behaviour.
UPDATE public.loads
SET is_super_load = FALSE,
    updated_at = NOW()
WHERE super_status IN ('request_submitted', 'under_review', 'rejected', 'none')
  AND is_super_load = TRUE;

CREATE OR REPLACE FUNCTION public.request_super_load(p_load_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_load RECORD;
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
  SET is_super_load = FALSE,
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
$function$;

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
  WHERE public.load_is_on_marketplace(l)
    AND (p_origin_city IS NULL OR l.origin_city ILIKE '%' || p_origin_city || '%')
    AND (p_destination_city IS NULL OR l.destination_city ILIKE '%' || p_destination_city || '%')
    AND (p_material IS NULL OR l.material ILIKE '%' || p_material || '%')
    AND (p_body_type IS NULL OR l.required_body_type = p_body_type)
    AND (p_min_price IS NULL OR l.price_amount >= p_min_price)
    AND (p_max_price IS NULL OR l.price_amount <= p_max_price)
    AND (p_super_loads_only = FALSE OR public.load_is_public_super_load(l.is_super_load, l.super_status))
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
      public.load_is_public_super_load(l.is_super_load, l.super_status) AS is_super_load,
      l.super_status,
      l.created_at,
      l.parent_load_id,
      l.listing_duration,
      l.marketplace_visible_until,
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
    WHERE public.load_is_on_marketplace(l)
      AND (p_origin_city IS NULL OR l.origin_city ILIKE '%' || p_origin_city || '%')
      AND (p_destination_city IS NULL OR l.destination_city ILIKE '%' || p_destination_city || '%')
      AND (p_material IS NULL OR l.material ILIKE '%' || p_material || '%')
      AND (p_body_type IS NULL OR l.required_body_type = p_body_type)
      AND (p_min_price IS NULL OR l.price_amount >= p_min_price)
      AND (p_max_price IS NULL OR l.price_amount <= p_max_price)
      AND (p_super_loads_only = FALSE OR public.load_is_public_super_load(l.is_super_load, l.super_status))
      AND (p_required_tyres IS NULL OR p_required_tyres = '{}'
           OR l.required_tyres && p_required_tyres)
    ORDER BY sort_key DESC
    LIMIT p_page_size
    OFFSET v_offset
  ) t;

  RETURN jsonb_build_object(
    'loads',     COALESCE(v_results, '[]'::JSONB),
    'total',     v_total,
    'page',      p_page,
    'page_size', p_page_size,
    'has_more',  (v_total > v_offset + p_page_size)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_marketplace_feed(
  TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, INT[],
  TEXT, INT, INT
) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_trucker_load_detail(p_load_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = auth.uid()
      AND user_role_type = 'trucker'
  ) THEN
    RAISE EXCEPTION 'Trucker role required';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
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
      trucks_booked,
      price_amount,
      price_type,
      advance_percentage,
      pickup_date,
      status,
      public.load_is_public_super_load(is_super_load, super_status) AS is_super_load,
      super_status,
      assigned_trucker_id,
      assigned_truck_id,
      published_at,
      created_at,
      updated_at
    FROM loads
    WHERE id = p_load_id
      AND status IN ('active', 'assigned_partial')
      AND parent_load_id IS NULL
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;
