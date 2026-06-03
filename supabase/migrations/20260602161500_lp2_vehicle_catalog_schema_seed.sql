-- LOADPOST-2 Slice F: vehicle catalog schema + seed from capacity master UI/UX
BEGIN;

CREATE TABLE IF NOT EXISTS public.vehicle_categories (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_hi TEXT,
  ui_mode TEXT NOT NULL DEFAULT 'configuration_only',
  sort_order INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vehicle_body_styles (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_hi TEXT,
  sort_order INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vehicle_category_body_styles (
  category_code TEXT NOT NULL REFERENCES public.vehicle_categories(code) ON UPDATE CASCADE ON DELETE CASCADE,
  body_style_code TEXT NOT NULL REFERENCES public.vehicle_body_styles(code) ON UPDATE CASCADE ON DELETE CASCADE,
  sort_order INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (category_code, body_style_code)
);

CREATE TABLE IF NOT EXISTS public.vehicle_configurations (
  code TEXT PRIMARY KEY,
  category_code TEXT NOT NULL REFERENCES public.vehicle_categories(code) ON UPDATE CASCADE ON DELETE CASCADE,
  body_style_code TEXT REFERENCES public.vehicle_body_styles(code) ON UPDATE CASCADE ON DELETE SET NULL,
  label_en TEXT NOT NULL,
  label_hi TEXT,
  wheels_w INTEGER,
  length_ft TEXT,
  loading_ton_min NUMERIC,
  loading_ton_max NUMERIC,
  is_special BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vehicle_categories_is_active ON public.vehicle_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_vehicle_body_styles_is_active ON public.vehicle_body_styles(is_active);
CREATE INDEX IF NOT EXISTS idx_vehicle_configurations_category_active
  ON public.vehicle_configurations(category_code, is_active);
CREATE INDEX IF NOT EXISTS idx_vehicle_configurations_body_style
  ON public.vehicle_configurations(body_style_code);

ALTER TABLE public.loads
  ADD COLUMN IF NOT EXISTS required_vehicle_category_code TEXT REFERENCES public.vehicle_categories(code) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE public.loads
  ADD COLUMN IF NOT EXISTS required_body_style_codes TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.loads
  ADD COLUMN IF NOT EXISTS required_configuration_codes TEXT[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_loads_required_vehicle_category_code ON public.loads(required_vehicle_category_code);
CREATE INDEX IF NOT EXISTS idx_loads_required_configuration_codes_gin ON public.loads USING GIN(required_configuration_codes);
CREATE INDEX IF NOT EXISTS idx_loads_required_body_style_codes_gin ON public.loads USING GIN(required_body_style_codes);

ALTER TABLE public.trucks
  ADD COLUMN IF NOT EXISTS vehicle_category_code TEXT REFERENCES public.vehicle_categories(code) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE public.trucks
  ADD COLUMN IF NOT EXISTS vehicle_body_style_code TEXT REFERENCES public.vehicle_body_styles(code) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE public.trucks
  ADD COLUMN IF NOT EXISTS configuration_code TEXT REFERENCES public.vehicle_configurations(code) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE public.trucks
  ADD COLUMN IF NOT EXISTS passing_tonnes NUMERIC;

CREATE INDEX IF NOT EXISTS idx_trucks_vehicle_category_code ON public.trucks(vehicle_category_code);
CREATE INDEX IF NOT EXISTS idx_trucks_vehicle_body_style_code ON public.trucks(vehicle_body_style_code);
CREATE INDEX IF NOT EXISTS idx_trucks_configuration_code ON public.trucks(configuration_code);

INSERT INTO public.vehicle_categories (code, name_en, ui_mode, sort_order)
VALUES
  ('lcv', 'LCV', 'body_and_capacity', 10),
  ('open_truck', 'Open Truck', 'wheels_body_capacity', 20),
  ('trailer', 'Trailer', 'wheels_body_capacity', 30),
  ('container', 'Container', 'wheels_length_capacity', 40),
  ('bulker', 'Bulker', 'wheels_body_capacity', 50),
  ('tanker', 'Tanker', 'wheels_body_capacity', 60),
  ('tipper', 'Tipper', 'wheels_body_capacity', 70),
  ('reefer', 'Reefer', 'wheels_body_capacity', 80),
  ('parcel', 'Parcel', 'wheels_body_capacity', 90),
  ('odc', 'ODC', 'wheels_body_capacity', 100)
ON CONFLICT (code) DO UPDATE
SET
  name_en = EXCLUDED.name_en,
  ui_mode = EXCLUDED.ui_mode,
  sort_order = EXCLUDED.sort_order,
  updated_at = NOW();

INSERT INTO public.vehicle_body_styles (code, name_en, sort_order)
VALUES
  ('open', 'Open', 10),
  ('closed', 'Closed', 20),
  ('half_body', 'Half Body', 30),
  ('full_body', 'Full Body', 40),
  ('high_side', 'High Side', 50),
  ('flat_bed', 'Flat Bed', 60),
  ('cement_bulker', 'Cement Bulker', 70),
  ('fly_ash_bulker', 'Fly Ash Bulker', 80),
  ('lime_bulker', 'Lime Bulker', 90),
  ('powder_bulker', 'Powder Bulker', 100),
  ('water_tanker', 'Water Tanker', 110),
  ('chemical_tanker', 'Chemical Tanker', 120),
  ('acid_tanker', 'Acid Tanker', 130),
  ('petroleum_tanker', 'Petroleum Tanker', 140),
  ('edible_oil_tanker', 'Edible Oil Tanker', 150),
  ('mining', 'Mining', 160),
  ('heavy_mining', 'Heavy Mining', 170),
  ('reefer', 'Reefer', 180),
  ('closed_body', 'Closed Body', 190),
  ('semi_low_bed', 'Semi Low Bed', 200),
  ('low_bed', 'Low Bed', 210),
  ('hydraulic_axle', 'Hydraulic Axle', 220),
  ('multi_axle_hydraulic', 'Multi Axle Hydraulic', 230),
  ('extendable_trailer', 'Extendable Trailer', 240),
  ('length_ft', 'Length (FT)', 250)
ON CONFLICT (code) DO UPDATE
SET
  name_en = EXCLUDED.name_en,
  sort_order = EXCLUDED.sort_order,
  updated_at = NOW();

INSERT INTO public.vehicle_category_body_styles (category_code, body_style_code, sort_order)
VALUES
  ('lcv', 'open', 10),
  ('lcv', 'closed', 20),
  ('open_truck', 'half_body', 10),
  ('open_truck', 'full_body', 20),
  ('open_truck', 'high_side', 30),
  ('trailer', 'flat_bed', 10),
  ('trailer', 'full_body', 20),
  ('trailer', 'high_side', 30),
  ('container', 'length_ft', 10),
  ('bulker', 'cement_bulker', 10),
  ('bulker', 'fly_ash_bulker', 20),
  ('bulker', 'lime_bulker', 30),
  ('bulker', 'powder_bulker', 40),
  ('tanker', 'water_tanker', 10),
  ('tanker', 'chemical_tanker', 20),
  ('tanker', 'acid_tanker', 30),
  ('tanker', 'petroleum_tanker', 40),
  ('tanker', 'edible_oil_tanker', 50),
  ('tipper', 'mining', 10),
  ('tipper', 'heavy_mining', 20),
  ('reefer', 'reefer', 10),
  ('parcel', 'closed_body', 10),
  ('odc', 'semi_low_bed', 10),
  ('odc', 'low_bed', 20),
  ('odc', 'hydraulic_axle', 30),
  ('odc', 'multi_axle_hydraulic', 40),
  ('odc', 'extendable_trailer', 50)
ON CONFLICT (category_code, body_style_code) DO UPDATE
SET
  sort_order = EXCLUDED.sort_order,
  is_active = TRUE;

INSERT INTO public.vehicle_configurations (
  code, category_code, body_style_code, label_en, wheels_w, length_ft, loading_ton_min, loading_ton_max, is_special, sort_order
)
VALUES
  ('lcv_4w_open_0_5_1t', 'lcv', 'open', 'LCV • 4W • Open • 0.5-1T', 4, NULL, 0.5, 1, FALSE, 10),
  ('lcv_4w_open_1_2t', 'lcv', 'open', 'LCV • 4W • Open • 1-2T', 4, NULL, 1, 2, FALSE, 20),
  ('lcv_4w_closed_0_5_1t', 'lcv', 'closed', 'LCV • 4W • Closed • 0.5-1T', 4, NULL, 0.5, 1, FALSE, 30),
  ('lcv_4w_closed_1_2t', 'lcv', 'closed', 'LCV • 4W • Closed • 1-2T', 4, NULL, 1, 2, FALSE, 40),
  ('open_6w_half_3_5t', 'open_truck', 'half_body', 'Open Truck • 6W • Half Body • 3-5T', 6, NULL, 3, 5, FALSE, 50),
  ('open_6w_full_4_7t', 'open_truck', 'full_body', 'Open Truck • 6W • Full Body • 4-7T', 6, NULL, 4, 7, FALSE, 60),
  ('open_10w_half_8_12t', 'open_truck', 'half_body', 'Open Truck • 10W • Half Body • 8-12T', 10, NULL, 8, 12, FALSE, 70),
  ('open_10w_full_10_16t', 'open_truck', 'full_body', 'Open Truck • 10W • Full Body • 10-16T', 10, NULL, 10, 16, FALSE, 80),
  ('open_12w_half_15_22t', 'open_truck', 'half_body', 'Open Truck • 12W • Half Body • 15-22T', 12, NULL, 15, 22, FALSE, 90),
  ('open_12w_full_18_25t', 'open_truck', 'full_body', 'Open Truck • 12W • Full Body • 18-25T', 12, NULL, 18, 25, FALSE, 100),
  ('open_14w_half_20_28t', 'open_truck', 'half_body', 'Open Truck • 14W • Half Body • 20-28T', 14, NULL, 20, 28, FALSE, 110),
  ('open_14w_full_28_32t', 'open_truck', 'full_body', 'Open Truck • 14W • Full Body • 28-32T', 14, NULL, 28, 32, FALSE, 120),
  ('open_16w_half_25_30t', 'open_truck', 'half_body', 'Open Truck • 16W • Half Body • 25-30T', 16, NULL, 25, 30, FALSE, 130),
  ('open_16w_full_30_35t', 'open_truck', 'full_body', 'Open Truck • 16W • Full Body • 30-35T', 16, NULL, 30, 35, FALSE, 140),
  ('open_16w_high_30_36t', 'open_truck', 'high_side', 'Open Truck • 16W • High Side • 30-36T', 16, NULL, 30, 36, FALSE, 150),
  ('open_18w_high_34_42t', 'open_truck', 'high_side', 'Open Truck • 18W • High Side • 34-42T', 18, NULL, 34, 42, FALSE, 160),
  ('trailer_18w_flat_30_38t', 'trailer', 'flat_bed', 'Trailer • 18W • Flat Bed • 30-38T', 18, NULL, 30, 38, FALSE, 170),
  ('trailer_18w_full_35_42t', 'trailer', 'full_body', 'Trailer • 18W • Full Body • 35-42T', 18, NULL, 35, 42, FALSE, 180),
  ('trailer_18w_high_38_42t', 'trailer', 'high_side', 'Trailer • 18W • High Side • 38-42T', 18, NULL, 38, 42, FALSE, 190),
  ('trailer_22w_flat_35_42t', 'trailer', 'flat_bed', 'Trailer • 22W • Flat Bed • 35-42T', 22, NULL, 35, 42, FALSE, 200),
  ('trailer_22w_full_40_45t', 'trailer', 'full_body', 'Trailer • 22W • Full Body • 40-45T', 22, NULL, 40, 45, FALSE, 210),
  ('trailer_22w_high_42_48t', 'trailer', 'high_side', 'Trailer • 22W • High Side • 42-48T', 22, NULL, 42, 48, FALSE, 220),
  ('container_18w_20ft_20_28t', 'container', 'length_ft', 'Container • 18W • 20FT • 20-28T', 18, '20', 20, 28, FALSE, 230),
  ('container_18w_24ft_22_28t', 'container', 'length_ft', 'Container • 18W • 24FT • 22-28T', 18, '24', 22, 28, FALSE, 240),
  ('container_18w_32ft_24_30t', 'container', 'length_ft', 'Container • 18W • 32FT • 24-30T', 18, '32', 24, 30, FALSE, 250),
  ('container_18w_40ft_26_32t', 'container', 'length_ft', 'Container • 18W • 40FT • 26-32T', 18, '40', 26, 32, FALSE, 260),
  ('container_18w_40ft_hc_26_30t', 'container', 'length_ft', 'Container • 18W • 40FT HC • 26-30T', 18, '40HC', 26, 30, FALSE, 270),
  ('tanker_10w_water_10_18t', 'tanker', 'water_tanker', 'Tanker • 10W • Water Tanker • 10-18T', 10, NULL, 10, 18, FALSE, 280),
  ('tanker_12w_water_15_22t', 'tanker', 'water_tanker', 'Tanker • 12W • Water Tanker • 15-22T', 12, NULL, 15, 22, FALSE, 290),
  ('tanker_18w_chemical_25_38t', 'tanker', 'chemical_tanker', 'Tanker • 18W • Chemical Tanker • 25-38T', 18, NULL, 25, 38, FALSE, 300),
  ('reefer_6w_3_7t', 'reefer', 'reefer', 'Reefer • 6W • Reefer • 3-7T', 6, NULL, 3, 7, FALSE, 310),
  ('reefer_10w_8_15t', 'reefer', 'reefer', 'Reefer • 10W • Reefer • 8-15T', 10, NULL, 8, 15, FALSE, 320),
  ('reefer_12w_15_22t', 'reefer', 'reefer', 'Reefer • 12W • Reefer • 15-22T', 12, NULL, 15, 22, FALSE, 330),
  ('odc_18w_semi_low_30_50t', 'odc', 'semi_low_bed', 'ODC • 18W • Semi Low Bed • 30-50T', 18, NULL, 30, 50, FALSE, 340),
  ('odc_18w_low_35_60t', 'odc', 'low_bed', 'ODC • 18W • Low Bed • 35-60T', 18, NULL, 35, 60, FALSE, 350),
  ('odc_22w_low_40_80t', 'odc', 'low_bed', 'ODC • 22W • Low Bed • 40-80T', 22, NULL, 40, 80, FALSE, 360),
  ('odc_22w_hydraulic_40_120t', 'odc', 'hydraulic_axle', 'ODC • 22W+ • Hydraulic Axle • 40-120T', 22, NULL, 40, 120, FALSE, 370),
  ('odc_30w_multi_80_300t', 'odc', 'multi_axle_hydraulic', 'ODC • 30W+ • Multi Axle Hydraulic • 80-300T+', 30, NULL, 80, 300, FALSE, 380),
  ('odc_22w_extendable_special', 'odc', 'extendable_trailer', 'ODC • 22W+ • Extendable Trailer • Special Project Cargo', 22, NULL, NULL, NULL, TRUE, 390)
ON CONFLICT (code) DO UPDATE
SET
  label_en = EXCLUDED.label_en,
  wheels_w = EXCLUDED.wheels_w,
  length_ft = EXCLUDED.length_ft,
  loading_ton_min = EXCLUDED.loading_ton_min,
  loading_ton_max = EXCLUDED.loading_ton_max,
  is_special = EXCLUDED.is_special,
  sort_order = EXCLUDED.sort_order,
  is_active = TRUE,
  updated_at = NOW();

CREATE OR REPLACE FUNCTION public.get_vehicle_catalog()
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'categories',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'code', vc.code,
            'name_en', vc.name_en,
            'name_hi', vc.name_hi,
            'ui_mode', vc.ui_mode
          )
          ORDER BY vc.sort_order, vc.name_en
        )
        FROM public.vehicle_categories vc
        WHERE vc.is_active = TRUE
      ),
      '[]'::jsonb
    ),
    'body_styles',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'category_code', vcbs.category_code,
            'code', vbs.code,
            'name_en', vbs.name_en,
            'name_hi', vbs.name_hi
          )
          ORDER BY vcbs.category_code, vcbs.sort_order, vbs.name_en
        )
        FROM public.vehicle_category_body_styles vcbs
        JOIN public.vehicle_body_styles vbs
          ON vbs.code = vcbs.body_style_code
        WHERE vcbs.is_active = TRUE
          AND vbs.is_active = TRUE
      ),
      '[]'::jsonb
    ),
    'configurations',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'code', cfg.code,
            'category_code', cfg.category_code,
            'body_style_code', cfg.body_style_code,
            'label_en', cfg.label_en,
            'label_hi', cfg.label_hi,
            'wheels_w', cfg.wheels_w,
            'length_ft', cfg.length_ft,
            'loading_ton_min', cfg.loading_ton_min,
            'loading_ton_max', cfg.loading_ton_max,
            'is_special', cfg.is_special
          )
          ORDER BY cfg.category_code, cfg.sort_order, cfg.label_en
        )
        FROM public.vehicle_configurations cfg
        WHERE cfg.is_active = TRUE
      ),
      '[]'::jsonb
    )
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_vehicle_catalog() TO authenticated;

COMMIT;
