-- LOADPOST-2 Slice A: material catalog + create_load material_code support

BEGIN;

CREATE TABLE IF NOT EXISTS public.material_groups (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_hi TEXT,
  sort_order INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.materials (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_hi TEXT,
  group_code TEXT REFERENCES public.material_groups(code) ON UPDATE CASCADE ON DELETE SET NULL,
  keywords TEXT[] NOT NULL DEFAULT '{}',
  popularity_score INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_materials_is_active ON public.materials(is_active);
CREATE INDEX IF NOT EXISTS idx_materials_name_en_lower ON public.materials((LOWER(name_en)));
CREATE INDEX IF NOT EXISTS idx_materials_keywords_gin ON public.materials USING GIN(keywords);

ALTER TABLE public.loads
  ADD COLUMN IF NOT EXISTS material_code TEXT;

ALTER TABLE public.loads
  ADD CONSTRAINT loads_material_code_fkey
  FOREIGN KEY (material_code) REFERENCES public.materials(code)
  ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_loads_material_code ON public.loads(material_code);

INSERT INTO public.material_groups (code, name_en, sort_order)
VALUES
  ('minerals_ores', 'Minerals & Ores', 10),
  ('iron_steel', 'Iron & Steel', 20),
  ('chemicals', 'Chemicals', 30),
  ('plastic_rubber', 'Plastic & Rubber', 40),
  ('construction', 'Construction', 50),
  ('agri_products', 'Agri Products', 60),
  ('others', 'Others', 999)
ON CONFLICT (code) DO UPDATE
SET
  name_en = EXCLUDED.name_en,
  sort_order = EXCLUDED.sort_order,
  updated_at = NOW();

INSERT INTO public.materials (code, name_en, group_code, keywords, popularity_score)
VALUES
  ('coal', 'Coal', 'minerals_ores', ARRAY['koyla', 'thermal coal', 'coal'], 100),
  ('steel', 'Steel', 'iron_steel', ARRAY['ms', 'steel'], 90),
  ('cement', 'Cement', 'construction', ARRAY['opc', 'ppc', 'cement'], 90),
  ('fly_ash', 'Fly Ash', 'construction', ARRAY['flyash', 'ash'], 70),
  ('iron_ore', 'Iron Ore', 'minerals_ores', ARRAY['ore'], 75),
  ('sponge_iron', 'Sponge Iron', 'iron_steel', ARRAY['dri', 'sponge iron'], 80),
  ('plastic', 'Plastic', 'plastic_rubber', ARRAY['plastic'], 60),
  ('plastic_product', 'Plastic Product', 'plastic_rubber', ARRAY['plastic product'], 55),
  ('plastic_granules', 'Plastic Granules / Dana', 'plastic_rubber', ARRAY['dana', 'granules', 'plastic'], 65),
  ('plastic_scrap', 'Plastic Scrap', 'plastic_rubber', ARRAY['scrap', 'plastic'], 50),
  ('fertilizer', 'Fertilizer', 'agri_products', ARRAY['urea', 'dap', 'fertilizer'], 80),
  ('grains', 'Grains', 'agri_products', ARRAY['grain', 'wheat', 'rice'], 70),
  ('machinery', 'Machinery', 'others', ARRAY['equipment', 'machinery'], 50)
ON CONFLICT (code) DO UPDATE
SET
  name_en = EXCLUDED.name_en,
  group_code = EXCLUDED.group_code,
  keywords = EXCLUDED.keywords,
  popularity_score = EXCLUDED.popularity_score,
  updated_at = NOW();

CREATE OR REPLACE FUNCTION public.search_materials(
  p_query TEXT,
  p_limit INTEGER DEFAULT 12
)
RETURNS TABLE (
  code TEXT,
  name_en TEXT,
  name_hi TEXT,
  group_code TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH q AS (
    SELECT LOWER(TRIM(COALESCE(p_query, ''))) AS term
  )
  SELECT
    m.code,
    m.name_en,
    m.name_hi,
    m.group_code
  FROM public.materials m
  CROSS JOIN q
  WHERE m.is_active = TRUE
    AND LENGTH(q.term) >= 2
    AND (
      LOWER(m.name_en) LIKE q.term || '%'
      OR LOWER(m.name_en) LIKE '%' || q.term || '%'
      OR EXISTS (
        SELECT 1
        FROM unnest(m.keywords) kw
        WHERE LOWER(kw) LIKE '%' || q.term || '%'
      )
    )
  ORDER BY
    CASE
      WHEN LOWER(m.name_en) = q.term THEN 0
      WHEN LOWER(m.name_en) LIKE q.term || '%' THEN 1
      ELSE 2
    END,
    m.popularity_score DESC,
    m.name_en ASC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 12), 50));
$$;

