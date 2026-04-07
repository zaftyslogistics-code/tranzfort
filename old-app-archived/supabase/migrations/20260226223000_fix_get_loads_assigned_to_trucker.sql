-- Fix ambiguous reference in get_loads_assigned_to_trucker detected by supabase db lint.
CREATE OR REPLACE FUNCTION public.get_loads_assigned_to_trucker(
    trucker_uuid UUID,
    status_filter VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    supplier_id UUID,
    origin_city VARCHAR,
    origin_state VARCHAR,
    dest_city VARCHAR,
    dest_state VARCHAR,
    material VARCHAR,
    weight_tonnes DECIMAL,
    required_truck_type body_type,
    required_tyres INTEGER[],
    price DECIMAL,
    price_type price_type,
    advance_percentage INTEGER,
    pickup_date DATE,
    status load_status,
    is_super_load BOOLEAN,
    super_status super_status,
    assigned_trucker_id UUID,
    assigned_truck_id UUID,
    assigned_by UUID,
    pod_photo_url TEXT,
    lr_photo_url TEXT,
    views_count INTEGER,
    responses_count INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    completed_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT l.*
    FROM public.loads l
    WHERE l.assigned_trucker_id = trucker_uuid
      AND (status_filter IS NULL OR l.status = status_filter::load_status)
    ORDER BY l.created_at DESC;
END;
$$;
