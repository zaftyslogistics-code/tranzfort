-- Migration: Add get_linked_trips_for_supplier RPC function
-- Created: 2026-03-22
-- Purpose: Provide RPC for fetching linked trips for a supplier's load

DROP FUNCTION IF EXISTS public.get_linked_trips_for_supplier(p_load_id UUID);

CREATE OR REPLACE FUNCTION public.get_linked_trips_for_supplier(p_load_id UUID)
RETURNS TABLE (
    id UUID,
    load_id UUID,
    trucker_id UUID,
    truck_id UUID,
    stage TEXT,
    assigned_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    pod_uploaded_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    lr_document_path TEXT,
    pod_document_path TEXT,
    load_data JSONB
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_supplier_id UUID;
BEGIN
    -- Get the supplier_id from the load
    SELECT supplier_id INTO v_supplier_id FROM public.loads WHERE id = p_load_id;
    
    IF v_supplier_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if current user is the supplier or an admin
    IF auth.uid() <> v_supplier_id AND NOT public.is_app_admin(auth.uid()) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        t.id,
        t.load_id,
        t.trucker_id,
        t.truck_id,
        t.stage::TEXT,
        t.assigned_at,
        t.delivered_at,
        t.pod_uploaded_at,
        t.completed_at,
        t.lr_document_path,
        t.pod_document_path,
        jsonb_build_object(
            'load_id', l.id,
            'parent_load_id', l.parent_load_id,
            'origin_label', l.origin_label,
            'destination_label', l.destination_label,
            'material', l.material
        ) AS load_data
    FROM public.trips t
    JOIN public.loads l ON l.id = t.load_id
    WHERE t.supplier_id = v_supplier_id
      AND (
          l.id = p_load_id 
          OR l.parent_load_id = p_load_id
      )
    ORDER BY t.assigned_at DESC;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_linked_trips_for_supplier(UUID) TO authenticated;