GRANT EXECUTE ON FUNCTION public.search_materials(TEXT, INTEGER) TO authenticated;

DROP FUNCTION IF EXISTS public.create_load(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  NUMERIC, INTEGER, TEXT, TEXT,
  TEXT, NUMERIC, TEXT, INTEGER[],
  INTEGER, NUMERIC, public.price_type, INTEGER, DATE,
  public.load_listing_duration
);

CREATE OR REPLACE FUNCTION public.create_load(
  p_origin_label TEXT, p_origin_city TEXT, p_origin_state TEXT,
  p_origin_lat DOUBLE PRECISION, p_origin_lng DOUBLE PRECISION,
  p_destination_label TEXT, p_destination_city TEXT, p_destination_state TEXT,
  p_destination_lat DOUBLE PRECISION, p_destination_lng DOUBLE PRECISION,
  p_route_distance_km NUMERIC, p_route_duration_minutes INTEGER,
  p_route_polyline TEXT, p_route_snapshot_source TEXT,
  p_material TEXT, p_weight_tonnes NUMERIC,
  p_required_body_type TEXT, p_required_tyres INTEGER[],
  p_trucks_needed INTEGER, p_price_amount NUMERIC,
  p_price_type public.price_type, p_advance_percentage INTEGER,
  p_pickup_date DATE,
  p_listing_duration public.load_listing_duration DEFAULT '7_days',
  p_material_code TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_load_id UUID;
  v_supplier_id UUID;
  v_canonical_price_type public.price_type;
  v_body_type TEXT;
  v_verification public.verification_status;
  v_posted_today INTEGER;
  v_daily_limit CONSTANT INTEGER := 20;
  v_visible_until TIMESTAMPTZ;
  v_material_code TEXT;
  v_material_name TEXT;
BEGIN
  v_supplier_id := auth.uid();
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT p.verification_status
  INTO v_verification
  FROM public.profiles p
  WHERE p.id = v_supplier_id;

  IF v_verification IS DISTINCT FROM 'verified' THEN
    RAISE EXCEPTION 'Supplier verification required';
  END IF;

  v_posted_today := public.supplier_loads_posted_today_count(v_supplier_id);
  IF v_posted_today >= v_daily_limit THEN
    RAISE EXCEPTION 'daily_post_limit_reached'
      USING HINT = format('Posted %s of %s loads today (IST)', v_posted_today, v_daily_limit);
  END IF;

  v_canonical_price_type := CASE
    WHEN p_price_type = 'negotiable' THEN 'per_ton'::public.price_type
    ELSE p_price_type
  END;

  v_body_type := NULLIF(TRIM(LOWER(COALESCE(p_required_body_type, ''))), '');
  IF v_body_type IN ('any', '') THEN
    v_body_type := NULL;
  END IF;

  v_material_code := NULLIF(TRIM(COALESCE(p_material_code, '')), '');
  IF v_material_code IS NOT NULL THEN
    SELECT m.name_en
    INTO v_material_name
    FROM public.materials m
    WHERE m.code = v_material_code
      AND m.is_active = TRUE;
    IF v_material_name IS NULL THEN
      RAISE EXCEPTION 'Invalid material_code';
    END IF;
  ELSE
    v_material_name := NULLIF(TRIM(COALESCE(p_material, '')), '');
  END IF;

  IF v_material_name IS NULL THEN
    RAISE EXCEPTION 'Material is required';
  END IF;

  v_visible_until := NOW() + public.listing_duration_interval(p_listing_duration);

  IF NOT EXISTS (SELECT 1 FROM public.suppliers WHERE id = v_supplier_id) THEN
    INSERT INTO public.suppliers (id) VALUES (v_supplier_id)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  INSERT INTO public.loads (
    supplier_id, origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, material_code, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage,
    pickup_date, status, published_at,
    listing_duration, marketplace_visible_until
  ) VALUES (
    v_supplier_id, p_origin_label, p_origin_city, p_origin_state, p_origin_lat, p_origin_lng,
    p_destination_label, p_destination_city, p_destination_state, p_destination_lat, p_destination_lng,
    p_route_distance_km, p_route_duration_minutes, p_route_polyline, p_route_snapshot_source,
    v_material_name, v_material_code, p_weight_tonnes, v_body_type, p_required_tyres,
    p_trucks_needed, p_price_amount, v_canonical_price_type, p_advance_percentage,
    p_pickup_date, 'active', NOW(),
    p_listing_duration, v_visible_until
  ) RETURNING id INTO v_load_id;

  UPDATE public.suppliers SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_load_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_load(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  NUMERIC, INTEGER, TEXT, TEXT,
  TEXT, NUMERIC, TEXT, INTEGER[],
  INTEGER, NUMERIC, public.price_type, INTEGER, DATE,
  public.load_listing_duration, TEXT
) TO authenticated;

COMMIT;
