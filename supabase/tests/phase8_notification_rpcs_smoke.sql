DO $$
DECLARE
  v_approve_verification_case_def TEXT;
  v_reject_verification_case_def TEXT;
  v_update_truck_verification_state_def TEXT;
BEGIN
  IF to_regprocedure('send_message(uuid,message_type,uuid,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'Missing send_message RPC';
  END IF;

  IF to_regprocedure('raise_trip_dispute(uuid,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing raise_trip_dispute RPC';
  END IF;

  IF to_regprocedure('cancel_trip(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing cancel_trip RPC';
  END IF;

  IF to_regprocedure('reply_to_support_ticket(uuid,text,text,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing reply_to_support_ticket RPC';
  END IF;

  IF to_regprocedure('claim_operational_case(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing claim_operational_case RPC';
  END IF;

  IF to_regprocedure('release_operational_case(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing release_operational_case RPC';
  END IF;

  IF to_regprocedure('transition_operational_case(uuid,operational_case_status,text,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing transition_operational_case RPC';
  END IF;

  IF to_regprocedure('resolve_operational_case(uuid,text,operational_case_status)') IS NULL THEN
    RAISE EXCEPTION 'Missing resolve_operational_case RPC';
  END IF;

  IF to_regprocedure('escalate_operational_case(uuid,uuid,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing escalate_operational_case RPC';
  END IF;

  IF to_regprocedure('submit_verification_for_review()') IS NULL THEN
    RAISE EXCEPTION 'Missing submit_verification_for_review RPC';
  END IF;

  IF to_regprocedure('resubmit_verification_case()') IS NULL THEN
    RAISE EXCEPTION 'Missing resubmit_verification_case RPC';
  END IF;

  IF to_regprocedure('approve_verification_case(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing approve_verification_case RPC';
  END IF;

  IF to_regprocedure('reject_verification_case(uuid,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'Missing reject_verification_case structured feedback RPC';
  END IF;

  IF to_regprocedure('update_truck_verification_state(uuid,truck_status,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing update_truck_verification_state RPC';
  END IF;

  IF to_regprocedure('update_truck_verification_state(uuid,truck_status,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'Missing update_truck_verification_state structured feedback RPC';
  END IF;

  IF to_regprocedure('request_account_deletion()') IS NULL THEN
    RAISE EXCEPTION 'Missing request_account_deletion RPC';
  END IF;

  IF to_regprocedure('update_trust_safety_status(uuid,trust_safety_status,text,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing update_trust_safety_status RPC';
  END IF;

  IF to_regprocedure('request_super_load(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing request_super_load RPC';
  END IF;

  IF to_regprocedure('mark_super_load_under_review(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing mark_super_load_under_review RPC';
  END IF;

  IF to_regprocedure('approve_super_load_request(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing approve_super_load_request RPC';
  END IF;

  IF to_regprocedure('reject_super_load_request(uuid,text)') IS NULL THEN
    RAISE EXCEPTION 'Missing reject_super_load_request RPC';
  END IF;

  IF to_regprocedure('activate_super_load(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing activate_super_load RPC';
  END IF;

  IF to_regprocedure('admin_force_assign_super_load(uuid,uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'Missing admin_force_assign_super_load RPC';
  END IF;

  IF to_regprocedure('notify_verification_sla_approaching()') IS NULL THEN
    RAISE EXCEPTION 'Missing notify_verification_sla_approaching RPC';
  END IF;

  v_approve_verification_case_def := lower(pg_get_functiondef('approve_verification_case(uuid)'::regprocedure));
  IF position('update verification_cases' IN v_approve_verification_case_def) = 0 OR
     position('update profiles' IN v_approve_verification_case_def) = 0 OR
     position('insert into notifications' IN v_approve_verification_case_def) = 0 THEN
    RAISE EXCEPTION 'approve_verification_case RPC no longer guarantees verification case/profile/notification sync';
  END IF;

  v_reject_verification_case_def := lower(pg_get_functiondef('reject_verification_case(uuid,text,jsonb)'::regprocedure));
  IF position('update verification_cases' IN v_reject_verification_case_def) = 0 OR
     position('update profiles' IN v_reject_verification_case_def) = 0 OR
     position('insert into notifications' IN v_reject_verification_case_def) = 0 THEN
    RAISE EXCEPTION 'reject_verification_case RPC no longer guarantees verification case/profile/notification sync';
  END IF;

  v_update_truck_verification_state_def := lower(pg_get_functiondef('update_truck_verification_state(uuid,truck_status,text,jsonb)'::regprocedure));
  IF position('update verification_cases' IN v_update_truck_verification_state_def) = 0 OR
     position('update trucks' IN v_update_truck_verification_state_def) = 0 OR
     position('insert into notifications' IN v_update_truck_verification_state_def) = 0 THEN
    RAISE EXCEPTION 'update_truck_verification_state RPC no longer guarantees verification case/truck/notification sync';
  END IF;
END;
$$;
