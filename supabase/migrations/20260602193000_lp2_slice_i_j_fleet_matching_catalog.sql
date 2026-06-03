-- LOADPOST-2 Slice I + J
-- Fleet catalog fields + matching compatibility (category/body-style/config + legacy fallback).

DROP FUNCTION IF EXISTS public.add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.update_truck(UUID, TEXT, TEXT, INTEGER, NUMERIC, TEXT);

CREATE OR REPLACE FUNCTION public.get_trucker_fleet(
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_trucks JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to view this fleet';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'truck_model_id', t.truck_model_id,
      'truck_number', t.truck_number,
      'body_type', t.body_type,
      'vehicle_category_code', t.vehicle_category_code,
      'vehicle_body_style_code', t.vehicle_body_style_code,
      'configuration_code', t.configuration_code,
      'tyres', t.tyres,
      'capacity_tonnes', t.capacity_tonnes,
      'passing_tonnes', t.passing_tonnes,
      'rc_document_path', t.rc_document_path,
      'status', t.status,
      'rejection_reason', t.rejection_reason,
      'verification_feedback_json', t.verification_feedback_json,
      'verified_at', t.verified_at,
      'created_at', t.created_at,
      'updated_at', t.updated_at,
      'truck_models', jsonb_build_object(
        'make', tm.make,
        'model', tm.model,
        'axles', tm.axles,
        'payload_kg', tm.payload_kg,
        'mileage_empty_kmpl', tm.mileage_empty_kmpl,
        'mileage_loaded_kmpl', tm.mileage_loaded_kmpl
      )
    )
  )
  INTO v_trucks
  FROM (
    SELECT t.*
    FROM public.trucks t
    WHERE t.owner_id = p_user_id
      AND t.status != 'archived'
    ORDER BY t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t
  LEFT JOIN public.truck_models tm ON tm.id = t.truck_model_id;

  RETURN COALESCE(v_trucks, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION public.add_truck(
  p_truck_number TEXT,
  p_body_type TEXT,
  p_tyres INTEGER,
  p_capacity_tonnes NUMERIC,
  p_rc_document_path TEXT,
  p_vehicle_category_code TEXT DEFAULT NULL,
  p_vehicle_body_style_code TEXT DEFAULT NULL,
  p_configuration_code TEXT DEFAULT NULL,
  p_passing_tonnes NUMERIC DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_truck_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_truck_number IS NULL OR BTRIM(p_truck_number) = '' THEN
    RAISE EXCEPTION 'Truck number is required';
  END IF;

  IF p_body_type IS NULL OR BTRIM(p_body_type) = '' THEN
    RAISE EXCEPTION 'Body type is required';
  END IF;

  IF p_tyres IS NULL OR p_tyres <= 0 THEN
    RAISE EXCEPTION 'Tyres must be a positive integer';
  END IF;

  IF p_capacity_tonnes IS NULL OR p_capacity_tonnes <= 0 THEN
    RAISE EXCEPTION 'Capacity must be a positive number';
  END IF;

  INSERT INTO public.trucks (
    owner_id,
    truck_number,
    body_type,
    vehicle_category_code,
    vehicle_body_style_code,
    configuration_code,
    tyres,
    capacity_tonnes,
    passing_tonnes,
    rc_document_path,
    status
  ) VALUES (
    v_user_id,
    UPPER(BTRIM(p_truck_number)),
    BTRIM(p_body_type),
    NULLIF(BTRIM(COALESCE(p_vehicle_category_code, '')), ''),
    NULLIF(BTRIM(COALESCE(p_vehicle_body_style_code, '')), ''),
    NULLIF(BTRIM(COALESCE(p_configuration_code, '')), ''),
    p_tyres,
    p_capacity_tonnes,
    p_passing_tonnes,
    BTRIM(p_rc_document_path),
    'pending'
  )
  RETURNING id INTO v_truck_id;

  RETURN jsonb_build_object('id', v_truck_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_truck(
  p_truck_id UUID,
  p_truck_number TEXT,
  p_body_type TEXT,
  p_tyres INTEGER,
  p_capacity_tonnes NUMERIC,
  p_rc_document_path TEXT,
  p_vehicle_category_code TEXT DEFAULT NULL,
  p_vehicle_body_style_code TEXT DEFAULT NULL,
  p_configuration_code TEXT DEFAULT NULL,
  p_passing_tonnes NUMERIC DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_existing_truck RECORD;
  v_critical_fields_changed BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT *
  INTO v_existing_truck
  FROM public.trucks
  WHERE id = p_truck_id
    AND owner_id = v_user_id
  FOR UPDATE;

  IF v_existing_truck IS NULL THEN
    RAISE EXCEPTION 'Truck not found or not owned by user';
  END IF;

  v_critical_fields_changed := (
    v_existing_truck.truck_number != UPPER(BTRIM(p_truck_number))
    OR v_existing_truck.body_type != BTRIM(p_body_type)
    OR COALESCE(v_existing_truck.vehicle_category_code, '') != COALESCE(NULLIF(BTRIM(p_vehicle_category_code), ''), '')
    OR COALESCE(v_existing_truck.vehicle_body_style_code, '') != COALESCE(NULLIF(BTRIM(p_vehicle_body_style_code), ''), '')
    OR COALESCE(v_existing_truck.configuration_code, '') != COALESCE(NULLIF(BTRIM(p_configuration_code), ''), '')
    OR v_existing_truck.tyres != p_tyres
    OR v_existing_truck.capacity_tonnes != p_capacity_tonnes
    OR COALESCE(v_existing_truck.passing_tonnes, 0) != COALESCE(p_passing_tonnes, 0)
    OR COALESCE(v_existing_truck.rc_document_path, '') != BTRIM(p_rc_document_path)
  );

  UPDATE public.trucks
  SET
    truck_number = UPPER(BTRIM(p_truck_number)),
    body_type = BTRIM(p_body_type),
    vehicle_category_code = NULLIF(BTRIM(COALESCE(p_vehicle_category_code, '')), ''),
    vehicle_body_style_code = NULLIF(BTRIM(COALESCE(p_vehicle_body_style_code, '')), ''),
    configuration_code = NULLIF(BTRIM(COALESCE(p_configuration_code, '')), ''),
    tyres = p_tyres,
    capacity_tonnes = p_capacity_tonnes,
    passing_tonnes = p_passing_tonnes,
    rc_document_path = BTRIM(p_rc_document_path),
    status = CASE
      WHEN v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN 'edited_pending_reapproval'
      ELSE v_existing_truck.status
    END,
    rejection_reason = CASE
      WHEN v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN NULL
      ELSE rejection_reason
    END,
    verification_feedback_json = CASE
      WHEN v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN NULL
      ELSE verification_feedback_json
    END,
    verified_at = CASE
      WHEN v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN NULL
      ELSE verified_at
    END,
    verified_by_admin_user_id = CASE
      WHEN v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN NULL
      ELSE verified_by_admin_user_id
    END,
    updated_at = NOW()
  WHERE id = p_truck_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.truck_matches_load_requirements(
  p_truck public.trucks,
  p_load public.loads
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT
    (
      p_load.required_vehicle_category_code IS NULL
      OR BTRIM(p_load.required_vehicle_category_code) = ''
      OR LOWER(BTRIM(p_load.required_vehicle_category_code)) = LOWER(BTRIM(COALESCE(p_truck.vehicle_category_code, '')))
    )
    AND (
      p_load.required_body_style_codes IS NULL
      OR cardinality(p_load.required_body_style_codes) = 0
      OR LOWER(BTRIM(COALESCE(p_truck.vehicle_body_style_code, ''))) = ANY(
        ARRAY(
          SELECT LOWER(BTRIM(item))
          FROM unnest(p_load.required_body_style_codes) AS item
        )
      )
    )
    AND (
      p_load.required_configuration_codes IS NULL
      OR cardinality(p_load.required_configuration_codes) = 0
      OR LOWER(BTRIM(COALESCE(p_truck.configuration_code, ''))) = ANY(
        ARRAY(
          SELECT LOWER(BTRIM(item))
          FROM unnest(p_load.required_configuration_codes) AS item
        )
      )
    )
    AND (
      p_load.required_body_type IS NULL
      OR TRIM(p_load.required_body_type) = ''
      OR LOWER(TRIM(p_load.required_body_type)) = LOWER(TRIM(p_truck.body_type::text))
    )
    AND (
      p_load.required_tyres IS NULL
      OR cardinality(p_load.required_tyres) = 0
      OR p_truck.tyres = ANY(p_load.required_tyres)
    )
    AND COALESCE(p_truck.capacity_tonnes, 0) >= COALESCE(p_load.weight_tonnes, 0);
$$;

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
    FROM public.profiles
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
      required_vehicle_category_code,
      required_body_style_codes,
      required_configuration_codes,
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
    FROM public.loads
    WHERE id = p_load_id
      AND status IN ('active', 'assigned_partial')
      AND parent_load_id IS NULL
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_trucker_fleet(UUID, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT, TEXT, TEXT, TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_truck(UUID, TEXT, TEXT, INTEGER, NUMERIC, TEXT, TEXT, TEXT, TEXT, NUMERIC) TO authenticated;
