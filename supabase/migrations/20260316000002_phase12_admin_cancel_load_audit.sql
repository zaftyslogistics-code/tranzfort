ALTER TYPE audit_action_type ADD VALUE IF NOT EXISTS 'admin_cancel_load';

CREATE OR REPLACE FUNCTION cancel_load(p_load_id UUID)
RETURNS VOID AS $$
DECLARE
  v_load RECORD;
  v_admin_user_id UUID;
  v_actor_type TEXT;
  v_actor_role TEXT;
  v_action_type audit_action_type;
BEGIN
  SELECT * INTO v_load FROM loads WHERE id = p_load_id FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.supplier_id != auth.uid() AND NOT is_admin() THEN RAISE EXCEPTION 'Not authorized'; END IF;
  IF v_load.status NOT IN ('active', 'draft') THEN RAISE EXCEPTION 'Load cannot be cancelled in current state'; END IF;

  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NOT NULL THEN
    v_actor_type := 'admin';
    v_actor_role := get_admin_role()::text;
    v_action_type := 'admin_cancel_load';
  ELSE
    v_actor_type := 'user';
    v_actor_role := NULL;
    v_action_type := 'override_action';
  END IF;

  UPDATE loads SET status = 'cancelled' WHERE id = p_load_id;

  IF v_load.status = 'active' THEN
    UPDATE suppliers SET active_loads_count = GREATEST(active_loads_count - 1, 0)
    WHERE id = v_load.supplier_id;
  END IF;

  UPDATE booking_requests SET status = 'superseded'
  WHERE load_id = p_load_id AND status = 'submitted';

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
    v_actor_type,
    v_actor_role,
    v_action_type,
    'load',
    p_load_id,
    NULL,
    NULL,
    CASE
      WHEN v_admin_user_id IS NOT NULL THEN 'Load cancelled by admin'
      ELSE 'Load cancelled by supplier'
    END,
    jsonb_build_object(
      'previous_status', v_load.status,
      'next_status', 'cancelled',
      'supplier_id', v_load.supplier_id
    ),
    'internal'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
