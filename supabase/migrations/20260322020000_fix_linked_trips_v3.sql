-- Migration: Fix get_linked_trips_for_supplier RPC v3
-- Created: 2026-03-22
-- Purpose: Fix function to work without is_app_admin dependency

DROP FUNCTION IF EXISTS public.get_linked_trips_for_supplier(p_load_id UUID);

CREATE OR REPLACE FUNCTION public.get_linked_trips_for_supplier(p_load_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
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
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_linked_trips_for_supplier(UUID) TO authenticated;
