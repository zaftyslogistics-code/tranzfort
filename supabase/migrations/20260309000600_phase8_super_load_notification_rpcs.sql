CREATE OR REPLACE FUNCTION request_super_load(
  p_load_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_load RECORD;
  v_supplier_name TEXT;
BEGIN
  SELECT l.*, p.full_name INTO v_load
  FROM loads l
  JOIN profiles p ON p.id = l.supplier_id
  WHERE l.id = p_load_id
    AND l.supplier_id = auth.uid()
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.parent_load_id IS NOT NULL THEN
    RAISE EXCEPTION 'Only parent loads can request Super Load';
  END IF;

  IF v_load.status != 'active' THEN
    RAISE EXCEPTION 'Only active loads can request Super Load';
  END IF;

  IF v_load.super_status NOT IN ('none', 'rejected') THEN
    RAISE EXCEPTION 'Super Load request is already in progress or active';
  END IF;

  UPDATE loads
  SET is_super_load = TRUE,
      super_status = 'request_submitted',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'super_load_update',
    'medium',
    'New Super Load Request',
    p.full_name || ': ' || v_load.material || ' ' || v_load.origin_city || '→' || v_load.destination_city,
    p_load_id,
    '/admin/super-ops'
  FROM admin_users
  JOIN profiles p ON p.id = v_load.supplier_id
  WHERE admin_users.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_super_load_under_review(
  p_load_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status != 'request_submitted' THEN
    RAISE EXCEPTION 'Only submitted active Super Load requests can move under review';
  END IF;

  UPDATE loads
  SET super_status = 'under_review',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'load',
    p_load_id,
    'Super Load moved under review',
    jsonb_build_object(
      'super_status', 'under_review'
    ),
    'internal'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION approve_super_load_request(
  p_load_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status NOT IN ('request_submitted', 'under_review') THEN
    RAISE EXCEPTION 'Super Load request is not awaiting approval';
  END IF;

  UPDATE loads
  SET is_super_load = TRUE,
      super_status = 'approved_payment_pending',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'super_load_approved',
    'load',
    p_load_id,
    'Super Load approved with payment pending',
    jsonb_build_object(
      'super_status', 'approved_payment_pending'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'super_load_update',
    'high',
    'Super Load Approved',
    'Complete off-platform payment to activate',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION reject_super_load_request(
  p_load_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
  v_reason TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status NOT IN ('request_submitted', 'under_review', 'approved_payment_pending') THEN
    RAISE EXCEPTION 'Super Load request is not awaiting review';
  END IF;

  UPDATE loads
  SET is_super_load = FALSE,
      super_status = 'rejected',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'super_load_rejected',
    'load',
    p_load_id,
    'Super Load rejected',
    jsonb_build_object(
      'reason', v_reason
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'super_load_update',
    'high',
    'Super Load Rejected',
    'Your Super Load request was not approved',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION activate_super_load(
  p_load_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_load RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_load
  FROM loads
  WHERE id = p_load_id
  FOR UPDATE;

  IF v_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_load.status != 'active' OR v_load.super_status != 'approved_payment_pending' THEN
    RAISE EXCEPTION 'Only approved payment-pending Super Loads can be activated';
  END IF;

  UPDATE loads
  SET is_super_load = TRUE,
      super_status = 'active',
      updated_at = NOW()
  WHERE id = p_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'load',
    p_load_id,
    'Super Load activated after payment confirmation',
    jsonb_build_object(
      'super_status', 'active'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'super_load_update',
    'high',
    'Super Load Active!',
    'Your ' || v_load.material || ' load is now a Super Load',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_force_assign_super_load(
  p_parent_load_id UUID,
  p_trucker_id UUID,
  p_truck_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_admin_user_id UUID;
  v_parent RECORD;
  v_truck RECORD;
  v_child_load_id UUID;
  v_trip_id UUID;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_parent
  FROM loads
  WHERE id = p_parent_load_id
  FOR UPDATE;

  IF v_parent IS NULL OR v_parent.parent_load_id IS NOT NULL THEN
    RAISE EXCEPTION 'Invalid Super Load parent';
  END IF;

  IF v_parent.is_super_load IS DISTINCT FROM TRUE OR v_parent.super_status != 'active' THEN
    RAISE EXCEPTION 'Super Load is not active';
  END IF;

  IF v_parent.status != 'active' OR v_parent.trucks_booked >= v_parent.trucks_needed THEN
    RAISE EXCEPTION 'Load is not available for force assignment';
  END IF;

  SELECT * INTO v_truck
  FROM trucks
  WHERE id = p_truck_id
    AND owner_id = p_trucker_id
    AND status = 'verified';

  IF v_truck IS NULL THEN
    RAISE EXCEPTION 'Truck is not verified for the selected trucker';
  END IF;

  INSERT INTO loads (
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
    trucks_needed,
    price_amount,
    price_type,
    advance_percentage,
    pickup_date,
    status,
    is_super_load,
    super_status,
    assigned_trucker_id,
    assigned_truck_id,
    published_at
  ) VALUES (
    v_parent.supplier_id,
    v_parent.id,
    v_parent.origin_label,
    v_parent.origin_city,
    v_parent.origin_state,
    v_parent.origin_lat,
    v_parent.origin_lng,
    v_parent.destination_label,
    v_parent.destination_city,
    v_parent.destination_state,
    v_parent.destination_lat,
    v_parent.destination_lng,
    v_parent.route_distance_km,
    v_parent.route_duration_minutes,
    v_parent.route_polyline,
    v_parent.route_snapshot_source,
    v_parent.material,
    v_parent.weight_tonnes,
    v_parent.required_body_type,
    v_parent.required_tyres,
    1,
    v_parent.price_amount,
    v_parent.price_type,
    v_parent.advance_percentage,
    v_parent.pickup_date,
    'assigned_full',
    TRUE,
    'active',
    p_trucker_id,
    p_truck_id,
    NOW()
  ) RETURNING id INTO v_child_load_id;

  INSERT INTO trips (
    load_id,
    supplier_id,
    trucker_id,
    truck_id,
    stage,
    assigned_at
  ) VALUES (
    v_child_load_id,
    v_parent.supplier_id,
    p_trucker_id,
    p_truck_id,
    'assigned',
    NOW()
  ) RETURNING id INTO v_trip_id;

  UPDATE loads
  SET trucks_booked = trucks_booked + 1,
      status = CASE
        WHEN trucks_booked + 1 >= trucks_needed THEN 'assigned_full'::load_status
        ELSE 'assigned_partial'::load_status
      END,
      updated_at = NOW()
  WHERE id = p_parent_load_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'override_action',
    'load',
    p_parent_load_id,
    'trip',
    v_trip_id,
    'Super Load force-assigned to trucker',
    jsonb_build_object(
      'trucker_id', p_trucker_id,
      'truck_id', p_truck_id,
      'child_load_id', v_child_load_id
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    p_trucker_id,
    'super_load_update',
    'high',
    'Super Load Assignment',
    'You''ve been assigned a Super Load! ' || v_parent.material || ' ' || v_parent.origin_city || '→' || v_parent.destination_city,
    v_child_load_id,
    v_trip_id,
    '/trip-detail/' || v_trip_id::text
  );

  RETURN v_trip_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
