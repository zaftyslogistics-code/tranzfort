-- Public load previews RPC
-- Returns paginated public-visible loads for a supplier profile with trust-safety filtering.
-- Visibility rules: only loads with status in ('active', 'completed', 'assigned_partial', 'assigned_full')
-- and supplier must have verification_status = 'verified'.

DROP FUNCTION IF EXISTS public.get_public_load_previews(UUID, INT, INT, TEXT);

CREATE OR REPLACE FUNCTION public.get_public_load_previews(
    p_supplier_id UUID,
    p_limit     INT DEFAULT 5,
    p_offset    INT DEFAULT 0,
    p_status_filter TEXT DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_results JSONB;
    v_total   BIGINT;
BEGIN
    -- Verify supplier is verified before returning any loads
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = p_supplier_id AND p.verification_status = 'verified'
    ) THEN
        RETURN jsonb_build_object('loads', '[]'::JSONB, 'total', 0);
    END IF;

    -- Count total
    SELECT COUNT(*) INTO v_total
    FROM public.loads l
    WHERE l.supplier_id = p_supplier_id
      AND l.parent_load_id IS NULL
      AND (
          p_status_filter IS NOT NULL
          AND p_status_filter <> ''
          AND l.status = p_status_filter
          OR p_status_filter IS NULL
          OR p_status_filter = ''
      )
      AND l.status IN ('active', 'completed', 'assigned_partial', 'assigned_full');

    -- Fetch paginated results
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
              AND l.status = p_status_filter
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
$$;

GRANT EXECUTE ON FUNCTION public.get_public_load_previews(UUID, INT, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_load_previews(UUID, INT, INT, TEXT) TO anon;
