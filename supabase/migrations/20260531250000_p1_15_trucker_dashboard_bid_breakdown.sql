-- P1-15: Trucker dashboard bid breakdown (submitted / approved / rejected).

CREATE OR REPLACE FUNCTION public.get_trucker_dashboard_stats(p_trucker_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_active_bids BIGINT;
    v_bids_approved BIGINT;
    v_bids_rejected BIGINT;
    v_upcoming_trips BIGINT;
    v_in_transit_trips BIGINT;
    v_completed_trips BIGINT;
    v_total_trucks BIGINT;
    v_approved_trucks BIGINT;
    v_pending_trucks BIGINT;
    v_rejected_trucks BIGINT;
    v_pending_approval_trucks BIGINT;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_trucker_id IS DISTINCT FROM v_caller AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT COUNT(*) INTO v_active_bids FROM public.booking_requests
    WHERE trucker_id = v_caller AND status = 'submitted';

    SELECT COUNT(*) INTO v_bids_approved FROM public.booking_requests
    WHERE trucker_id = v_caller AND status = 'approved';

    SELECT COUNT(*) INTO v_bids_rejected FROM public.booking_requests
    WHERE trucker_id = v_caller AND status = 'rejected';

    SELECT COUNT(*) INTO v_upcoming_trips FROM public.trips
    WHERE trucker_id = v_caller AND stage IN ('assigned', 'pickup_pending', 'picked_up');

    SELECT COUNT(*) INTO v_in_transit_trips FROM public.trips
    WHERE trucker_id = v_caller AND stage = 'in_transit';

    SELECT COUNT(*) INTO v_completed_trips FROM public.trips
    WHERE trucker_id = v_caller AND stage = 'completed';

    SELECT COUNT(*) INTO v_total_trucks FROM public.trucks
    WHERE owner_id = v_caller;

    SELECT COUNT(*) INTO v_approved_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'verified';

    SELECT COUNT(*) INTO v_pending_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'pending';

    SELECT COUNT(*) INTO v_rejected_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'rejected';

    SELECT COUNT(*) INTO v_pending_approval_trucks FROM public.trucks
    WHERE owner_id = v_caller AND status = 'edited_pending_reapproval';

    RETURN jsonb_build_object(
        'active_bids', v_active_bids,
        'bids_submitted', v_active_bids,
        'bids_approved', v_bids_approved,
        'bids_rejected', v_bids_rejected,
        'upcoming_trips', v_upcoming_trips,
        'in_transit_trips', v_in_transit_trips,
        'completed_trips', v_completed_trips,
        'total_trucks', v_total_trucks,
        'approved_trucks', v_approved_trucks,
        'pending_trucks', v_pending_trucks,
        'rejected_trucks', v_rejected_trucks,
        'pending_approval_trucks', v_pending_approval_trucks
    );
END;
$$;
