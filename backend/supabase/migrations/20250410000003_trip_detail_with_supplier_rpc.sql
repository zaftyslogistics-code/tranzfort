-- Migration: Create consolidated RPC for trip detail with supplier info
-- This combines 3 separate queries into 1 for better performance
-- Replaces: fetchTripDetail + fetchSupplierProfile + fetchSupplierExtension

CREATE OR REPLACE FUNCTION get_trip_detail_with_supplier(
  p_trip_id UUID,
  p_trucker_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_trip JSONB;
  v_supplier_profile JSONB;
  v_supplier_extension JSONB;
  v_dispute_summary JSONB;
BEGIN
  -- Fetch trip detail with all related data in single query
  SELECT jsonb_build_object(
    'id', t.id,
    'load_id', t.load_id,
    'supplier_id', t.supplier_id,
    'truck_id', t.truck_id,
    'stage', t.stage,
    'assigned_at', t.assigned_at,
    'started_at', t.started_at,
    'delivered_at', t.delivered_at,
    'pod_uploaded_at', t.pod_uploaded_at,
    'completed_at', t.completed_at,
    'lr_document_path', t.lr_document_path,
    'pod_document_path', t.pod_document_path,
    'load_snapshot_summary', t.load_snapshot_summary,
    'loads', jsonb_build_object(
      'origin_label', l.origin_label,
      'origin_city', l.origin_city,
      'origin_state', l.origin_state,
      'origin_lat', l.origin_lat,
      'origin_lng', l.origin_lng,
      'destination_label', l.destination_label,
      'destination_city', l.destination_city,
      'destination_state', l.destination_state,
      'destination_lat', l.destination_lat,
      'destination_lng', l.destination_lng,
      'route_distance_km', l.route_distance_km,
      'route_duration_minutes', l.route_duration_minutes,
      'route_snapshot_source', l.route_snapshot_source,
      'material', l.material,
      'pickup_date', l.pickup_date
    ),
    'trucks', jsonb_build_object(
      'truck_number', tr.truck_number,
      'body_type', tr.body_type,
      'tyres', tr.tyres
    )
  )
  INTO v_trip
  FROM trips t
  LEFT JOIN loads l ON l.id = t.load_id
  LEFT JOIN trucks tr ON tr.id = t.truck_id
  WHERE t.id = p_trip_id
    AND t.trucker_id = p_trucker_id;

  -- Return null if trip not found or not owned by this trucker
  IF v_trip IS NULL THEN
    RETURN NULL;
  END IF;

  -- Fetch supplier profile
  SELECT jsonb_build_object(
    'id', p.id,
    'full_name', p.full_name,
    'verification_status', p.verification_status,
    'mobile', p.mobile
  )
  INTO v_supplier_profile
  FROM profiles p
  WHERE p.id = (v_trip->>'supplier_id')::UUID;

  -- Fetch supplier extension
  SELECT jsonb_build_object(
    'id', s.id,
    'company_name', s.company_name
  )
  INTO v_supplier_extension
  FROM suppliers s
  WHERE s.id = (v_trip->>'supplier_id')::UUID;

  -- Fetch dispute summary if trip is disputed
  SELECT jsonb_build_object(
    'category', td.category,
    'status', td.status,
    'updated_at', td.updated_at
  )
  INTO v_dispute_summary
  FROM trip_disputes td
  WHERE td.trip_id = p_trip_id
  ORDER BY td.updated_at DESC
  LIMIT 1;

  -- Build final result
  v_result := jsonb_build_object(
    'trip', v_trip,
    'supplier_profile', v_supplier_profile,
    'supplier_extension', v_supplier_extension,
    'dispute_summary', v_dispute_summary
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_trip_detail_with_supplier(UUID, UUID) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION get_trip_detail_with_supplier(UUID, UUID) IS 
  'Consolidated RPC that returns trip detail with supplier profile and extension in a single call.
   Replaces 3 separate queries: fetchTripDetail + fetchSupplierProfile + fetchSupplierExtension';
