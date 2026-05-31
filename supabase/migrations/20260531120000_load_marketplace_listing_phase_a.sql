-- P1-LOAD Phase A: marketplace listing columns, load_is_on_marketplace(), feed fix
-- Locked rules: review-31-may.md § P1-LOAD — partial booking stays visible until full OR time ends
-- Does NOT change approve_booking_request / trip RPCs (Phase D)

-- ─── Listing duration enum + columns ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'load_listing_duration') THEN
    CREATE TYPE public.load_listing_duration AS ENUM (
      '48_hours',
      '7_days',
      '30_days'
    );
  END IF;
END $$;

ALTER TABLE public.loads
  ADD COLUMN IF NOT EXISTS listing_duration public.load_listing_duration,
  ADD COLUMN IF NOT EXISTS marketplace_visible_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reposted_from_load_id UUID REFERENCES public.loads(id);

-- Backfill parent loads (default 7-day listing window from publish/create time)
UPDATE public.loads
SET
  listing_duration = COALESCE(listing_duration, '7_days'::public.load_listing_duration),
  marketplace_visible_until = COALESCE(
    marketplace_visible_until,
    COALESCE(published_at, created_at) + INTERVAL '7 days'
  )
WHERE parent_load_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_loads_marketplace_visible_until
  ON public.loads (marketplace_visible_until)
  WHERE parent_load_id IS NULL;

-- ─── Marketplace visibility (single source of truth) ───
CREATE OR REPLACE FUNCTION public.load_is_on_marketplace(l public.loads)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT
    l.parent_load_id IS NULL
    AND l.trucks_booked < l.trucks_needed
    AND l.marketplace_visible_until IS NOT NULL
    AND l.marketplace_visible_until > NOW()
    AND l.status IN ('active', 'assigned_partial')
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = l.supplier_id
        AND p.verification_status = 'verified'
    );
$$;

COMMENT ON FUNCTION public.load_is_on_marketplace(public.loads) IS
  'True when parent load should appear on Find Loads (P1-LOAD locked formula).';

-- ─── get_marketplace_feed: include assigned_partial with open slots ───
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
      AND (p_super_loads_only = FALSE OR l.is_super_load = TRUE)
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
