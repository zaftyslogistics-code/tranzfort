-- Marketplace consolidated feed RPC (P1.6a.2)
-- Returns load + supplier summary + ranking metadata in one paginated call,
-- replacing direct loads table read + separate supplier profile query.
--
-- Benefits:
--   - Single round-trip instead of N+1 supplier lookups
--   - Centralized visibility rules (only active loads, verified suppliers)
--   - Easier to add ranking/sorting in one place

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
  p_sort_by             TEXT DEFAULT 'newest',   -- newest | price_asc | price_desc | pickup_date
  p_page_size           INT DEFAULT 20,
  p_page                INT DEFAULT 1
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset   INT := (p_page - 1) * p_page_size;
  v_total    BIGINT;
  v_results  JSONB;
BEGIN
  -- Count total (for pagination metadata)
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

  -- Fetch paginated results with supplier summary inline
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
      -- Supplier summary inline
      jsonb_build_object(
        'supplier_name',        p.full_name,
        'supplier_avatar_url',  p.avatar_url,
        'supplier_photo_path',  p.profile_photo_document_path,
        'supplier_mobile',      p.mobile,
        'supplier_trust_score', COALESCE((
          SELECT trust_score FROM public.profile_trust_scores WHERE profile_id = p.id
        ), 0)
      ) AS supplier_summary,
      -- Ranking metadata
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
