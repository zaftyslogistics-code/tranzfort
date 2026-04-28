-- RPC contract smoke tests + backend version endpoint
-- Run these after 20260428000005_canonical_user_app_rpc_contracts.sql is applied.

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. Version / compatibility check endpoint
-- Flutter calls this on startup to confirm the backend supports the current
-- client contract. Returns a semver-like string and the list of expected RPCs.
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_backend_rpc_contract_version()
RETURNS JSONB LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'version', '2026.04.28-v1',
    'required_rpcs', jsonb_build_array(
      'get_supplier_dashboard_stats',
      'get_trucker_dashboard_stats',
      'get_public_profile',
      'get_profile_reviews',
      'get_trip_detail_with_supplier',
      'upsert_current_user_profile',
      'create_load',
      'advance_trip_stage',
      'upload_trip_proof',
      'submit_review',
      'add_reply_to_review',
      'can_review_user',
      'get_conversation_summary',
      'send_message',
      'request_account_deletion',
      'cancel_account_deletion_request',
      'set_current_user_preferred_language'
    )
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_backend_rpc_contract_version() TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. Smoke test function (idempotent, safe to re-run)
-- Validates that canonical RPCs exist, are callable, and return expected shapes.
-- Does NOT mutate data.
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.run_rpc_contract_smoke_tests()
RETURNS TABLE (test_name TEXT, passed BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_result JSONB;
    v_profile_id UUID;
    v_trip_id UUID;
BEGIN
    -- Pick a real profile to use as a test target (any verified trucker or supplier)
    SELECT id INTO v_profile_id FROM public.profiles WHERE user_role_type IN ('supplier','trucker') LIMIT 1;
    SELECT id INTO v_trip_id FROM public.trips LIMIT 1;

    -- ─── Test: version endpoint exists ───
    test_name := 'version_endpoint_exists';
    BEGIN
        SELECT public.get_backend_rpc_contract_version() INTO v_result;
        passed := (v_result ? 'version');
        message := CASE WHEN passed THEN 'ok' ELSE 'missing version key' END;
        RETURN NEXT;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_supplier_dashboard_stats shape ───
    test_name := 'get_supplier_dashboard_stats_shape';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_supplier_dashboard_stats(v_profile_id) INTO v_result;
            passed := (v_result ? 'active_loads') AND (v_result ? 'pending_bookings')
                      AND (v_result ? 'in_transit_trips') AND (v_result ? 'completed_trips');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_trucker_dashboard_stats shape ───
    test_name := 'get_trucker_dashboard_stats_shape';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_trucker_dashboard_stats(v_profile_id) INTO v_result;
            passed := (v_result ? 'active_bids') AND (v_result ? 'upcoming_trips')
                      AND (v_result ? 'in_transit_trips') AND (v_result ? 'completed_trips')
                      AND (v_result ? 'total_trucks') AND (v_result ? 'approved_trucks');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_public_profile shape ───
    test_name := 'get_public_profile_shape';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_public_profile(v_profile_id, v_profile_id) INTO v_result;
            passed := (v_result ? 'id') AND (v_result ? 'full_name')
                      AND (v_result ? 'role') AND (v_result ? 'trust_scores')
                      AND (v_result ? 'is_self');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_profile_reviews returns array ───
    test_name := 'get_profile_reviews_array';
    BEGIN
        IF v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_profile_reviews(v_profile_id, 5, 0) INTO v_result;
            passed := jsonb_typeof(v_result) = 'array';
            message := CASE WHEN passed THEN 'ok' ELSE 'expected jsonb array, got ' || jsonb_typeof(v_result) END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    -- ─── Test: get_trip_detail_with_supplier shape ───
    test_name := 'get_trip_detail_with_supplier_shape';
    BEGIN
        IF v_trip_id IS NULL OR v_profile_id IS NULL THEN
            passed := TRUE;
            message := 'skipped (no test trip/profile)';
            RETURN NEXT;
        ELSE
            SELECT public.get_trip_detail_with_supplier(v_trip_id, v_profile_id) INTO v_result;
            passed := (v_result ? 'trip') AND (v_result ? 'supplier_profile')
                      AND (v_result ? 'supplier_extension');
            message := CASE WHEN passed THEN 'ok' ELSE 'missing expected keys' END;
            RETURN NEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        passed := FALSE;
        message := SQLERRM;
        RETURN NEXT;
    END;

    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION public.run_rpc_contract_smoke_tests() TO authenticated;
