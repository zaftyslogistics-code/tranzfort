-- Fix get_trucker_dashboard_stats RPC to use owner_id instead of trucker_id for trucks table
-- The trucks table uses owner_id, not trucker_id

create or replace function get_trucker_dashboard_stats(p_trucker_id uuid)
returns jsonb language plpgsql security definer as $$
declare
    v_active_bids bigint;
    v_upcoming_trips bigint;
    v_in_transit_trips bigint;
    v_completed_trips bigint;
    v_total_trucks bigint;
    v_approved_trucks bigint;
    v_pending_trucks bigint;
    v_rejected_trucks bigint;
    v_pending_approval_trucks bigint;
begin
    -- Active bids count
    select count(*) into v_active_bids from booking_requests 
    where trucker_id = p_trucker_id and status = 'submitted';
    
    -- Upcoming trips (assigned, pickup_pending, picked_up)
    select count(*) into v_upcoming_trips from trips 
    where trucker_id = p_trucker_id 
    and stage in ('assigned', 'pickup_pending', 'picked_up');
    
    -- In transit trips
    select count(*) into v_in_transit_trips from trips 
    where trucker_id = p_trucker_id and stage = 'in_transit';
    
    -- Completed trips
    select count(*) into v_completed_trips from trips 
    where trucker_id = p_trucker_id and stage = 'completed';
    
    -- Total trucks
    select count(*) into v_total_trucks from trucks 
    where owner_id = p_trucker_id;
    
    -- Approved trucks
    select count(*) into v_approved_trucks from trucks 
    where owner_id = p_trucker_id and status = 'verified';
    
    -- Pending trucks
    select count(*) into v_pending_trucks from trucks 
    where owner_id = p_trucker_id and status = 'pending';
    
    -- Rejected trucks
    select count(*) into v_rejected_trucks from trucks 
    where owner_id = p_trucker_id and status = 'rejected';
    
    -- Pending re-approval trucks
    select count(*) into v_pending_approval_trucks from trucks 
    where owner_id = p_trucker_id and status = 'edited_pending_reapproval';
    
    return jsonb_build_object(
        'active_bids', v_active_bids,
        'upcoming_trips', v_upcoming_trips,
        'in_transit_trips', v_in_transit_trips,
        'completed_trips', v_completed_trips,
        'total_trucks', v_total_trucks,
        'approved_trucks', v_approved_trucks,
        'pending_trucks', v_pending_trucks,
        'rejected_trucks', v_rejected_trucks,
        'pending_approval_trucks', v_pending_approval_trucks
    );
end;
$$;
