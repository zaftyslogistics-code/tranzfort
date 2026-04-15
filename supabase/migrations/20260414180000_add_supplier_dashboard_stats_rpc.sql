-- Add missing get_supplier_dashboard_stats RPC
-- This RPC was referenced in Dart code but never created in migrations

create or replace function get_supplier_dashboard_stats(p_supplier_id uuid)
returns jsonb language plpgsql security definer as $$
declare
    v_active_loads bigint;
    v_pending_bookings bigint;
    v_in_transit_trips bigint;
    v_completed_trips bigint;
begin
    -- Active loads count (loads that are active, assigned_partial, assigned_full, in_transit)
    select count(*) into v_active_loads from loads
    where supplier_id = p_supplier_id
    and status in ('active', 'assigned_partial', 'assigned_full', 'in_transit');

    -- Pending bookings (booking_requests with status 'submitted' or 'pending')
    -- booking_requests doesn't have supplier_id, need to join with loads
    select count(*) into v_pending_bookings from booking_requests br
    join loads l on l.id = br.load_id
    where l.supplier_id = p_supplier_id
    and br.status in ('submitted', 'pending');

    -- In transit trips (trips with stage 'in_transit')
    select count(*) into v_in_transit_trips from trips
    where supplier_id = p_supplier_id
    and stage = 'in_transit';

    -- Completed trips (trips with stage 'completed')
    select count(*) into v_completed_trips from trips
    where supplier_id = p_supplier_id
    and stage = 'completed';

    return jsonb_build_object(
        'active_loads', v_active_loads,
        'pending_bookings', v_pending_bookings,
        'in_transit_trips', v_in_transit_trips,
        'completed_trips', v_completed_trips
    );
end;
$$;

-- Grant execute permissions
grant execute on function get_supplier_dashboard_stats(uuid) to authenticated;
