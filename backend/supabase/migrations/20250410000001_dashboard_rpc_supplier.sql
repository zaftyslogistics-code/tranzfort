-- Migration: Consolidate supplier dashboard stats into single RPC
-- Reduces N+1 queries from 4 separate calls to 1

create or replace function get_supplier_dashboard_stats(p_supplier_id uuid)
returns table (
  active_loads bigint,
  pending_bookings bigint,
  in_transit_trips bigint,
  completed_trips bigint
)
language plpgsql
security definer
as $$
begin
  return query
  select
    -- Active loads count
    (select count(*)::bigint
     from loads
     where supplier_id = p_supplier_id
       and status in ('active', 'assigned_partial', 'assigned_full', 'in_transit')),

    -- Pending bookings count
    (select count(*)::bigint
     from booking_requests br
     join loads l on l.id = br.load_id
     where l.supplier_id = p_supplier_id
       and br.status = 'submitted'),

    -- In-transit trips count
    (select count(*)::bigint
     from trips
     where supplier_id = p_supplier_id
       and stage = 'in_transit'),

    -- Completed trips count
    (select count(*)::bigint
     from trips
     where supplier_id = p_supplier_id
       and stage = 'completed');
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function get_supplier_dashboard_stats(uuid) to authenticated;
