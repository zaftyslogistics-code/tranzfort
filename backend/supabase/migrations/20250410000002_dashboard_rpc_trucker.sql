-- Migration: Consolidate trucker dashboard stats into single RPC
-- Reduces N+1 queries from 9 separate calls to 1

create or replace function get_trucker_dashboard_stats(p_trucker_id uuid)
returns table (
  active_bids bigint,
  upcoming_trips bigint,
  in_transit_trips bigint,
  completed_trips bigint,
  total_trucks bigint,
  approved_trucks bigint,
  pending_trucks bigint,
  rejected_trucks bigint,
  pending_approval_trucks bigint
)
language plpgsql
security definer
as $$
begin
  return query
  select
    -- Active bids count (submitted booking requests)
    (select count(*)::bigint
     from booking_requests
     where trucker_id = p_trucker_id
       and status = 'submitted'),

    -- Upcoming trips count
    (select count(*)::bigint
     from trips
     where trucker_id = p_trucker_id
       and stage in ('assigned', 'pickup_pending', 'picked_up')),

    -- In-transit trips count
    (select count(*)::bigint
     from trips
     where trucker_id = p_trucker_id
       and stage = 'in_transit'),

    -- Completed trips count
    (select count(*)::bigint
     from trips
     where trucker_id = p_trucker_id
       and stage = 'completed'),

    -- Total trucks count
    (select count(*)::bigint
     from trucks
     where owner_id = p_trucker_id),

    -- Approved trucks count
    (select count(*)::bigint
     from trucks
     where owner_id = p_trucker_id
       and status = 'verified'),

    -- Pending trucks count
    (select count(*)::bigint
     from trucks
     where owner_id = p_trucker_id
       and status = 'pending'),

    -- Rejected trucks count
    (select count(*)::bigint
     from trucks
     where owner_id = p_trucker_id
       and status = 'rejected'),

    -- Pending re-approval trucks count
    (select count(*)::bigint
     from trucks
     where owner_id = p_trucker_id
       and status = 'edited_pending_reapproval');
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function get_trucker_dashboard_stats(uuid) to authenticated;
